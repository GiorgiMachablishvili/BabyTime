import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Lock-screen / Notification-Centre view

struct SleepTimerLockScreenView: View {
    let context: ActivityViewContext<SleepTimerAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Moon badge
            ZStack {
                Circle()
                    .fill(Color(red: 0.545, green: 0.427, blue: 0.769))  // #8b6dc4
                    .frame(width: 52, height: 52)
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 24, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.babyName) is sleeping")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.133, green: 0.133, blue: 0.133))

                // SwiftUI counts up automatically from startTime — no polling needed
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))  // #8b6dc4

                Text("Started \(context.state.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.941, green: 0.933, blue: 0.973))  // #f0eef8
    }
}

// MARK: - Widget declaration

struct SleepTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerAttributes.self) { context in
            SleepTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded island
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.babyName)
                            .font(.callout.weight(.semibold))
                    } icon: {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.callout.bold().monospacedDigit())
                        .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Tap the app to stop the sleep session")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))
                    .frame(minWidth: 40)
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color(red: 0.545, green: 0.427, blue: 0.769))
            }
            .widgetURL(URL(string: "mybaby://sleep"))
            .keylineTint(Color(red: 0.545, green: 0.427, blue: 0.769))
        }
    }
}

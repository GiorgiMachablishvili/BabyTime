import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Lock-screen / Notification-Centre view

struct BreastTimerLockScreenView: View {
    let context: ActivityViewContext<BreastTimerAttributes>

    private var sideLabel: String {
        context.state.side == "L" ? "Left side" : "Right side"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Badge
            ZStack {
                Circle()
                    .fill(Color(red: 0.988, green: 0.733, blue: 0.506))  // warm peach #fCBB81
                    .frame(width: 52, height: 52)
                Text("🤱")
                    .font(.system(size: 26))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.state.babyName) is breastfeeding")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.133, green: 0.133, blue: 0.133))

                // Auto-counts every second — no polling, no refresh needed
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.988, green: 0.573, blue: 0.200))  // #FD9233

                Text("\(sideLabel) · started \(context.state.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.996, green: 0.953, blue: 0.925))  // #FEF3EC
    }
}

// MARK: - Widget declaration

struct BreastTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreastTimerAttributes.self) { context in
            BreastTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded island
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.babyName)
                            .font(.callout.weight(.semibold))
                    } icon: {
                        Text("🤱")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.callout.bold().monospacedDigit())
                        .foregroundStyle(Color(red: 0.988, green: 0.573, blue: 0.200))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.side == "L" ? "Left" : "Right") side · tap app to stop")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Text("🤱")
                    .font(.caption)
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(Color(red: 0.988, green: 0.573, blue: 0.200))
                    .frame(minWidth: 40)
            } minimal: {
                Text("🤱")
                    .font(.caption)
            }
            .widgetURL(URL(string: "mybaby://feeding"))
            .keylineTint(Color(red: 0.988, green: 0.573, blue: 0.200))
        }
    }
}

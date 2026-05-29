import Foundation
import UserNotifications

// MARK: - NSNotification names shared across the app

extension Notification.Name {
    static let sleepTimerShouldPause  = Notification.Name("sleepTimerShouldPause")
    static let sleepTimerShouldResume = Notification.Name("sleepTimerShouldResume")
    static let sleepTimerShouldStop   = Notification.Name("sleepTimerShouldStop")
    static let breastTimerShouldStop  = Notification.Name("breastTimerShouldStop")
}

// MARK: - BreastTimerNotificationHandler

/// Fallback called by AppDelegate when "Stop & Save" fires and the app was killed.
/// FeedingBreastTimerCell.stopAndSave() is the primary path (when app is alive);
/// this handler reads UserDefaults and saves the session independently.
enum BreastTimerNotificationHandler {

    private static let startKey = "activeBreastTimerStartTimestamp"
    private static let sideKey  = "activeBreastTimerSide"

    static func stopAndSaveIfNeeded() {
        let ud  = UserDefaults.standard
        let ts  = ud.double(forKey: startKey)
        guard ts > 0 else { return }   // no active session

        let start   = Date(timeIntervalSince1970: ts)
        let side    = ud.string(forKey: sideKey) ?? "L"
        let elapsed = max(0, Date().timeIntervalSince(start))

        let totalMin = Int(elapsed / 60)
        let totalSec = Int(elapsed.truncatingRemainder(dividingBy: 60))
        let value    = totalMin > 0 ? "\(totalMin) min \(totalSec) sec" : "\(totalSec) sec"

        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        let df = DateFormatter(); df.dateFormat = "MMM d"

        FeedingLogStore.add(FeedingViewCell.ViewModel(
            type: .breast,
            volumeText: value,
            notesText: "Side: \(side)",
            timeText: tf.string(from: start),
            dateText: df.string(from: start)
        ))

        ud.removeObject(forKey: startKey)
        ud.removeObject(forKey: sideKey)

        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: ["breastFeedingTimerNotification"])
    }
}

// MARK: - SleepTimerNotificationHandler

/// Stateless helper called by AppDelegate when a sleep notification action fires.
/// Handles the "Stop" case directly so the session is saved even if
/// SleepViewController is not alive (app was in the background / killed).
enum SleepTimerNotificationHandler {

    private static let startKey          = "activeSleepStartTimestamp"
    private static let pausedSecondsKey  = "sleepTotalPausedSeconds"
    private static let pausedAtKey       = "sleepPausedAtTimestamp"

    static func stopAndSaveIfNeeded() {
        let ud  = UserDefaults.standard
        let ts  = ud.double(forKey: startKey)
        guard ts > 0 else { return }                  // no active session

        let start           = Date(timeIntervalSince1970: ts)
        var pausedSecs      = ud.double(forKey: pausedSecondsKey)
        let pausedAt        = ud.double(forKey: pausedAtKey)
        if pausedAt > 0 {
            pausedSecs += Date().timeIntervalSince(Date(timeIntervalSince1970: pausedAt))
        }

        let effectiveDuration = max(0, Date().timeIntervalSince(start) - pausedSecs)
        let end               = start.addingTimeInterval(effectiveDuration)

        // Save session
        var sessions = SleepSessionStore.load()
        sessions.insert(SleepSession(start: start, end: end), at: 0)
        SleepSessionStore.save(sessions)

        // Clear persisted state
        ud.removeObject(forKey: startKey)
        ud.removeObject(forKey: pausedSecondsKey)
        ud.removeObject(forKey: pausedAtKey)

        // Clear notification
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: ["sleepInProgressNotification"])
    }
}

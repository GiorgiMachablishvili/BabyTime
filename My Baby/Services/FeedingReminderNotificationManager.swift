import UserNotifications

enum FeedingReminderNotificationManager {
    private static let center = UNUserNotificationCenter.current()

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Schedules a one-time notification for the reminder's date at its time.
    static func schedule(_ reminder: FeedingReminder) {
        unschedule(reminderId: reminder.id)
        guard reminder.isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Feeding Reminder"
        content.body = reminder.note.isEmpty ? "Time to feed your baby" : reminder.note
        content.sound = .default
        content.userInfo = ["reminderId": reminder.id.uuidString]

        let cal = Calendar.current
        let day = Date(timeIntervalSince1970: reminder.dayTimestamp)
        var comps = cal.dateComponents([.year, .month, .day], from: day)
        comps.hour = reminder.hour
        comps.minute = reminder.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: reminder.id), content: content, trigger: trigger)
        center.add(request)
    }

    static func unschedule(reminderId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: reminderId)])
    }

    static func scheduleAll(_ reminders: [FeedingReminder]) {
        center.removeAllPendingNotificationRequests()
        reminders.filter(\.isEnabled).forEach { schedule($0) }
    }

    private static func identifier(for id: UUID) -> String {
        "feeding_reminder_\(id.uuidString)"
    }
}

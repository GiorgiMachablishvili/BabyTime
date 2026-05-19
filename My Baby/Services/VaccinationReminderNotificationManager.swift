import UserNotifications

enum VaccinationReminderNotificationManager {
    private static let center = UNUserNotificationCenter.current()

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func schedule(_ reminder: VaccinationReminder) {
        unschedule(reminderId: reminder.id)
        guard reminder.isEnabled else { return }

        let cal = Calendar.current
        let visitDay = Date(timeIntervalSince1970: reminder.dayTimestamp)

        let days = reminder.notifyDaysBefore.isEmpty ? [0] : reminder.notifyDaysBefore

        for daysBefore in days {
            guard let notifyDate = cal.date(byAdding: .day, value: -daysBefore, to: visitDay) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Vaccination Reminder"
            content.body = reminder.note.isEmpty ? "Vaccination appointment\(daysBefore == 0 ? " today" : " in \(daysBefore) day\(daysBefore == 1 ? "" : "s")")" : reminder.note
            content.sound = .default
            content.userInfo = ["reminderId": reminder.id.uuidString, "daysBefore": daysBefore]

            var comps = cal.dateComponents([.year, .month, .day], from: notifyDate)
            comps.hour = reminder.hour
            comps.minute = reminder.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: reminder.id, daysBefore: daysBefore),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func unschedule(reminderId: UUID) {
        let ids = VaccinationReminder.notifyDaysOptions.map { identifier(for: reminderId, daysBefore: $0) }
            + [identifier(for: reminderId, daysBefore: 0)]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func identifier(for id: UUID, daysBefore: Int) -> String {
        "vaccination_reminder_\(id.uuidString)_\(daysBefore)"
    }
}

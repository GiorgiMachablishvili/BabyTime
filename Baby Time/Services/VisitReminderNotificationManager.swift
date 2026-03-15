import UserNotifications

enum VisitReminderNotificationManager {
    private static let center = UNUserNotificationCenter.current()
    private static let notificationHour = 9
    private static let notificationMinute = 0

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Schedules one notification for each selected "days before" at 9:00 AM on that day.
    static func schedule(_ visit: VisitReminder) {
        unschedule(visitId: visit.id, kind: visit.kind)
        let cal = Calendar.current
        let visitDay = Date(timeIntervalSince1970: visit.visitDayTimestamp)
        let title: String
        switch visit.kind {
        case .vaccination: title = "Vaccination Reminder"
        case .doctorVisit: title = "Doctor Visit Reminder"
        }
        let body = visit.note.isEmpty ? "Reminder for your scheduled visit" : visit.note

        for daysBefore in visit.notifyDaysBefore {
            guard let notifyDate = cal.date(byAdding: .day, value: -daysBefore, to: visitDay) else { continue }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = [
                "visitId": visit.id.uuidString,
                "kind": visit.kind.rawValue,
                "daysBefore": daysBefore
            ]

            var comps = cal.dateComponents([.year, .month, .day], from: notifyDate)
            comps.hour = notificationHour
            comps.minute = notificationMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(visitId: visit.id, kind: visit.kind, daysBefore: daysBefore),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func unschedule(visitId: UUID, kind: VisitReminder.Kind) {
        for days in VisitReminder.notifyDaysBeforeOptions {
            center.removePendingNotificationRequests(
                withIdentifiers: [identifier(visitId: visitId, kind: kind, daysBefore: days)]
            )
        }
    }

    private static func identifier(visitId: UUID, kind: VisitReminder.Kind, daysBefore: Int) -> String {
        "visit_reminder_\(kind.rawValue)_\(visitId.uuidString)_\(daysBefore)"
    }
}

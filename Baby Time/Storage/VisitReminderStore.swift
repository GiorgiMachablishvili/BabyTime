import Foundation

enum VisitReminderStore {
    private static func key(for kind: VisitReminder.Kind) -> String {
        "visit_reminders_\(kind.rawValue)"
    }

    static func load(kind: VisitReminder.Kind) -> [VisitReminder] {
        let k = key(for: kind)
        guard let data = UserDefaults.standard.data(forKey: k),
              let decoded = try? JSONDecoder().decode([VisitReminder].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.visitDayTimestamp < $1.visitDayTimestamp }
    }

    static func save(_ visits: [VisitReminder], kind: VisitReminder.Kind) {
        let k = key(for: kind)
        guard let data = try? JSONEncoder().encode(visits) else { return }
        UserDefaults.standard.set(data, forKey: k)
    }

    static func visits(for date: Date, kind: VisitReminder.Kind) -> [VisitReminder] {
        let day = Calendar.current.startOfDay(for: date)
        return load(kind: kind).filter {
            Calendar.current.isDate(Date(timeIntervalSince1970: $0.visitDayTimestamp), inSameDayAs: day)
        }
    }
}

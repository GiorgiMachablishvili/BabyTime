import Foundation

enum FeedingReminderStore {
    private static let key = "feeding_reminders"

    static func load() -> [FeedingReminder] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FeedingReminder].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ reminders: [FeedingReminder]) {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func reminders(for date: Date) -> [FeedingReminder] {
        let day = Calendar.current.startOfDay(for: date)
        return load().filter {
            Calendar.current.isDate(Date(timeIntervalSince1970: $0.dayTimestamp), inSameDayAs: day)
        }.sorted { r1, r2 in
            if r1.hour != r2.hour { return r1.hour < r2.hour }
            return r1.minute < r2.minute
        }
    }
}

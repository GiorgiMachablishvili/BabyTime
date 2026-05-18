import Foundation

enum VaccinationReminderStore {
    private static let key = "vaccination_reminders"

    static func load() -> [VaccinationReminder] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([VaccinationReminder].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ reminders: [VaccinationReminder]) {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func reminders(for date: Date) -> [VaccinationReminder] {
        let day = Calendar.current.startOfDay(for: date)
        return load().filter {
            Calendar.current.isDate(Date(timeIntervalSince1970: $0.dayTimestamp), inSameDayAs: day)
        }.sorted {
            if $0.hour != $1.hour { return $0.hour < $1.hour }
            return $0.minute < $1.minute
        }
    }
}

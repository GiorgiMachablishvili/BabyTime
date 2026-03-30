import Foundation

struct DiaperLogEntry: Codable, Equatable {
    let id: UUID
    let typeRaw: String
    let note: String?
    let date: Date
}

enum DiaperLogStore {
    private static let key = "diaper_log_entries"

    static func load() -> [DiaperLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DiaperLogEntry].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date > $1.date }
    }

    static func save(_ entries: [DiaperLogEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}


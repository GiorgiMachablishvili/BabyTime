import Foundation

struct DiaperLogEntry: Codable, Equatable {
    let id: UUID
    let typeRaw: String
    let note: String?
    let date: Date
}

enum DiaperLogStore {
    private static let key = "diaper_log_entries"
    private static var _cache: [DiaperLogEntry]?  // in-memory cache; nil = not yet loaded

    static func load() -> [DiaperLogEntry] {
        if let cached = _cache { return cached }  // ← free after first load
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DiaperLogEntry].self, from: data) else {
            _cache = []
            return []
        }
        let sorted = decoded.sorted { $0.date > $1.date }
        _cache = sorted
        return sorted
    }

    static func save(_ entries: [DiaperLogEntry]) {
        _cache = entries                          // keep cache in sync; no re-decode needed
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}


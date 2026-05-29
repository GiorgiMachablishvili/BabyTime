import Foundation

enum SleepSessionStore {
    private static let key = "sleep_sessions"
    private static var _cache: [SleepSession]?   // in-memory cache; nil = not yet loaded

    static func load() -> [SleepSession] {
        if let cached = _cache { return cached }  // ← free after first load
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SleepSession].self, from: data) else {
            _cache = []
            return []
        }
        let sorted = decoded.sorted { $0.end > $1.end }
        _cache = sorted
        return sorted
    }

    static func save(_ sessions: [SleepSession]) {
        _cache = sessions                         // keep cache in sync; no re-decode needed
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}


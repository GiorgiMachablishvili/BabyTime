import Foundation

enum SleepSessionStore {
    private static let key = "sleep_sessions"

    static func load() -> [SleepSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SleepSession].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.end > $1.end }
    }

    static func save(_ sessions: [SleepSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}


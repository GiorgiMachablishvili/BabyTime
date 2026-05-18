import Foundation

enum GrowthMeasurementStore {
    private static let key = "growth_measurements_v2"

    static func load() -> [GrowthMeasurement] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([GrowthMeasurement].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date > $1.date }
    }

    static func save(_ measurements: [GrowthMeasurement]) {
        guard let data = try? JSONEncoder().encode(measurements) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

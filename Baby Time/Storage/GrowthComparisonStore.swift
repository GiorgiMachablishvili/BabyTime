import Foundation

enum GrowthComparisonStore {
    private static let key = "growth_comparison_data"

    static func load() -> GrowthComparisonData? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(GrowthComparisonData.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func save(_ value: GrowthComparisonData) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Backward compatibility: migrate from old keys into GrowthComparisonData and save.
    static func loadOrMigrate() -> GrowthComparisonData {
        if let existing = load() { return existing }
        let p1H = loadParent1HeightLegacy()
        let p2H = loadParent2HeightLegacy()
        let bH = loadBabyHeightLegacy()
        let p1L = loadParent1LabelLegacy()
        let p2L = loadParent2LabelLegacy()
        let p1S = loadParent1SkinToneIndexLegacy()
        let p2S = loadParent2SkinToneIndexLegacy()
        let p1Type: GrowthComparisonData.ParentType = (p1L?.lowercased() == "father") ? .father : .mother
        let p2Type: GrowthComparisonData.ParentType = (p2L?.lowercased() == "father") ? .father : .mother
        let migrated = GrowthComparisonData(
            parent1Type: p1Type,
            parent2Type: p2Type,
            parent1HeightCm: p1H,
            parent2HeightCm: p2H,
            babyHeightCm: bH,
            parent1SkinToneIndex: p1S,
            parent2SkinToneIndex: p2S,
            babySkinToneIndex: 0
        )
        save(migrated)
        return migrated
    }

    private static let defaults = UserDefaults.standard
    private static func loadParent1HeightLegacy() -> Double? {
        let v = defaults.object(forKey: "growth_comparison.parent1_height")
        if let d = v as? Double { return d }; if let n = v as? NSNumber { return n.doubleValue }; return nil
    }
    private static func loadParent2HeightLegacy() -> Double? {
        let v = defaults.object(forKey: "growth_comparison.parent2_height")
        if let d = v as? Double { return d }; if let n = v as? NSNumber { return n.doubleValue }; return nil
    }
    private static func loadBabyHeightLegacy() -> Double? {
        let v = defaults.object(forKey: "growth_comparison.baby_height")
        if let d = v as? Double { return d }; if let n = v as? NSNumber { return n.doubleValue }; return nil
    }
    private static func loadParent1LabelLegacy() -> String? { defaults.string(forKey: "growth_comparison.parent1_label") }
    private static func loadParent2LabelLegacy() -> String? { defaults.string(forKey: "growth_comparison.parent2_label") }
    private static func loadParent1SkinToneIndexLegacy() -> Int {
        (defaults.object(forKey: "growth_comparison.parent1_skin_index") as? Int) ?? 0
    }
    private static func loadParent2SkinToneIndexLegacy() -> Int {
        (defaults.object(forKey: "growth_comparison.parent2_skin_index") as? Int) ?? 0
    }

    // MARK: - Height history (baby height + date per save)

    private static let historyKey = "growth_height_history"

    private static let historyDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
    private static let historyEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    static func loadHistory() -> [GrowthHeightHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? historyDecoder.decode([GrowthHeightHistoryEntry].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.savedAt > $1.savedAt }
    }

    static func appendHistoryEntry(babyHeightCm: Double) {
        let entry = GrowthHeightHistoryEntry(babyHeightCm: babyHeightCm, savedAt: Date())
        var list = loadHistory()
        list.insert(entry, at: 0)
        saveHistory(list)
    }

    static func removeHistoryEntries(atOffsets offsets: IndexSet) {
        var list = loadHistory()
        for index in offsets.sorted(by: >) {
            list.remove(at: index)
        }
        saveHistory(list)
    }

    private static func saveHistory(_ entries: [GrowthHeightHistoryEntry]) {
        guard let data = try? historyEncoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
}

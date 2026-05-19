import Foundation
import Combine

/// View model for Growth height comparison. Loads/saves via GrowthComparisonStore.
final class GrowthComparisonViewModel: ObservableObject {
    @Published private(set) var data: GrowthComparisonData
    @Published private(set) var history: [GrowthHeightHistoryEntry]

    init(initialData: GrowthComparisonData? = nil) {
        self.data = initialData ?? GrowthComparisonStore.loadOrMigrate()
        self.history = GrowthComparisonStore.loadHistory()
    }

    func load() {
        data = GrowthComparisonStore.loadOrMigrate()
        history = GrowthComparisonStore.loadHistory()
    }

    func save(_ newData: GrowthComparisonData) {
        data = newData
        GrowthComparisonStore.save(newData)
    }

    func updateFromForm(
        parent1Type: GrowthComparisonData.ParentType,
        parent2Type: GrowthComparisonData.ParentType,
        parent1HeightCm: Double?,
        parent2HeightCm: Double?,
        babyHeightCm: Double?,
        parent1SkinToneIndex: Int,
        parent2SkinToneIndex: Int,
        babySkinToneIndex: Int
    ) {
        var updated = data
        updated.parent1Type = parent1Type
        updated.parent2Type = parent2Type
        updated.parent1HeightCm = parent1HeightCm
        updated.parent2HeightCm = parent2HeightCm
        updated.babyHeightCm = babyHeightCm
        updated.parent1SkinToneIndex = min(max(0, parent1SkinToneIndex), 5)
        updated.parent2SkinToneIndex = min(max(0, parent2SkinToneIndex), 5)
        updated.babySkinToneIndex = min(max(0, babySkinToneIndex), 5)
        save(updated)
    }

    /// Call this when the user saves the form to add the current baby height to history. Uses the value you pass (e.g. from the text field at save time).
    func addHistoryEntry(babyHeightCm: Double) {
        GrowthComparisonStore.appendHistoryEntry(babyHeightCm: babyHeightCm)
        history = GrowthComparisonStore.loadHistory()
    }

    func deleteHistoryEntries(atOffsets offsets: IndexSet) {
        GrowthComparisonStore.removeHistoryEntries(atOffsets: offsets)
        history = GrowthComparisonStore.loadHistory()
    }
}

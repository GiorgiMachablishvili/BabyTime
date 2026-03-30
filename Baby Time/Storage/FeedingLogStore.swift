import Foundation

/// Persisted feeding log entry (Codable). Convert to/from FeedingViewCell.ViewModel for display.
struct FeedingLogEntry: Codable {
    let id: UUID
    let typeRaw: String  // "breast", "bottle", "formula", "solid"
    let volumeText: String?
    let notesText: String?
    let timeText: String
    let dateText: String
    let savedAtEpochSeconds: Double?

    enum CodingKeys: String, CodingKey {
        case id, typeRaw, volumeText, notesText, timeText, dateText, savedAtEpochSeconds
    }

    init(
        id: UUID = UUID(),
        typeRaw: String,
        volumeText: String?,
        notesText: String?,
        timeText: String,
        dateText: String,
        savedAtEpochSeconds: Double?
    ) {
        self.id = id
        self.typeRaw = typeRaw
        self.volumeText = volumeText
        self.notesText = notesText
        self.timeText = timeText
        self.dateText = dateText
        self.savedAtEpochSeconds = savedAtEpochSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        typeRaw = try c.decode(String.self, forKey: .typeRaw)
        volumeText = try c.decodeIfPresent(String.self, forKey: .volumeText)
        notesText = try c.decodeIfPresent(String.self, forKey: .notesText)
        timeText = try c.decode(String.self, forKey: .timeText)
        dateText = try c.decode(String.self, forKey: .dateText)
        savedAtEpochSeconds = try c.decodeIfPresent(Double.self, forKey: .savedAtEpochSeconds)
    }
}

enum FeedingLogStore {
    private static let key = "feeding_log_items"

    static func load() -> [FeedingViewCell.ViewModel] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([FeedingLogEntry].self, from: data) else {
            return []
        }
        return entries.compactMap { entry -> FeedingViewCell.ViewModel? in
            let type: FeedingViewCell.ViewModel.FeedingType
            switch entry.typeRaw {
            case "breast": type = .breast
            case "bottle": type = .bottle
            case "formula": type = .formula
            case "solid": type = .solid
            default: return nil
            }
            return FeedingViewCell.ViewModel(
                type: type,
                volumeText: entry.volumeText,
                notesText: entry.notesText,
                timeText: entry.timeText,
                dateText: entry.dateText
            )
        }
    }

    static func loadEntries() -> [FeedingLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([FeedingLogEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func saveEntries(_ entries: [FeedingLogEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func save(_ viewModels: [FeedingViewCell.ViewModel]) {
        let entries = viewModels.map { vm -> FeedingLogEntry in
            let raw: String
            switch vm.type {
            case .breast: raw = "breast"
            case .bottle: raw = "bottle"
            case .formula: raw = "formula"
            case .solid: raw = "solid"
            }
            return FeedingLogEntry(
                id: UUID(),
                typeRaw: raw,
                volumeText: vm.volumeText,
                notesText: vm.notesText,
                timeText: vm.timeText,
                dateText: vm.dateText,
                savedAtEpochSeconds: Date().timeIntervalSince1970
            )
        }
        saveEntries(entries)
    }

    static func add(_ viewModel: FeedingViewCell.ViewModel) {
        var entries = loadEntries()
        let raw: String
        switch viewModel.type {
        case .breast: raw = "breast"
        case .bottle: raw = "bottle"
        case .formula: raw = "formula"
        case .solid: raw = "solid"
        }
        let entry = FeedingLogEntry(
            id: UUID(),
            typeRaw: raw,
            volumeText: viewModel.volumeText,
            notesText: viewModel.notesText,
            timeText: viewModel.timeText,
            dateText: viewModel.dateText,
            savedAtEpochSeconds: Date().timeIntervalSince1970
        )
        entries.insert(entry, at: 0)
        saveEntries(entries)
    }
}

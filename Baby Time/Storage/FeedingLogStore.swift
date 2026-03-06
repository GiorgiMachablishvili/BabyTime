import Foundation

/// Persisted feeding log entry (Codable). Convert to/from FeedingViewCell.ViewModel for display.
struct FeedingLogEntry: Codable {
    let typeRaw: String  // "breast", "bottle", "formula", "solid"
    let volumeText: String?
    let notesText: String?
    let timeText: String
    let dateText: String
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
                typeRaw: raw,
                volumeText: vm.volumeText,
                notesText: vm.notesText,
                timeText: vm.timeText,
                dateText: vm.dateText
            )
        }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func add(_ viewModel: FeedingViewCell.ViewModel) {
        var list = load()
        list.insert(viewModel, at: 0)
        save(list)
    }
}

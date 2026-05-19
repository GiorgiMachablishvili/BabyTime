import Foundation

enum FeedingHistoryDataProvider {
    static func loadItems() -> [HistoryItem] {
        FeedingLogStore.loadEntries().compactMap { entry in
            guard let ts = entry.savedAtEpochSeconds else { return nil }
            let date = Date(timeIntervalSince1970: ts)

            let typeTitle: String = {
                switch entry.typeRaw {
                case "breast": return "Breast"
                case "bottle": return "Bottle"
                case "formula": return "Formula"
                case "solid": return "Solid Food"
                default: return "Feeding"
                }
            }()

            let subtitle = [entry.volumeText, entry.notesText]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            return HistoryItem(
                id: entry.id,
                date: date,
                type: .feeding,
                title: typeTitle,
                subtitle: subtitle.isEmpty ? nil : subtitle
            )
        }
        .sorted { $0.date > $1.date }
    }
}


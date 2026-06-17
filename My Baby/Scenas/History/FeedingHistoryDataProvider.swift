import Foundation

enum FeedingHistoryDataProvider {

    static func loadItems() -> [HistoryItem] {
        localItems()
    }

    static func loadItemsFromBackend(completion: @escaping ([HistoryItem]) -> Void) {
        guard AuthStore.isLoggedIn else { completion(localItems()); return }
        APIClient.getFeedings { result in
            switch result {
            case .success(let responses):
                let items = responses.compactMap { r -> HistoryItem? in
                    let ts = r.saved_at_epoch ?? 0
                    let date = Date(timeIntervalSince1970: ts)
                    guard let id = UUID(uuidString: r.id) else { return nil }

                    let typeTitle: String = {
                        switch r.type_raw {
                        case "breast":  return "Breast"
                        case "bottle":  return "Bottle"
                        case "formula": return "Formula"
                        case "solid":   return "Solid Food"
                        default:        return "Feeding"
                        }
                    }()

                    let subtitle = [r.volume_text, r.notes_text]
                        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " • ")

                    return HistoryItem(
                        id: id,
                        date: date,
                        type: .feeding,
                        title: typeTitle,
                        subtitle: subtitle.isEmpty ? nil : subtitle
                    )
                }
                .sorted { $0.date > $1.date }

                // Merge with local entries not yet on server
                let serverIDs = Set(items.map { $0.id })
                let localOnly = localItems().filter { !serverIDs.contains($0.id) }
                completion((items + localOnly).sorted { $0.date > $1.date })

            case .failure:
                completion(localItems())
            }
        }
    }

    private static func localItems() -> [HistoryItem] {
        FeedingLogStore.loadEntries().compactMap { entry in
            guard let ts = entry.savedAtEpochSeconds else { return nil }
            let date = Date(timeIntervalSince1970: ts)

            let typeTitle: String = {
                switch entry.typeRaw {
                case "breast":  return "Breast"
                case "bottle":  return "Bottle"
                case "formula": return "Formula"
                case "solid":   return "Solid Food"
                default:        return "Feeding"
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

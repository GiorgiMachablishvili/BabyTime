import Foundation

struct HistoryItem: Hashable {
    let id: UUID
    let date: Date
    let type: HistoryType
    let title: String
    let subtitle: String?
}

enum HistoryType: Hashable {
    case feeding
    case sleep
    case diaper
    case doctorVisit
    case vaccination
}

struct HistorySection: Hashable {
    let id: String
    let title: String
    let items: [HistoryItem]
}


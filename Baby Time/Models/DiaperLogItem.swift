

import UIKit

struct DiaperLogItem: Hashable {
    let id: UUID
    let type: DiaperType
    let note: String?
    let date: Date

    init(id: UUID = UUID(), type: DiaperType, note: String?, date: Date) {
        self.id = id
        self.type = type
        self.note = note
        self.date = date
    }
}

enum DiaperType: Hashable {
    case wet
    case mixed
    case dirty

    var title: String {
        switch self {
        case .wet: return "Wet"
        case .mixed: return "Mixed Diaper"
        case .dirty: return "Dirty Diaper"
        }
    }

    var subtitleFallback: String { "No notes" }

    var iconText: String {
        switch self {
        case .wet: return "💧"
        case .mixed: return "💧💩"
        case .dirty: return "💩"
        }
    }

    var iconBackground: UIColor {
        switch self {
        case .wet: return UIColor.systemTeal.withAlphaComponent(0.25)
        case .mixed: return UIColor.systemPurple.withAlphaComponent(0.25)
        case .dirty: return UIColor.systemOrange.withAlphaComponent(0.25)
        }
    }
}


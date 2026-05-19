

import Foundation


struct FeedingItem {
    enum FeedingType {
        case breast
        case bottle
        case formula
        case solid
    }

    let type: FeedingType
    let volumeML: Int?          // for bottle/formula/solid
    let durationMinutes: Int?   // for breast, if you track duration
    let notes: String?          // e.g., “apple”
    let date: Date              // save time
}

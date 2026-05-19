import Foundation

/// A single history entry when the user saved height comparison (baby height + date).
struct GrowthHeightHistoryEntry: Codable, Equatable, Identifiable {
    var id: String { "\(savedAt.timeIntervalSince1970)" }
    let babyHeightCm: Double
    let savedAt: Date
}

import Foundation

struct GrowthMeasurement: Codable {
    var id: UUID = UUID()
    var typeRaw: String   // "weight", "height", "head"
    var value: Double     // kg for weight, cm for height/head
    var date: Date
    var percentile: Int?
}

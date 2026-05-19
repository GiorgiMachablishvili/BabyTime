import Foundation

/// Model for height comparison: parent types, heights (cm), and skin tone indices.
struct GrowthComparisonData: Codable, Equatable {
    enum ParentType: String, Codable, CaseIterable {
        case mother
        case father

        var displayName: String {
            switch self {
            case .mother: return "Mother"
            case .father: return "Father"
            }
        }
    }

    var parent1Type: ParentType
    var parent2Type: ParentType
    var parent1HeightCm: Double?
    var parent2HeightCm: Double?
    var babyHeightCm: Double?
    var parent1SkinToneIndex: Int
    var parent2SkinToneIndex: Int
    var babySkinToneIndex: Int

    init(
        parent1Type: ParentType = .mother,
        parent2Type: ParentType = .father,
        parent1HeightCm: Double? = nil,
        parent2HeightCm: Double? = nil,
        babyHeightCm: Double? = nil,
        parent1SkinToneIndex: Int = 0,
        parent2SkinToneIndex: Int = 0,
        babySkinToneIndex: Int = 0
    ) {
        self.parent1Type = parent1Type
        self.parent2Type = parent2Type
        self.parent1HeightCm = parent1HeightCm
        self.parent2HeightCm = parent2HeightCm
        self.babyHeightCm = babyHeightCm
        self.parent1SkinToneIndex = min(max(0, parent1SkinToneIndex), 5)
        self.parent2SkinToneIndex = min(max(0, parent2SkinToneIndex), 5)
        self.babySkinToneIndex = min(max(0, babySkinToneIndex), 5)
    }

    enum CodingKeys: String, CodingKey {
        case parent1Type, parent2Type
        case parent1HeightCm, parent2HeightCm, babyHeightCm
        case parent1SkinToneIndex, parent2SkinToneIndex, babySkinToneIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        parent1Type = try c.decode(ParentType.self, forKey: .parent1Type)
        parent2Type = try c.decode(ParentType.self, forKey: .parent2Type)
        parent1HeightCm = try c.decodeIfPresent(Double.self, forKey: .parent1HeightCm)
        parent2HeightCm = try c.decodeIfPresent(Double.self, forKey: .parent2HeightCm)
        babyHeightCm = try c.decodeIfPresent(Double.self, forKey: .babyHeightCm)
        parent1SkinToneIndex = min(max(0, try c.decode(Int.self, forKey: .parent1SkinToneIndex)), 5)
        parent2SkinToneIndex = min(max(0, try c.decode(Int.self, forKey: .parent2SkinToneIndex)), 5)
        babySkinToneIndex = min(max(0, try c.decodeIfPresent(Int.self, forKey: .babySkinToneIndex) ?? 0), 5)
    }

    /// Sample data for previews and empty state.
    static var sample: GrowthComparisonData {
        GrowthComparisonData(
            parent1Type: .mother,
            parent2Type: .father,
            parent1HeightCm: 165,
            parent2HeightCm: 178,
            babyHeightCm: 62,
            parent1SkinToneIndex: 1,
            parent2SkinToneIndex: 2,
            babySkinToneIndex: 0
        )
    }
}

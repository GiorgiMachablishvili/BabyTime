import UIKit

struct BabyMemory: Codable, Hashable {

    enum Category: String, Codable, CaseIterable {
        case health, funny, memories, growth, other

        var title: String {
            switch self {
            case .health:   return "Health"
            case .funny:    return "Funny"
            case .memories: return "Memories"
            case .growth:   return "Growth"
            case .other:    return "Other"
            }
        }

        var color: UIColor {
            switch self {
            case .health:   return UIColor(hexString: "#4CAF50")
            case .funny:    return UIColor(hexString: "#FF9800")
            case .memories: return UIColor(hexString: "#8b6dc4")
            case .growth:   return UIColor(hexString: "#2196F3")
            case .other:    return UIColor(hexString: "#9E9E9E")
            }
        }

        var iconName: String {
            switch self {
            case .health:   return "heart.fill"
            case .funny:    return "face.smiling.fill"
            case .memories: return "camera.fill"
            case .growth:   return "arrow.up.circle.fill"
            case .other:    return "tag.fill"
            }
        }
    }

    var id: UUID
    var title: String
    var date: Date
    var text: String
    var category: Category
}

enum BabyMemoryStore {
    private static let key = "baby_memories_v1"

    static func load() -> [BabyMemory] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([BabyMemory].self, from: data) else { return [] }
        return items
    }

    static func save(_ items: [BabyMemory]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func delete(id: UUID) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }
}

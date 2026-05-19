import Foundation

struct FeedingReminder: Codable, Equatable {
    enum FeedingType: String, Codable, CaseIterable {
        case breast, bottle, formula, solid
    }

    let id: UUID
    /// Start of the calendar day (seconds since 1970) for this reminder.
    var dayTimestamp: Double
    var hour: Int
    var minute: Int
    var note: String
    var isEnabled: Bool
    /// "breast", "bottle", "formula", "solid"
    var feedingTypeRaw: String

    /// The calendar day (start of day) for this reminder.
    var date: Date {
        get { Date(timeIntervalSince1970: dayTimestamp) }
        set { dayTimestamp = Calendar.current.startOfDay(for: newValue).timeIntervalSince1970 }
    }

    var feedingType: FeedingType {
        get { FeedingType(rawValue: feedingTypeRaw) ?? .solid }
        set { feedingTypeRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), date: Date, hour: Int, minute: Int, note: String, isEnabled: Bool = true, feedingTypeRaw: String = "solid") {
        self.id = id
        self.dayTimestamp = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        self.hour = hour
        self.minute = minute
        self.note = note
        self.isEnabled = isEnabled
        self.feedingTypeRaw = feedingTypeRaw
    }

    enum CodingKeys: String, CodingKey {
        case id, hour, minute, note, isEnabled, dayTimestamp, feedingTypeRaw
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        hour = try c.decode(Int.self, forKey: .hour)
        minute = try c.decode(Int.self, forKey: .minute)
        note = try c.decode(String.self, forKey: .note)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        if let ts = try c.decodeIfPresent(Double.self, forKey: .dayTimestamp) {
            dayTimestamp = ts
        } else {
            dayTimestamp = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        }
        feedingTypeRaw = try c.decodeIfPresent(String.self, forKey: .feedingTypeRaw) ?? "solid"
    }

    var timeString: String {
        let h = hour % 24
        let m = minute % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var comps = DateComponents()
        comps.hour = h
        comps.minute = m
        if let d = Calendar.current.date(from: comps) {
            return formatter.string(from: d)
        }
        return String(format: "%d:%02d", h, m)
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

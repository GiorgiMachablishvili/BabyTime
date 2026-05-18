import Foundation

struct VaccinationReminder: Codable, Equatable {
    static let notifyDaysOptions: [Int] = [1, 3, 5, 10]

    let id: UUID
    var dayTimestamp: Double
    var hour: Int
    var minute: Int
    var note: String
    var isEnabled: Bool
    var notifyDaysBefore: [Int]

    var date: Date {
        get { Date(timeIntervalSince1970: dayTimestamp) }
        set { dayTimestamp = Calendar.current.startOfDay(for: newValue).timeIntervalSince1970 }
    }

    init(id: UUID = UUID(), date: Date, hour: Int, minute: Int, note: String, isEnabled: Bool = true, notifyDaysBefore: [Int] = []) {
        self.id = id
        self.dayTimestamp = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        self.hour = hour
        self.minute = minute
        self.note = note
        self.isEnabled = isEnabled
        self.notifyDaysBefore = notifyDaysBefore.filter { Self.notifyDaysOptions.contains($0) }
    }

    enum CodingKeys: String, CodingKey {
        case id, dayTimestamp, hour, minute, note, isEnabled, notifyDaysBefore
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        dayTimestamp = try c.decode(Double.self, forKey: .dayTimestamp)
        hour = try c.decode(Int.self, forKey: .hour)
        minute = try c.decode(Int.self, forKey: .minute)
        note = try c.decode(String.self, forKey: .note)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        notifyDaysBefore = try c.decodeIfPresent([Int].self, forKey: .notifyDaysBefore) ?? []
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var comps = DateComponents()
        comps.hour = hour % 24
        comps.minute = minute % 60
        if let d = Calendar.current.date(from: comps) {
            return formatter.string(from: d)
        }
        return String(format: "%d:%02d", hour, minute)
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

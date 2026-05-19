import Foundation

/// Visit reminder for Vaccination or Doctor Visit. Notifications fire X days before the visit date.
struct VisitReminder: Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case vaccination
        case doctorVisit
    }

    /// Allowed "notify days before" options.
    static let notifyDaysBeforeOptions: [Int] = [1, 2, 3, 5, 10]

    let id: UUID
    /// Start of the calendar day for the visit.
    var visitDayTimestamp: Double
    var note: String
    /// Which days before the visit to trigger a notification. e.g. [1, 3, 5] = notify 1, 3, and 5 days before.
    var notifyDaysBefore: [Int]
    var kindRaw: String
    /// Optional time of day for display (0-23, 0-59). If nil, no time shown.
    var hour: Int?
    var minute: Int?

    enum CodingKeys: String, CodingKey {
        case id, visitDayTimestamp, note, notifyDaysBefore, kindRaw, hour, minute
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        visitDayTimestamp = try c.decode(Double.self, forKey: .visitDayTimestamp)
        note = try c.decode(String.self, forKey: .note)
        notifyDaysBefore = try c.decode([Int].self, forKey: .notifyDaysBefore)
        kindRaw = try c.decode(String.self, forKey: .kindRaw)
        hour = try c.decodeIfPresent(Int.self, forKey: .hour)
        minute = try c.decodeIfPresent(Int.self, forKey: .minute)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(visitDayTimestamp, forKey: .visitDayTimestamp)
        try c.encode(note, forKey: .note)
        try c.encode(notifyDaysBefore, forKey: .notifyDaysBefore)
        try c.encode(kindRaw, forKey: .kindRaw)
        try c.encodeIfPresent(hour, forKey: .hour)
        try c.encodeIfPresent(minute, forKey: .minute)
    }

    var visitDate: Date {
        get { Date(timeIntervalSince1970: visitDayTimestamp) }
        set { visitDayTimestamp = Calendar.current.startOfDay(for: newValue).timeIntervalSince1970 }
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .vaccination }
        set { kindRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), visitDate: Date, note: String, notifyDaysBefore: [Int], kind: Kind, hour: Int? = nil, minute: Int? = nil) {
        self.id = id
        self.visitDayTimestamp = Calendar.current.startOfDay(for: visitDate).timeIntervalSince1970
        self.note = note
        self.notifyDaysBefore = notifyDaysBefore.filter { Self.notifyDaysBeforeOptions.contains($0) }
        self.kindRaw = kind.rawValue
        self.hour = hour
        self.minute = minute
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: visitDate)
    }

    var shortDateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: visitDate)
    }

    var timeString: String? {
        guard let h = hour, let m = minute else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var comps = DateComponents()
        comps.hour = h % 24
        comps.minute = m % 60
        if let d = Calendar.current.date(from: comps) {
            return formatter.string(from: d)
        }
        return String(format: "%d:%02d", h % 24, m % 60)
    }
}

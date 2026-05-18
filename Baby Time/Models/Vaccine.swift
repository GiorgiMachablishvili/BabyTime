import Foundation

enum VaccineStatus {
    case completed, overdue, dueSoon, scheduled, upcoming

    var badgeTitle: String {
        switch self {
        case .completed: return "Completed"
        case .overdue:   return "Overdue"
        case .dueSoon:   return "Due soon"
        case .scheduled: return "Scheduled"
        case .upcoming:  return "Upcoming"
        }
    }
}

struct Vaccine: Codable, Hashable {
    let id: UUID
    var name: String
    var fullName: String
    var ageRange: String
    var dueDateTimestamp: Double?
    var scheduledTimestamp: Double?
    var scheduledHour: Int?
    var scheduledMinute: Int?
    var completedTimestamp: Double?
    var doseNumber: Int?
    var totalDoses: Int?
    var doctorName: String?
    var notes: String

    var dueDate: Date? {
        get { dueDateTimestamp.map { Date(timeIntervalSince1970: $0) } }
        set { dueDateTimestamp = newValue.map { Calendar.current.startOfDay(for: $0).timeIntervalSince1970 } }
    }
    var scheduledDate: Date? {
        get { scheduledTimestamp.map { Date(timeIntervalSince1970: $0) } }
        set { scheduledTimestamp = newValue.map { $0.timeIntervalSince1970 } }
    }
    var completedDate: Date? {
        get { completedTimestamp.map { Date(timeIntervalSince1970: $0) } }
        set { completedTimestamp = newValue.map { $0.timeIntervalSince1970 } }
    }

    var status: VaccineStatus {
        if completedDate != nil { return .completed }
        if let due = dueDate {
            if due < Date() { return .overdue }
            if let soon = Calendar.current.date(byAdding: .day, value: 30, to: Date()), due <= soon { return .dueSoon }
        }
        if scheduledDate != nil { return .scheduled }
        return .upcoming
    }

    var scheduledTimeString: String? {
        guard let h = scheduledHour, let m = scheduledMinute else { return nil }
        var comps = DateComponents(); comps.hour = h; comps.minute = m
        guard let d = Calendar.current.date(from: comps) else { return nil }
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    var doseInfoString: String? {
        guard let n = doseNumber, let t = totalDoses else { return nil }
        return "\(n) of \(t)"
    }

    init(id: UUID = UUID(), name: String, fullName: String, ageRange: String,
         dueDate: Date? = nil, scheduledDate: Date? = nil,
         scheduledHour: Int? = nil, scheduledMinute: Int? = nil,
         completedDate: Date? = nil,
         doseNumber: Int? = nil, totalDoses: Int? = nil,
         doctorName: String? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.ageRange = ageRange
        self.dueDateTimestamp = dueDate.map { Calendar.current.startOfDay(for: $0).timeIntervalSince1970 }
        self.scheduledTimestamp = scheduledDate.map { $0.timeIntervalSince1970 }
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.completedTimestamp = completedDate.map { $0.timeIntervalSince1970 }
        self.doseNumber = doseNumber
        self.totalDoses = totalDoses
        self.doctorName = doctorName
        self.notes = notes
    }
}

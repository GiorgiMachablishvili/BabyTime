import Foundation

struct DoctorVisit: Codable, Hashable {
    let id: UUID
    var doctorName: String
    var specialty: String
    var clinic: String
    var visitDate: Date
    var visitType: String       // "VACCINATION", "SPECIALIST", "WELL-CHECK", "SICK VISIT"
    var visitTitle: String
    var notes: String
    var weightKg: Double?
    var heightCm: Double?
    var prescriptions: [String]
    var isCompleted: Bool

    var isPast: Bool { visitDate < Date() || isCompleted }

    var shortDateString: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: visitDate)
    }
    var monthString: String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: visitDate).uppercased()
    }
    var dayString: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: visitDate)
    }
    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: visitDate)
    }
    var fullDateTimeString: String {
        let f = DateFormatter(); f.dateFormat = "MMM d, h:mm a"
        return f.string(from: visitDate)
    }

    init(id: UUID = UUID(), doctorName: String, specialty: String = "", clinic: String = "",
         visitDate: Date, visitType: String = "WELL-CHECK", visitTitle: String,
         notes: String = "", weightKg: Double? = nil, heightCm: Double? = nil,
         prescriptions: [String] = [], isCompleted: Bool = false) {
        self.id = id; self.doctorName = doctorName; self.specialty = specialty
        self.clinic = clinic; self.visitDate = visitDate; self.visitType = visitType
        self.visitTitle = visitTitle; self.notes = notes; self.weightKg = weightKg
        self.heightCm = heightCm; self.prescriptions = prescriptions; self.isCompleted = isCompleted
    }
}

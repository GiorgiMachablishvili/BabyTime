import Foundation

enum DoctorVisitStore {
    private static let key = "doctor_visits_v1"

    static func load() -> [DoctorVisit] {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([DoctorVisit].self, from: data) {
            return decoded.sorted { $0.visitDate > $1.visitDate }
        }
        let defaults = defaultVisits()
        save(defaults)
        return defaults.sorted { $0.visitDate > $1.visitDate }
    }

    static func save(_ visits: [DoctorVisit]) {
        guard let data = try? JSONEncoder().encode(visits) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func upsert(_ visit: DoctorVisit) {
        var all = load()
        if let idx = all.firstIndex(where: { $0.id == visit.id }) { all[idx] = visit }
        else { all.append(visit) }
        save(all)
    }

    static func delete(id: UUID) {
        var all = load(); all.removeAll { $0.id == id }; save(all)
    }

    private static func defaultVisits() -> [DoctorVisit] {
        let cal = Calendar.current
        func days(_ n: Int, hour: Int = 10, min: Int = 30) -> Date {
            var comps = cal.dateComponents([.year, .month, .day], from: Date())
            comps.day! += n; comps.hour = hour; comps.minute = min
            return cal.date(from: comps) ?? Date()
        }
        return [
            DoctorVisit(doctorName: "Dr. Sarah Jenkins", specialty: "Pediatrician",
                        clinic: "Willow Creek Clinic", visitDate: days(26),
                        visitType: "WELL-CHECK", visitTitle: "6-Month Well-Check"),
            DoctorVisit(doctorName: "Dr. Sarah Jenkins", specialty: "Pediatrician",
                        clinic: "Willow Creek Clinic", visitDate: days(54),
                        visitType: "VACCINATION", visitTitle: "Well-Check Boosters"),
            DoctorVisit(doctorName: "Dr. Michael Chen", specialty: "Specialist",
                        clinic: "Vision Care Center", visitDate: days(85),
                        visitType: "SPECIALIST", visitTitle: "Pediatric Optometry"),
            DoctorVisit(doctorName: "Dr. Sarah Jenkins", specialty: "Pediatrician",
                        clinic: "Willow Creek Clinic", visitDate: days(-10),
                        visitType: "SICK VISIT", visitTitle: "Sick Visit",
                        notes: "", isCompleted: true),
            DoctorVisit(doctorName: "Dr. Sarah Jenkins", specialty: "Pediatrician",
                        clinic: "Willow Creek Clinic", visitDate: days(-36, hour: 9, min: 0),
                        visitType: "WELL-CHECK", visitTitle: "Well-check",
                        notes: "Baby is meeting all developmental milestones. Lungs are clear. Continue Vitamin D drops daily.",
                        weightKg: 8.4, heightCm: 68.0,
                        prescriptions: ["Poly-Vi-Sol Drops"], isCompleted: true),
        ]
    }
}

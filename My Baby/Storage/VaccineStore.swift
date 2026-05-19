import Foundation

enum VaccineStore {
    private static let key = "vaccine_records_v1"

    static func load() -> [Vaccine] {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Vaccine].self, from: data) {
            return decoded
        }
        let defaults = defaultVaccines()
        save(defaults)
        return defaults
    }

    static func save(_ vaccines: [Vaccine]) {
        guard let data = try? JSONEncoder().encode(vaccines) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func upsert(_ vaccine: Vaccine) {
        var all = load()
        if let idx = all.firstIndex(where: { $0.id == vaccine.id }) {
            all[idx] = vaccine
        } else {
            all.append(vaccine)
        }
        save(all)
    }

    static func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }

    private static func defaultVaccines() -> [Vaccine] {
        let cal = Calendar.current
        let today = Date()
        func daysFromNow(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: n, to: today)!
        }
        return [
            Vaccine(name: "HepB", fullName: "Hepatitis B", ageRange: "Birth",
                    completedDate: daysFromNow(-150)),
            Vaccine(name: "DTaP", fullName: "Diphtheria, Tetanus, Pertussis", ageRange: "2 months",
                    dueDate: daysFromNow(-14), doseNumber: 3, totalDoses: 5,
                    doctorName: "Dr. Sarah Miller"),
            Vaccine(name: "MMR", fullName: "Measles, Mumps, Rubella", ageRange: "6–9 months",
                    dueDate: daysFromNow(10)),
            Vaccine(name: "Influenza", fullName: "Flu Shot – Annual", ageRange: "6+ months",
                    scheduledDate: daysFromNow(55), scheduledHour: 10, scheduledMinute: 30),
            Vaccine(name: "Varicella", fullName: "Chickenpox Vaccine", ageRange: "12–15 months",
                    dueDate: daysFromNow(120)),
            Vaccine(name: "PCV15", fullName: "Pneumococcal Conjugate", ageRange: "12–15 months",
                    dueDate: daysFromNow(135)),
            Vaccine(name: "HepA", fullName: "Hepatitis A", ageRange: "12–23 months",
                    dueDate: daysFromNow(200)),
            Vaccine(name: "MMR", fullName: "Measles, Mumps, Rubella", ageRange: "4–6 years",
                    dueDate: daysFromNow(1200)),
            Vaccine(name: "IPV", fullName: "Inactivated Poliovirus", ageRange: "4–6 years",
                    completedDate: daysFromNow(-180)),
            Vaccine(name: "Hib", fullName: "Haemophilus influenzae type b", ageRange: "2 months",
                    completedDate: daysFromNow(-170)),
            Vaccine(name: "RV", fullName: "Rotavirus", ageRange: "2 months",
                    completedDate: daysFromNow(-168)),
            Vaccine(name: "PCV15", fullName: "Pneumococcal Conjugate", ageRange: "2 months",
                    completedDate: daysFromNow(-165)),
            Vaccine(name: "DTaP", fullName: "Diphtheria, Tetanus, Pertussis", ageRange: "4 months",
                    completedDate: daysFromNow(-120), doseNumber: 2, totalDoses: 5),
            Vaccine(name: "IPV", fullName: "Inactivated Poliovirus", ageRange: "4 months",
                    completedDate: daysFromNow(-118)),
        ]
    }
}

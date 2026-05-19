import Foundation

enum HistoryDataProvider {
    static func loadCombinedItems(now: Date = Date()) -> [HistoryItem] {
        var items: [HistoryItem] = []

        // Feeding (log)
        let feedingEntries = FeedingLogStore.loadEntries()
        for entry in feedingEntries {
            guard let ts = entry.savedAtEpochSeconds else { continue }
            let date = Date(timeIntervalSince1970: ts)
            let subtitle = [entry.volumeText, entry.notesText].compactMap { s in
                let t = s?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (t?.isEmpty == false) ? t : nil
            }.joined(separator: " • ")
            items.append(
                HistoryItem(
                    id: UUID(),
                    date: date,
                    type: .feeding,
                    title: "Feeding",
                    subtitle: subtitle.isEmpty ? nil : subtitle
                )
            )
        }

        // Sleep (sessions)
        let sleepSessions = SleepSessionStore.load()
        for s in sleepSessions {
            let minutes = max(1, Int(s.duration / 60))
            items.append(
                HistoryItem(
                    id: UUID(),
                    date: s.end,
                    type: .sleep,
                    title: "Sleep",
                    subtitle: "\(minutes) min"
                )
            )
        }

        // Diaper (entries)
        let diaperEntries = DiaperLogStore.load()
        for d in diaperEntries {
            let title = "Diaper"
            items.append(
                HistoryItem(
                    id: d.id,
                    date: d.date,
                    type: .diaper,
                    title: title,
                    subtitle: d.typeRaw.capitalized
                )
            )
        }

        // Doctor Visit / Vaccination (visit reminders)
        let doctorVisits = VisitReminderStore.load(kind: .doctorVisit)
        for v in doctorVisits {
            let date = Calendar.current.startOfDay(for: v.visitDate)
            items.append(
                HistoryItem(
                    id: v.id,
                    date: date,
                    type: .doctorVisit,
                    title: "Doctor Visit",
                    subtitle: v.note.isEmpty ? nil : v.note
                )
            )
        }
        let vaccinations = VisitReminderStore.load(kind: .vaccination)
        for v in vaccinations {
            let date = Calendar.current.startOfDay(for: v.visitDate)
            items.append(
                HistoryItem(
                    id: v.id,
                    date: date,
                    type: .vaccination,
                    title: "Vaccination",
                    subtitle: v.note.isEmpty ? nil : v.note
                )
            )
        }

        return items.sorted { $0.date > $1.date }
    }
}


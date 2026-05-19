import Foundation

/// Groups history items by calendar day. Section header titles are "dd/MM/yyyy".
func groupHistoryByDay(
    items: [HistoryItem],
    now: Date = Date(),
    calendar: Calendar = .current
) -> [HistorySection] {
    let sorted = items.sorted { $0.date > $1.date }

    let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        return df
    }()

    var bucket: [Date: [HistoryItem]] = [:]
    for item in sorted {
        let day = calendar.startOfDay(for: item.date)
        bucket[day, default: []].append(item)
    }

    let days = bucket.keys.sorted(by: >)
    return days.enumerated().map { index, day in
        let sectionId = "day-\(Int(day.timeIntervalSince1970))"
        return HistorySection(
            id: sectionId,
            title: formatter.string(from: day),
            items: bucket[day]?.sorted(by: { $0.date > $1.date }) ?? []
        )
    }
}


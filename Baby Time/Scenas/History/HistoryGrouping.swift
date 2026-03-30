import Foundation

func groupHistory(items: [HistoryItem], now: Date = Date(), calendar: Calendar = .current) -> [HistorySection] {
    let sorted = items.sorted { $0.date > $1.date }

    let startOfToday = calendar.startOfDay(for: now)
    let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday

    let startOfWeek: Date = {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return calendar.date(from: comps) ?? startOfToday
    }()

    var today: [HistoryItem] = []
    var yesterday: [HistoryItem] = []
    var thisWeek: [HistoryItem] = []
    var earlier: [HistoryItem] = []

    for item in sorted {
        if item.date >= startOfToday {
            today.append(item)
        } else if item.date >= startOfYesterday {
            yesterday.append(item)
        } else if item.date >= startOfWeek {
            thisWeek.append(item)
        } else {
            earlier.append(item)
        }
    }

    var sections: [HistorySection] = []
    if !today.isEmpty { sections.append(HistorySection(id: "today", title: "Today", items: today)) }
    if !yesterday.isEmpty { sections.append(HistorySection(id: "yesterday", title: "Yesterday", items: yesterday)) }
    if !thisWeek.isEmpty { sections.append(HistorySection(id: "thisWeek", title: "This Week", items: thisWeek)) }
    if !earlier.isEmpty { sections.append(HistorySection(id: "earlier", title: "Earlier", items: earlier)) }
    return sections
}


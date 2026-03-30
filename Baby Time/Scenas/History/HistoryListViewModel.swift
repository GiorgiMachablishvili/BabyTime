import Foundation

protocol HistoryListViewModeling: AnyObject {
    var onChange: (() -> Void)? { get set }
    var sections: [HistorySection] { get }
    func reload()
    func section(at index: Int) -> HistorySection?
}

final class HistoryListViewModel: HistoryListViewModeling {
    var onChange: (() -> Void)?
    private(set) var sections: [HistorySection] = []

    private let now: () -> Date
    private let loadItems: () -> [HistoryItem]
    private let group: (_ items: [HistoryItem], _ now: Date) -> [HistorySection]

    init(
        loadItems: @escaping () -> [HistoryItem],
        now: @escaping () -> Date = Date.init,
        group: @escaping (_ items: [HistoryItem], _ now: Date) -> [HistorySection] = { items, now in
            groupHistory(items: items, now: now)
        }
    ) {
        self.loadItems = loadItems
        self.now = now
        self.group = group
    }

    func reload() {
        let items = loadItems()
        sections = group(items, now())
        onChange?()
    }

    func section(at index: Int) -> HistorySection? {
        guard index >= 0, index < sections.count else { return nil }
        return sections[index]
    }
}


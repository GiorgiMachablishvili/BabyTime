import UIKit

/// Feeding-only history. Sections are dates (dd/MM/yyyy).
final class FeedingHistoryViewController: UIViewController {
    private let child: HistoryListViewController

    init() {
        let vm = HistoryListViewModel(
            loadItems: { FeedingHistoryDataProvider.loadItems() },
            group: { items, now in
                groupHistoryByDay(items: items, now: now)
            }
        )
        self.child = HistoryListViewController(title: "Feeding History", viewModel: vm)
        super.init(nibName: nil, bundle: nil)
        self.title = "Feeding History"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        child.didMove(toParent: self)
    }
}


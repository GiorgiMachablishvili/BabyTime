import UIKit

/// Combined history for Feeding/Sleep/Diaper/Doctor Visit/Vaccination.
final class HistoryViewController: UIViewController {
    private let child: HistoryListViewController

    init() {
        let vm = HistoryListViewModel(loadItems: { HistoryDataProvider.loadCombinedItems() })
        self.child = HistoryListViewController(title: "History", viewModel: vm)
        super.init(nibName: nil, bundle: nil)
        self.title = "History"
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


import UIKit
import SnapKit

final class HistoryListViewController: UIViewController {

    private typealias SectionId = String
    private typealias ItemId = UUID

    private let viewModel: HistoryListViewModeling
    private let showsSeeAll: (HistorySection) -> Bool
    private let onTapSeeAll: (HistorySection) -> Void

    private lazy var emptyStateView: EmptyStateView = {
        let v = EmptyStateView()
        v.configure(
            icon: UIImage(systemName: "clock.arrow.circlepath"),
            iconTint: .systemOrange.withAlphaComponent(0.9),
            circleColor: .systemOrange.withAlphaComponent(0.18),
            title: "No history yet",
            subtitle: "Your recent activity will show up here."
        )
        v.isHidden = true
        return v
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.register(HistoryItemCell.self, forCellWithReuseIdentifier: HistoryItemCell.reuseId)
        cv.register(HistorySectionHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: HistorySectionHeaderView.reuseId)
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<SectionId, ItemId>!
    private var currentSections: [HistorySection] = []
    private var itemById: [UUID: HistoryItem] = [:]

    init(
        title: String,
        viewModel: HistoryListViewModeling,
        showsSeeAll: @escaping (HistorySection) -> Bool = { _ in false },
        onTapSeeAll: @escaping (HistorySection) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.showsSeeAll = showsSeeAll
        self.onTapSeeAll = onTapSeeAll
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()
        configureDataSource()
        bind()
        viewModel.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyStateView.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(24 * Constraint.yCoeff)
        }
    }

    private func bind() {
        viewModel.onChange = { [weak self] in
            self?.applySnapshot(animated: true)
        }
    }

    private func applySnapshot(animated: Bool) {
        let sections = viewModel.sections
        currentSections = sections
        itemById = Dictionary(uniqueKeysWithValues: sections.flatMap(\.items).map { ($0.id, $0) })

        emptyStateView.isHidden = !sections.isEmpty
        collectionView.isHidden = sections.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<SectionId, ItemId>()
        snapshot.appendSections(sections.map(\.id))
        for section in sections {
            snapshot.appendItems(section.items.map(\.id), toSection: section.id)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<SectionId, ItemId>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemId in
            guard let self else { return UICollectionViewCell() }
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HistoryItemCell.reuseId,
                for: indexPath
            ) as! HistoryItemCell
            if let historyItem = self.itemById[itemId] {
                let timeText = Self.timeFormatter.string(from: historyItem.date)
                cell.configure(title: historyItem.title, subtitle: historyItem.subtitle, timeText: timeText, type: historyItem.type)
            }
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: HistorySectionHeaderView.reuseId,
                for: indexPath
            ) as! HistorySectionHeaderView
            guard indexPath.section >= 0, indexPath.section < self.currentSections.count else { return header }
            let section = self.currentSections[indexPath.section]
            header.configure(title: section.title, showsSeeAll: self.showsSeeAll(section))
            header.onTapSeeAll = { [weak self] in self?.onTapSeeAll(section) }
            return header
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(72)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(72)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
            return section
        }
    }

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        return df
    }()
}


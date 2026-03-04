import UIKit
import SnapKit

final class DiaperViewController: UIViewController {

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case summary
        case items
    }

    private nonisolated enum Item: Hashable, Sendable {
        case summary
        case log(DiaperLogItem)
    }

    private var items: [DiaperLogItem] = []

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        view.onTapPlus = { [weak self] in
            self?.diaperActionCardButtonPressed()
        }
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private lazy var daiperView: DaiperView = {
        let view = DaiperView()
        view.isHidden = true

        view.onTapCloseButton = { [weak self] in
            self?.dismissBottomSheet()
        }

        view.onTapSave = { [weak self] selectedType in
            guard let self else { return }

            let newItem = DiaperLogItem(type: selectedType, note: nil, date: Date())
            self.items.insert(newItem, at: 0)

            self.applySnapshot(animated: true)
            self.dismissBottomSheet()
        }

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor

        setupUI()
        setupConstraints()
        configureViews()
        configureCollection()
        applySnapshot(animated: false)
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(collectionView)
        view.addSubview(daiperView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        daiperView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Diaper Log",
            subtitle: "Track diaper changes",
            showsPlusButton: true,
            plusColor: .diaperViewColor
        )
    }

    // MARK: - Bottom sheet

    private func diaperActionCardButtonPressed() {
        daiperView.isHidden = false
        daiperView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)

        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut]) {
            self.daiperView.transform = .identity
        }
    }

    private func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.daiperView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.daiperView.isHidden = true
        }
    }

    // MARK: - Collection

    private func configureCollection() {
        collectionView.register(DiaperSummaryCell.self, forCellWithReuseIdentifier: DiaperSummaryCell.reuseId)
        collectionView.register(DiaperLogCell.self, forCellWithReuseIdentifier: DiaperLogCell.reuseId)

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { (collectionView: UICollectionView, indexPath: IndexPath, item: Item) in

            let section = Section(rawValue: indexPath.section)!

            switch section {
            case .summary:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DiaperSummaryCell.reuseId,
                    for: indexPath
                ) as! DiaperSummaryCell

                // 👇 WRITE THE CODE HERE
                let mixedCount = self.items.filter { $0.type == .mixed }.count
                let wetCount = self.items.filter { $0.type == .wet }.count + mixedCount
                let dirtyCount = self.items.filter { $0.type == .dirty }.count + mixedCount

                cell.configure(
                    wetCount: wetCount,
                    mixedCount: mixedCount,
                    dirtyCount: dirtyCount
                )

                return cell

            case .items:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DiaperLogCell.reuseId,
                    for: indexPath
                ) as! DiaperLogCell

                switch item {
                case .log(let log):
                    cell.configure(item: log)
                    cell.onDelete = { [weak self] in
                        guard let self else { return }
                        self.items.remove(at: indexPath.item)
                        self.applySnapshot(animated: true)
                    }
                default:
                    break
                }
                return cell
            }
        }

    }

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.summary, .items])

        snapshot.appendItems([.summary], toSection: .summary) // dummy item for 1 summary cell
        snapshot.appendItems(items.map { Item.log($0) }, toSection: .items)

        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, env in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .summary:
                let item = NSCollectionLayoutItem(layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                ))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(110)
                ), subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section

            case .items:
                let item = NSCollectionLayoutItem(layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                ))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(92)
                ), subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 14
                section.contentInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            }
        }
    }
}


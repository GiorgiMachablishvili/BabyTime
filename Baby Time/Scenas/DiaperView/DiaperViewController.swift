import UIKit
import SnapKit

// MARK: - DiaperType design extensions

extension DiaperType {
    var accentColor: UIColor {
        switch self {
        case .wet:   return UIColor(hexString: "#5aac7c")
        case .dirty: return UIColor(hexString: "#d4813a")
        case .mixed: return UIColor(hexString: "#7c5abf")
        }
    }
    var lightBackground: UIColor {
        switch self {
        case .wet:   return UIColor(hexString: "#e4f5ec")
        case .dirty: return UIColor(hexString: "#fdecd8")
        case .mixed: return UIColor(hexString: "#ebe0f8")
        }
    }
    var sfSymbol: String {
        switch self {
        case .wet:   return "drop.fill"
        case .dirty: return "leaf.fill"
        case .mixed: return "square.3.layers.3d"
        }
    }
    var badgeTitle: String {
        switch self {
        case .wet:   return "Wet"
        case .dirty: return "Dirty"
        case .mixed: return "Mixed"
        }
    }
}

// MARK: - DayCount (used by DiaperChartCell)

struct DayCount {
    let symbol: String
    let count: Int
    let isToday: Bool
}

// MARK: - Section header supplementary view

final class DiaperSectionHeaderView: UICollectionReusableView {
    static let reuseId = "DiaperSectionHeaderView"

    private let leftLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private let rightLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888")
        return l
    }()

    private lazy var rightButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        b.setTitleColor(UIColor(hexString: "#5aac7c"), for: .normal)
        b.addTarget(self, action: #selector(rightTapped), for: .touchUpInside)
        return b
    }()

    var onRightTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        [leftLabel, rightLabel, rightButton].forEach { addSubview($0) }

        leftLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
        rightLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        rightButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func rightTapped() { onRightTap?() }

    func configure(left: String, right: String? = nil, rightButtonTitle: String? = nil, onTap: (() -> Void)? = nil) {
        leftLabel.text = left
        rightLabel.text = right
        rightLabel.isHidden = right == nil
        rightButton.setTitle(rightButtonTitle, for: .normal)
        rightButton.isHidden = rightButtonTitle == nil
        onRightTap = onTap
    }
}

// MARK: - DiaperViewController

final class DiaperViewController: UIViewController {

    // MARK: - Sections / Items

    private nonisolated enum Section: Int, CaseIterable, Sendable { case pills, quickLog, chart, today }
    private nonisolated enum Item: Hashable, Sendable {
        case pills, quickLog, chart
        case log(DiaperLogItem)
    }

    // MARK: - State

    private var items: [DiaperLogItem] = []

    private var todayItems: [DiaperLogItem] {
        items.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var avgText: String {
        let total = last7DayCounts().reduce(0) { $0 + $1.count }
        return String(format: "Avg: %.1f/day", Double(total) / 7.0)
    }

    // MARK: - Header UI

    private lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .viewsBackGourdColor
        return v
    }()

    private lazy var avatarButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#c5d8dc")
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 22 * Constraint.yCoeff
        b.clipsToBounds = true
        b.isUserInteractionEnabled = false
        return b
    }()

    private lazy var nameTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private lazy var dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff)
        l.textColor = UIColor(hexString: "#888888")
        return l
    }()

    private lazy var gearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "gearshape"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return b
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Collection UI

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)
        return cv
    }()


    private lazy var diaperView: DiaperView = {
        let v = DiaperView()
        v.isHidden = true
        v.onTapCloseButton = { [weak self] in self?.dismissBottomSheet() }
        v.onTapSave = { [weak self] type, note in
            guard let self else { return }
            self.addEntry(type: type, note: note)
            self.dismissBottomSheet()
        }
        return v
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        loadFromStore()
        setupUI()
        setupConstraints()
        configureCollection()
        applySnapshot(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        let isPushed = navigationController?.viewControllers.count ?? 0 > 1
        backButton.isHidden = !isPushed
        gearButton.isHidden = isPushed
        let pad = 20 * Constraint.xCoeff
        avatarButton.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(isPushed ? 44 * Constraint.xCoeff : pad)
        }
        refreshHeader()
    }

    // MARK: - Header

    private func refreshHeader() {
        let name = BabyProfileStore.loadName() ?? "Baby"
        nameTitleLabel.text = "\(name)'s Day"
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        dateLabel.text = df.string(from: Date())
        if let photo = BabyProfileStore.loadPhoto() {
            avatarButton.setBackgroundImage(photo, for: .normal)
            avatarButton.setImage(nil, for: .normal)
            avatarButton.contentHorizontalAlignment = .fill
            avatarButton.contentVerticalAlignment = .fill
        }
    }

    // MARK: - Store

    private func loadFromStore() {
        items = DiaperLogStore.load().compactMap { entry in
            let type: DiaperType
            switch entry.typeRaw {
            case "wet":   type = .wet
            case "mixed": type = .mixed
            case "dirty": type = .dirty
            default: return nil
            }
            return DiaperLogItem(id: entry.id, type: type, note: entry.note, date: entry.date)
        }
    }

    private func saveToStore() {
        let entries = items.map { item -> DiaperLogEntry in
            let raw: String
            switch item.type {
            case .wet:   raw = "wet"
            case .mixed: raw = "mixed"
            case .dirty: raw = "dirty"
            }
            return DiaperLogEntry(id: item.id, typeRaw: raw, note: item.note, date: item.date)
        }
        DiaperLogStore.save(entries)
    }

    // MARK: - Data helpers

    func last7DayCounts() -> [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let df = DateFormatter()
        df.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset -> DayCount in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = items.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            return DayCount(symbol: df.string(from: day), count: count, isToday: offset == 0)
        }
    }

    private func addEntry(type: DiaperType, note: String?) {
        let item = DiaperLogItem(type: type, note: note, date: Date())
        items.insert(item, at: 0)
        saveToStore()
        applySnapshot(animated: true)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(avatarButton)
        headerView.addSubview(nameTitleLabel)
        headerView.addSubview(dateLabel)
        headerView.addSubview(gearButton)
        headerView.addSubview(backButton)
        view.addSubview(collectionView)

        view.addSubview(diaperView)
    }

    private func setupConstraints() {
        let pad = 20 * Constraint.xCoeff

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(60 * Constraint.yCoeff)
        }
        avatarButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(pad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        nameTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarButton.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.bottom.equalTo(avatarButton.snp.centerY)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(nameTitleLabel)
            $0.top.equalTo(nameTitleLabel.snp.bottom).offset(2)
        }
        gearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(pad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        diaperView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Collection

    private func configureCollection() {
        collectionView.register(DiaperSummaryCell.self,  forCellWithReuseIdentifier: DiaperSummaryCell.reuseId)
        collectionView.register(DiaperQuickLogCell.self, forCellWithReuseIdentifier: DiaperQuickLogCell.reuseId)
        collectionView.register(DiaperChartCell.self,    forCellWithReuseIdentifier: DiaperChartCell.reuseId)
        collectionView.register(DiaperLogCell.self,      forCellWithReuseIdentifier: DiaperLogCell.reuseId)
        collectionView.register(
            DiaperSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DiaperSectionHeaderView.reuseId
        )

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .pills:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DiaperSummaryCell.reuseId, for: indexPath) as! DiaperSummaryCell
                let today = self.todayItems
                let mixed = today.filter { $0.type == .mixed }.count
                let wet   = today.filter { $0.type == .wet }.count
                let dirty = today.filter { $0.type == .dirty }.count
                cell.configure(wetCount: wet, dirtyCount: dirty, mixedCount: mixed)
                return cell

            case .quickLog:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DiaperQuickLogCell.reuseId, for: indexPath) as! DiaperQuickLogCell
                cell.onQuickLog = { [weak self] type in self?.openSheet(type: type) }
                return cell

            case .chart:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DiaperChartCell.reuseId, for: indexPath) as! DiaperChartCell
                cell.configure(days: self.last7DayCounts())
                return cell

            case .log(let log):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DiaperLogCell.reuseId, for: indexPath) as! DiaperLogCell
                cell.configure(item: log)
                cell.onMenuTap = { [weak self] in
                    guard let self else { return }
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                        self.items.removeAll { $0.id == log.id }
                        self.saveToStore()
                        self.applySnapshot(animated: true)
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    self.present(alert, animated: true)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            let header = cv.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: DiaperSectionHeaderView.reuseId, for: indexPath
            ) as! DiaperSectionHeaderView
            switch indexPath.section {
            case Section.quickLog.rawValue:
                header.configure(left: "Quick Log")
            case Section.chart.rawValue:
                header.configure(left: "Last 7 days", right: self?.avgText)
            case Section.today.rawValue:
                header.configure(left: "Today", rightButtonTitle: "View All", onTap: nil)
            default:
                break
            }
            return header
        }
    }

    private func applySnapshot(animated: Bool) {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections(Section.allCases)
        snap.appendItems([Item.pills],    toSection: .pills)
        snap.appendItems([Item.quickLog], toSection: .quickLog)
        snap.appendItems([Item.chart],    toSection: .chart)
        snap.appendItems(todayItems.map { Item.log($0) }, toSection: .today)
        snap.reconfigureItems([.pills, .chart])
        dataSource.apply(snap, animatingDifferences: animated)
    }

    private func makeLayout() -> UICollectionViewLayout {
        let pad = NSDirectionalEdgeInsets(top: 8, leading: 20 * Constraint.xCoeff, bottom: 12, trailing: 20 * Constraint.xCoeff)

        func makeSection(height: CGFloat, hasHeader: Bool, spacing: CGFloat = 0) -> NSCollectionLayoutSection {
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = pad
            section.interGroupSpacing = spacing
            if hasHeader {
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44 * Constraint.yCoeff)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
            }
            return section
        }

        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch Section(rawValue: sectionIndex) {
            case .pills:    return makeSection(height: 128 * Constraint.yCoeff, hasHeader: false)
            case .quickLog: return makeSection(height: 90 * Constraint.yCoeff,  hasHeader: true)
            case .chart:    return makeSection(height: 170 * Constraint.yCoeff, hasHeader: true)
            case .today:    return makeSection(height: 82 * Constraint.yCoeff,  hasHeader: true, spacing: 10 * Constraint.yCoeff)
            case nil:       return nil
            }
        }
    }

    // MARK: - Actions

    @objc private func settingsTapped() {
        tabBarController?.selectedIndex = 4
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }


    private func openSheet(type: DiaperType, showTypePicker: Bool = false) {
        diaperView.configure(initialType: type, showTypePicker: showTypePicker)
        diaperView.isHidden = false
        diaperView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6) {
            self.diaperView.transform = .identity
        }
    }

    private func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.diaperView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.diaperView.isHidden = true
        }
    }
}

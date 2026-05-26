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
        case .dirty: return "Dry"
        case .mixed: return "Hard"
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

    private nonisolated enum Section: Int, CaseIterable, Sendable { case calendar, pills, quickLog, chart, today }
    private nonisolated enum Item: Hashable, Sendable {
        case calendar, pills, quickLog, chart
        case empty
        case log(DiaperLogItem)
    }

    // MARK: - State

    private var items: [DiaperLogItem] = []
    private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private var todayItems: [DiaperLogItem] {
        items.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
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
        dateLabel.text = df.string(from: selectedDate)
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
        collectionView.register(BabyEmptyLogCell.self,   forCellWithReuseIdentifier: BabyEmptyLogCell.reuseId)
        collectionView.register(DiaperCalendarCell.self, forCellWithReuseIdentifier: DiaperCalendarCell.reuseId)
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
            case .empty:
                return cv.dequeueReusableCell(withReuseIdentifier: BabyEmptyLogCell.reuseId, for: indexPath)

            case .calendar:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DiaperCalendarCell.reuseId, for: indexPath) as! DiaperCalendarCell
                cell.configure(selected: self.selectedDate)
                cell.onDaySelected = { [weak self] date in
                    self?.selectedDate = date
                    self?.refreshHeader()
                    self?.applySnapshot(animated: true)
                }
                cell.onToggleExpand = { [weak self] in
                    guard let self else { return }
                    UIView.animate(withDuration: 0.3) {
                        self.collectionView.performBatchUpdates(nil)
                    }
                }
                return cell

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
                let selDate = self?.selectedDate ?? Date()
                let isToday = Calendar.current.isDateInToday(selDate)
                let title: String
                if isToday {
                    title = "Today"
                } else {
                    let df = DateFormatter()
                    df.dateFormat = "EEEE, MMM d"
                    title = df.string(from: selDate)
                }
                header.configure(left: title, rightButtonTitle: "View All", onTap: nil)
            default:
                break
            }
            return header
        }
    }

    private func applySnapshot(animated: Bool) {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections(Section.allCases)
        snap.appendItems([Item.calendar], toSection: .calendar)
        snap.appendItems([Item.pills],    toSection: .pills)
        snap.appendItems([Item.quickLog], toSection: .quickLog)
        snap.appendItems([Item.chart],    toSection: .chart)
        let logs = todayItems
        if logs.isEmpty {
            snap.appendItems([.empty], toSection: .today)
        } else {
            snap.appendItems(logs.map { Item.log($0) }, toSection: .today)
        }
        snap.reconfigureItems([.pills, .chart])
        snap.reloadSections([.today])
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
            case .calendar:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16 * Constraint.xCoeff, bottom: 0, trailing: 16 * Constraint.xCoeff)
                return sec
            case .pills:    return makeSection(height: 128 * Constraint.yCoeff, hasHeader: false)
            case .quickLog: return makeSection(height: 90 * Constraint.yCoeff,  hasHeader: true)
            case .chart:    return makeSection(height: 170 * Constraint.yCoeff, hasHeader: true)
            case .today:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(82 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(82 * Constraint.yCoeff)), subitems: [item])
                let sec = NSCollectionLayoutSection(group: group)
                sec.interGroupSpacing = 10 * Constraint.yCoeff
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20 * Constraint.xCoeff, bottom: 12, trailing: 20 * Constraint.xCoeff)
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44 * Constraint.yCoeff)),
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                sec.boundarySupplementaryItems = [header]
                return sec
            case nil:       return nil
            }
        }
    }

    // MARK: - Actions

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

// MARK: - DiaperCalendarCell

final class DiaperCalendarCell: UICollectionViewCell {
    static let reuseId = "DiaperCalendarCell"

    var onDaySelected: ((Date) -> Void)?
    var onToggleExpand: (() -> Void)?

    private(set) var isExpanded = false
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()

    private let accent = UIColor(hexString: "#5aac7c")

    // MARK: Collapsed
    private let collapsedView = UIView()
    private var weekDates: [Date] = []
    private var weekCircles: [UIView] = []
    private var weekNumLabels: [UILabel] = []

    // MARK: Expanded
    private let expandedView = UIView()
    private let monthYearLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .center
        return l
    }()
    private lazy var prevBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#5aac7c")
        b.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        return b
    }()
    private lazy var nextBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        b.tintColor = UIColor(hexString: "#5aac7c")
        b.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        return b
    }()
    private var dayButtons: [UIButton] = []

    // MARK: Chevrons
    private lazy var expandChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        b.tintColor = UIColor(hexString: "#5aac7c")
        b.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        return b
    }()
    private lazy var collapseChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        b.tintColor = UIColor(hexString: "#5aac7c")
        b.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        return b
    }()

    private let mainStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        setupCollapsedView()
        setupExpandedView()

        mainStack.addArrangedSubview(collapsedView)
        mainStack.addArrangedSubview(expandedView)
        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        expandedView.isHidden = true
        buildWeekDates()
        reloadWeekStrip()
    }

    private func setupCollapsedView() {
        let symbols = ["M", "T", "W", "T", "F", "S", "S"]
        let strip = UIStackView()
        strip.axis = .horizontal
        strip.distribution = .fillEqually
        strip.alignment = .center

        for (i, sym) in symbols.enumerated() {
            let dayLbl = UILabel()
            dayLbl.text = sym
            dayLbl.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .medium)
            dayLbl.textColor = UIColor(hexString: "#aaaaaa")
            dayLbl.textAlignment = .center

            let circle = UIView()
            circle.layer.cornerRadius = 17 * Constraint.yCoeff

            let numLbl = UILabel()
            numLbl.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
            numLbl.textAlignment = .center

            circle.addSubview(numLbl)
            numLbl.snp.makeConstraints { $0.center.equalToSuperview() }
            circle.snp.makeConstraints { $0.width.height.equalTo(34 * Constraint.yCoeff) }

            let vStack = UIStackView(arrangedSubviews: [dayLbl, circle])
            vStack.axis = .vertical
            vStack.spacing = 3 * Constraint.yCoeff
            vStack.alignment = .center
            vStack.isUserInteractionEnabled = false

            let container = UIView()
            container.addSubview(vStack)
            vStack.snp.makeConstraints { $0.center.equalToSuperview() }

            let btn = UIButton(type: .system)
            btn.tag = i
            btn.addTarget(self, action: #selector(weekDayTapped(_:)), for: .touchUpInside)
            container.addSubview(btn)
            btn.snp.makeConstraints { $0.edges.equalToSuperview() }

            strip.addArrangedSubview(container)
            weekCircles.append(circle)
            weekNumLabels.append(numLbl)
        }

        collapsedView.addSubview(strip)
        collapsedView.addSubview(expandChevron)

        strip.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(6 * Constraint.xCoeff)
            $0.trailing.equalTo(expandChevron.snp.leading).offset(-4 * Constraint.xCoeff)
            $0.height.equalTo(78 * Constraint.yCoeff)
        }
        expandChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24 * Constraint.yCoeff)
        }

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeWeek(_:)))
        swipeLeft.direction = .left
        collapsedView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeWeek(_:)))
        swipeRight.direction = .right
        collapsedView.addGestureRecognizer(swipeRight)
    }

    private func setupExpandedView() {
        expandedView.addSubview(prevBtn)
        expandedView.addSubview(monthYearLabel)
        expandedView.addSubview(nextBtn)
        expandedView.addSubview(collapseChevron)

        prevBtn.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }
        monthYearLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(prevBtn)
        }
        collapseChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(prevBtn)
            $0.width.height.equalTo(24 * Constraint.yCoeff)
        }
        nextBtn.snp.makeConstraints {
            $0.trailing.equalTo(collapseChevron.snp.leading).offset(-4 * Constraint.xCoeff)
            $0.centerY.equalTo(prevBtn)
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }

        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        let namesStack = UIStackView()
        namesStack.axis = .horizontal
        namesStack.distribution = .fillEqually
        for name in dayNames {
            let l = UILabel()
            l.text = name
            l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .medium)
            l.textColor = UIColor(hexString: "#aaaaaa")
            l.textAlignment = .center
            namesStack.addArrangedSubview(l)
        }
        expandedView.addSubview(namesStack)
        namesStack.snp.makeConstraints {
            $0.top.equalTo(prevBtn.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.height.equalTo(20 * Constraint.yCoeff)
        }

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 2 * Constraint.yCoeff

        for row in 0..<6 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.snp.makeConstraints { $0.height.equalTo(36 * Constraint.yCoeff) }
            for col in 0..<7 {
                let btn = UIButton(type: .custom)
                btn.tag = row * 7 + col
                btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
                btn.layer.cornerRadius = 15 * Constraint.yCoeff
                btn.clipsToBounds = true
                btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
                dayButtons.append(btn)
                rowStack.addArrangedSubview(btn)
            }
            gridStack.addArrangedSubview(rowStack)
        }

        expandedView.addSubview(gridStack)
        gridStack.snp.makeConstraints {
            $0.top.equalTo(namesStack.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(8 * Constraint.yCoeff)
        }

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeMonth(_:)))
        swipeLeft.direction = .left
        expandedView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeMonth(_:)))
        swipeRight.direction = .right
        expandedView.addGestureRecognizer(swipeRight)
    }

    // MARK: - Data

    private func buildWeekDates() {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        let offset = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -offset, to: selectedDate) else { return }
        weekDates = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private func reloadWeekStrip() {
        let cal = Calendar.current
        for i in 0..<7 {
            guard i < weekDates.count else { continue }
            let date = weekDates[i]
            weekNumLabels[i].text = "\(cal.component(.day, from: date))"
            let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
            let isToday = cal.isDateInToday(date)
            weekCircles[i].backgroundColor = isSelected ? accent : .clear
            weekNumLabels[i].textColor = isSelected ? .white : (isToday ? accent : UIColor(hexString: "#333333"))
            weekNumLabels[i].font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: isSelected || isToday ? .bold : .regular)
        }
    }

    private func reloadMonthGrid() {
        let cal = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        monthYearLabel.text = df.string(from: displayedMonth)

        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        let weekday = cal.component(.weekday, from: firstDay)
        let offset = (weekday + 5) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)!.count

        for (i, btn) in dayButtons.enumerated() {
            let dayNum = i - offset + 1
            if dayNum < 1 || dayNum > daysInMonth {
                btn.setTitle("", for: .normal)
                btn.isEnabled = false
                btn.backgroundColor = .clear
            } else {
                btn.setTitle("\(dayNum)", for: .normal)
                btn.isEnabled = true
                let date = cal.date(byAdding: .day, value: dayNum - 1, to: firstDay)!
                let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                let isToday = cal.isDateInToday(date)
                if isSelected {
                    btn.backgroundColor = accent
                    btn.setTitleColor(.white, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .bold)
                } else if isToday {
                    btn.backgroundColor = accent.withAlphaComponent(0.12)
                    btn.setTitleColor(accent, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .bold)
                } else {
                    btn.backgroundColor = .clear
                    btn.setTitleColor(UIColor(hexString: "#333333"), for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
                }
            }
        }
    }

    // MARK: - Public

    func configure(selected: Date) {
        selectedDate = Calendar.current.startOfDay(for: selected)
        let cal = Calendar.current
        if !cal.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? displayedMonth
        }
        buildWeekDates()
        reloadWeekStrip()
        if isExpanded { reloadMonthGrid() }
    }

    // MARK: - Actions

    @objc private func toggleExpand() {
        isExpanded.toggle()
        collapsedView.isHidden = isExpanded
        expandedView.isHidden = !isExpanded
        if isExpanded { reloadMonthGrid() }
        onToggleExpand?()
    }

    @objc private func weekDayTapped(_ btn: UIButton) {
        let i = btn.tag
        guard i < weekDates.count else { return }
        selectedDate = weekDates[i]
        let cal = Calendar.current
        if !cal.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? displayedMonth
        }
        reloadWeekStrip()
        onDaySelected?(selectedDate)
    }

    @objc private func dayTapped(_ btn: UIButton) {
        let cal = Calendar.current
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        let weekday = cal.component(.weekday, from: firstDay)
        let offset = (weekday + 5) % 7
        let dayNum = btn.tag - offset + 1
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)!.count
        guard dayNum >= 1, dayNum <= daysInMonth,
              let date = cal.date(byAdding: .day, value: dayNum - 1, to: firstDay) else { return }
        selectedDate = cal.startOfDay(for: date)
        buildWeekDates()
        reloadMonthGrid()
        onDaySelected?(selectedDate)
    }

    @objc private func prevMonth() {
        slideCalendar(expandedView, toRight: true)
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev
        reloadMonthGrid()
    }

    @objc private func nextMonth() {
        slideCalendar(expandedView, toRight: false)
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next
        reloadMonthGrid()
    }

    @objc private func swipeWeek(_ g: UISwipeGestureRecognizer) {
        slideCalendar(collapsedView, toRight: g.direction == .right)
        let offset = g.direction == .left ? 7 : -7
        let cal = Calendar.current
        guard let newMonday = cal.date(byAdding: .day, value: offset, to: weekDates.first ?? selectedDate) else { return }
        let weekday = cal.component(.weekday, from: selectedDate)
        let dayOffset = (weekday + 5) % 7
        selectedDate = cal.date(byAdding: .day, value: dayOffset, to: newMonday) ?? newMonday
        if !cal.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? displayedMonth
        }
        buildWeekDates()
        reloadWeekStrip()
        onDaySelected?(selectedDate)
    }

    @objc private func swipeMonth(_ g: UISwipeGestureRecognizer) {
        if g.direction == .left { nextMonth() } else { prevMonth() }
    }

    private func slideCalendar(_ view: UIView, toRight: Bool) {
        let t = CATransition()
        t.type = .push
        t.subtype = toRight ? .fromLeft : .fromRight
        t.duration = 0.28
        t.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(t, forKey: "calendarSlide")
    }

    // MARK: - Self-sizing

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
        attrs.frame.size.height = isExpanded ? 310 * Constraint.yCoeff : 90 * Constraint.yCoeff
        return attrs
    }
}

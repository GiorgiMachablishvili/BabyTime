import UIKit
import SnapKit

// MARK: - DiaperHistoryViewController

final class DiaperHistoryViewController: UIViewController {

    // MARK: - Callback
    /// Called when the user logs a new diaper from this screen.
    var onNewEntry: ((DiaperType, String?) -> Void)?

    // MARK: - Data
    private var allItems: [DiaperLogItem] = []
    private var sections: [(date: Date, items: [DiaperLogItem])] = []

    private static let statsItemID  = "__dh_stats__"
    private static let footerItemID = "__dh_footer__"

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var footerSectionIndex: Int { sections.count + 1 }

    // MARK: - UI
    private let logButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("  Log New Diaper", for: .normal)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .white
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#4b3ba0")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
        b.clipsToBounds = true
        return b
    }()

    private lazy var diaperSheet: DiaperView = {
        let v = DiaperView()
        v.isHidden = true
        v.onTapCloseButton = { [weak self] in self?.dismissSheet() }
        v.onTapSave = { [weak self] type, note in
            guard let self else { return }
            self.onNewEntry?(type, note)
            self.reloadData()
            self.dismissSheet()
        }
        return v
    }()

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func reloadData() {
        allItems = DiaperLogStore.load().compactMap { entry -> DiaperLogItem? in
            let type: DiaperType
            switch entry.typeRaw {
            case "wet":   type = .wet
            case "mixed": type = .mixed
            case "dirty": type = .dirty
            default: return nil
            }
            return DiaperLogItem(id: entry.id, type: type, note: entry.note, date: entry.date)
        }
        buildSections()
    }

    private func buildSections() {
        let cal = Calendar.current
        var dict: [Date: [DiaperLogItem]] = [:]
        for item in allItems {
            let day = cal.startOfDay(for: item.date)
            dict[day, default: []].append(item)
        }
        sections = dict
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#f7f5f0")
        setupNavBar()
        reloadData()
        setupCollectionView()
        setupDataSource()
        applySnapshot()

        // Floating log button
        view.addSubview(logButton)
        view.addSubview(diaperSheet)
        logButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(12 * Constraint.yCoeff)
            $0.height.equalTo(56 * Constraint.yCoeff)
        }
        diaperSheet.snp.makeConstraints { $0.edges.equalToSuperview() }

        logButton.addTarget(self, action: #selector(logTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupNavBar() {
        title = "Diaper History"

        // Appearance — cream background, no shadow/separator
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hexString: "#f7f5f0")
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 18 * Constraint.yCoeff, weight: .bold),
            .foregroundColor: UIColor(hexString: "#4b3ba0")
        ]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance

        // Back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = UIColor(hexString: "#333333")

    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func logTapped() {
        diaperSheet.configure(initialType: .wet, showTypePicker: true)
        diaperSheet.isHidden = false
        diaperSheet.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6) {
            self.diaperSheet.transform = .identity
        }
    }

    private func dismissSheet() {
        UIView.animate(withDuration: 0.3) {
            self.diaperSheet.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.diaperSheet.isHidden = true
        }
    }

    // MARK: - Collection View

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100 * Constraint.yCoeff, right: 0)

        collectionView.register(DHStatsCell.self,    forCellWithReuseIdentifier: DHStatsCell.reuseId)
        collectionView.register(DHEntryCell.self,    forCellWithReuseIdentifier: DHEntryCell.reuseId)
        collectionView.register(DHFooterCell.self,   forCellWithReuseIdentifier: DHFooterCell.reuseId)
        collectionView.register(
            DHDayHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DHDayHeaderView.reuseId
        )

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }

            if sectionIndex == 0 {
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(140 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(140 * Constraint.yCoeff)), subitems: [item])
                let sec   = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
                return sec

            } else if sectionIndex == self.footerSectionIndex {
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60 * Constraint.yCoeff)), subitems: [item])
                return NSCollectionLayoutSection(group: group)

            } else {
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(76 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(76 * Constraint.yCoeff)), subitems: [item])
                let sec   = NSCollectionLayoutSection(group: group)
                sec.interGroupSpacing = 10 * Constraint.yCoeff
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40 * Constraint.yCoeff))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                sec.boundarySupplementaryItems = [header]
                return sec
            }
        }
    }

    // MARK: - Data Source

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) { [weak self] cv, indexPath, itemID in
            guard let self else { return UICollectionViewCell() }

            if itemID == Self.statsItemID {
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DHStatsCell.reuseId, for: indexPath) as! DHStatsCell
                cell.configure(allItems: self.allItems)
                return cell

            } else if itemID == Self.footerItemID {
                return cv.dequeueReusableCell(withReuseIdentifier: DHFooterCell.reuseId, for: indexPath)

            } else {
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DHEntryCell.reuseId, for: indexPath) as! DHEntryCell
                if let uuid = UUID(uuidString: itemID),
                   let item = self.allItems.first(where: { $0.id == uuid }) {
                    cell.configure(item: item)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader, let self else { return nil }
            let header = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DHDayHeaderView.reuseId, for: indexPath) as! DHDayHeaderView
            let dayIndex = indexPath.section - 1
            guard dayIndex >= 0, dayIndex < self.sections.count else { return header }
            header.configure(date: self.sections[dayIndex].date)
            return header
        }
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()

        snap.appendSections([0])
        snap.appendItems([Self.statsItemID], toSection: 0)

        for (i, (_, items)) in sections.enumerated() {
            snap.appendSections([i + 1])
            snap.appendItems(items.map { $0.id.uuidString }, toSection: i + 1)
        }

        if !allItems.isEmpty {
            snap.appendSections([footerSectionIndex])
            snap.appendItems([Self.footerItemID], toSection: footerSectionIndex)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }
}

// MARK: - DHStatsCell

private final class DHStatsCell: UICollectionViewCell {
    static let reuseId = "DHStatsCell"

    private let last7Chip: DHStatChip
    private let avgChip: DHStatChip

    override init(frame: CGRect) {
        last7Chip = DHStatChip()
        avgChip   = DHStatChip()
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [last7Chip, avgChip])
        stack.axis = .horizontal
        stack.spacing = 12 * Constraint.xCoeff
        stack.distribution = .fillEqually

        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(allItems: [DiaperLogItem]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekAgo = cal.date(byAdding: .day, value: -7, to: today)!
        let last7 = allItems.filter { $0.date >= weekAgo }.count
        let avg = Double(last7) / 7.0

        last7Chip.configure(
            title: "Last 7 Days",
            value: "\(last7)",
            subtitle: "Diapers total",
            accentColor: UIColor(hexString: "#4b3ba0")
        )
        avgChip.configure(
            title: "Avg. per Day",
            value: String(format: "%.1f", avg),
            subtitle: "Steady pace",
            accentColor: UIColor(hexString: "#d4813a")
        )
    }
}

// MARK: - DHStatChip

private final class DHStatChip: UIView {

    private let titleLabel: UILabel
    private let valueLabel: UILabel
    private let subtitleLabel: UILabel
    private let chevronView: UIImageView
    private let accentBar: UIView

    init() {
        titleLabel   = UILabel()
        valueLabel   = UILabel()
        subtitleLabel = UILabel()
        chevronView  = UIImageView()
        accentBar    = UIView()
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 16 * Constraint.yCoeff
        clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#555555")

        valueLabel.font = .systemFont(ofSize: 30 * Constraint.yCoeff, weight: .bold)
        valueLabel.textColor = UIColor(hexString: "#222222")
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        subtitleLabel.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#888888")

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: cfg)
        chevronView.tintColor = UIColor(hexString: "#cccccc")
        chevronView.contentMode = .scaleAspectFit

        // Left accent bar (thin colored strip on left edge)
        accentBar.layer.cornerRadius = 3
        accentBar.clipsToBounds = true

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), chevronView])
        titleRow.axis = .horizontal
        titleRow.alignment = .center

        addSubview(accentBar)
        addSubview(titleRow)
        addSubview(valueLabel)
        addSubview(subtitleLabel)

        accentBar.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(6 * Constraint.xCoeff)
        }
        titleRow.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
            $0.leading.equalTo(accentBar.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(titleRow.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.equalTo(titleRow)
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.equalTo(titleRow)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String, subtitle: String, accentColor: UIColor) {
        titleLabel.text    = title
        valueLabel.text    = value
        subtitleLabel.text = subtitle
        accentBar.backgroundColor = accentColor
        valueLabel.textColor = accentColor
    }
}

// MARK: - DHDayHeaderView

private final class DHDayHeaderView: UICollectionReusableView {
    static let reuseId = "DHDayHeaderView"

    private let label: UILabel

    override init(frame: CGRect) {
        label = UILabel()
        super.init(frame: frame)
        backgroundColor = .clear
        label.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .bold)
        label.textColor = UIColor(hexString: "#222222")
        addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(date: Date) {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            label.text = "Today"
        } else if cal.isDateInYesterday(date) {
            label.text = "Yesterday"
        } else {
            let df = DateFormatter(); df.dateFormat = "EEEE, MMM d"
            label.text = df.string(from: date)
        }
    }
}

// MARK: - DHEntryCell

private final class DHEntryCell: UICollectionViewCell {
    static let reuseId = "DHEntryCell"

    private let accentStrip: UIView
    private let iconCircle: UIView
    private let iconView: UIImageView
    private let nameLabel: UILabel
    private let noteLabel: UILabel
    private let timeLabel: UILabel
    private let chevronView: UIImageView

    override init(frame: CGRect) {
        accentStrip = UIView()
        iconCircle  = UIView()
        iconView    = UIImageView()
        nameLabel   = UILabel()
        noteLabel   = UILabel()
        timeLabel   = UILabel()
        chevronView = UIImageView()
        super.init(frame: frame)

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        accentStrip.layer.cornerRadius = 3
        accentStrip.clipsToBounds = true

        iconCircle.layer.cornerRadius = 22 * Constraint.yCoeff
        iconCircle.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit

        nameLabel.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        nameLabel.textColor = UIColor(hexString: "#222222")

        noteLabel.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        noteLabel.textColor = UIColor(hexString: "#888888")

        timeLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        timeLabel.textColor = UIColor(hexString: "#888888")
        timeLabel.textAlignment = .right
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: cfg)
        chevronView.tintColor = UIColor(hexString: "#cccccc")
        chevronView.contentMode = .scaleAspectFit
        chevronView.setContentHuggingPriority(.required, for: .horizontal)

        iconCircle.addSubview(iconView)
        contentView.addSubview(accentStrip)
        contentView.addSubview(iconCircle)
        contentView.addSubview(nameLabel)
        contentView.addSubview(noteLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(chevronView)

        accentStrip.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(5 * Constraint.xCoeff)
        }
        iconCircle.snp.makeConstraints {
            $0.leading.equalTo(accentStrip.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        chevronView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8 * Constraint.xCoeff)
            $0.height.equalTo(14 * Constraint.yCoeff)
        }
        timeLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronView.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            $0.bottom.equalTo(contentView.snp.centerY).offset(-1)
        }
        noteLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
            $0.top.equalTo(contentView.snp.centerY).offset(2)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: DiaperLogItem) {
        let tf = DateFormatter(); tf.dateFormat = "hh:mm a"
        timeLabel.text = tf.string(from: item.date)
        noteLabel.text = item.note?.isEmpty == false ? item.note : item.type.subtitleFallback

        switch item.type {
        case .wet:
            nameLabel.text = "Wet"
            iconView.image = UIImage(systemName: "drop.fill")
            iconView.tintColor = UIColor(hexString: "#5aac7c")
            iconCircle.backgroundColor = UIColor(hexString: "#e4f5ec")
            accentStrip.backgroundColor = UIColor(hexString: "#5aac7c")
        case .dirty:
            nameLabel.text = "Dirty"
            iconView.image = UIImage(systemName: "leaf.fill")
            iconView.tintColor = UIColor(hexString: "#d4813a")
            iconCircle.backgroundColor = UIColor(hexString: "#fdecd8")
            accentStrip.backgroundColor = UIColor(hexString: "#d4813a")
        case .mixed:
            nameLabel.text = "Mixed"
            iconView.image = UIImage(systemName: "square.3.layers.3d")
            iconView.tintColor = UIColor(hexString: "#7c5abf")
            iconCircle.backgroundColor = UIColor(hexString: "#ebe0f8")
            accentStrip.backgroundColor = UIColor(hexString: "#7c5abf")
        }
    }
}

// MARK: - DHFooterCell

private final class DHFooterCell: UICollectionViewCell {
    static let reuseId = "DHFooterCell"

    private let sparkleView: UIImageView
    private let label: UILabel

    override init(frame: CGRect) {
        sparkleView = UIImageView()
        label       = UILabel()
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        sparkleView.image = UIImage(systemName: "sparkle")
        sparkleView.tintColor = UIColor(hexString: "#cccccc")
        sparkleView.contentMode = .scaleAspectFit

        label.text = "End of history"
        label.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        label.textColor = UIColor(hexString: "#aaaaaa")
        label.textAlignment = .center

        contentView.addSubview(sparkleView)
        contentView.addSubview(label)

        sparkleView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(10 * Constraint.yCoeff)
            $0.width.height.equalTo(18 * Constraint.yCoeff)
        }
        label.snp.makeConstraints {
            $0.top.equalTo(sparkleView.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

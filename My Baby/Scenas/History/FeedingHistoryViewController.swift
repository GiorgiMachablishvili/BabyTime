import UIKit
import SnapKit

// MARK: - FeedingHistoryViewController
// Uses Int/String as diffable-data-source identifiers to avoid the Swift 6
// "@MainActor-isolated Hashable conformance" error that plagues custom enums
// defined in the same file as a @MainActor UIViewController.

final class FeedingHistoryViewController: UIViewController {

    // MARK: State
    private var allEntries: [FeedingLogEntry] = []
    private var sections:   [(title: String, entries: [FeedingLogEntry])] = []
    private var statsItem   = (totalML: 0, avgMin: 0)

    // Section index constants
    // 0          → stats
    // 1 … N      → day sections   (sections[sectionIndex - 1])
    // N + 1      → footer
    private var footerSectionIndex: Int { sections.count + 1 }

    // Item-string sentinels
    private static let statsItemID  = "__stats__"
    private static let footerItemID = "__footer__"

    // MARK: Views
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor      = .clear
        cv.alwaysBounceVertical = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        cv.register(FHStatsCell.self,  forCellWithReuseIdentifier: FHStatsCell.reuseId)
        cv.register(FHEntryCell.self,  forCellWithReuseIdentifier: FHEntryCell.reuseId)
        cv.register(FHFooterCell.self, forCellWithReuseIdentifier: FHFooterCell.reuseId)
        cv.register(FHDayHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: FHDayHeaderView.reuseId)
        return cv
    }()

    // Int sections, String items — both are Sendable with non-@MainActor Hashable
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feeding History"
        view.backgroundColor = UIColor(hexString: "#F7F5F2")
        navigationController?.navigationBar.tintColor = UIColor(hexString: "#6B4EBA")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        configureDataSource()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: Data
    private func reload() {
        applyEntries(FeedingLogStore.loadEntries())

        guard AuthStore.isLoggedIn else { return }
        APIClient.getFeedings { [weak self] result in
            guard let self, case .success(let responses) = result else { return }

            let serverEntries = responses.compactMap { r -> FeedingLogEntry? in
                guard let id = UUID(uuidString: r.id) else { return nil }
                return FeedingLogEntry(
                    id: id,
                    typeRaw: r.type_raw,
                    volumeText: r.volume_text,
                    notesText: r.notes_text,
                    timeText: r.time_text,
                    dateText: r.date_text,
                    savedAtEpochSeconds: r.saved_at_epoch
                )
            }

            let localEntries = FeedingLogStore.loadEntries()
            let serverIDs = Set(serverEntries.map { $0.id })
            let localOnly = localEntries.filter { !serverIDs.contains($0.id) }
            let merged = (serverEntries + localOnly)
                .sorted { ($0.savedAtEpochSeconds ?? 0) > ($1.savedAtEpochSeconds ?? 0) }

            FeedingLogStore.saveEntries(merged)
            self.applyEntries(merged)
        }
    }

    private func applyEntries(_ entries: [FeedingLogEntry]) {
        allEntries = entries.sorted { ($0.savedAtEpochSeconds ?? 0) > ($1.savedAtEpochSeconds ?? 0) }

        var seen:  [String: [FeedingLogEntry]] = [:]
        var order: [String] = []
        let cal = Calendar.current
        let df  = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        for entry in allEntries {
            let date = Date(timeIntervalSince1970: entry.savedAtEpochSeconds ?? 0)
            let key  = df.string(from: cal.startOfDay(for: date))
            if seen[key] == nil { seen[key] = []; order.append(key) }
            seen[key]!.append(entry)
        }
        sections  = order.map { ($0, seen[$0]!) }
        statsItem = (totalML: todayTotalML(), avgMin: avgSessionMinutes())
        applySnapshot()
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()

        // Section 0 — stats
        snap.appendSections([0])
        snap.appendItems([Self.statsItemID], toSection: 0)

        // Sections 1…N — days
        for (i, (_, entries)) in sections.enumerated() {
            snap.appendSections([i + 1])
            snap.appendItems(entries.map { $0.id.uuidString }, toSection: i + 1)
        }

        // Footer section
        if !allEntries.isEmpty {
            snap.appendSections([footerSectionIndex])
            snap.appendItems([Self.footerItemID], toSection: footerSectionIndex)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }

    // MARK: Stats helpers
    private func todayTotalML() -> Int {
        let cal = Calendar.current
        return allEntries
            .filter { cal.isDateInToday(Date(timeIntervalSince1970: $0.savedAtEpochSeconds ?? 0)) }
            .compactMap { parseML($0.volumeText) }
            .reduce(0, +)
    }

    private func avgSessionMinutes() -> Int {
        let mins = allEntries.compactMap { parseMinutes($0.volumeText) }
        return mins.isEmpty ? 0 : mins.reduce(0, +) / mins.count
    }

    private func parseML(_ text: String?) -> Int? {
        guard let t = text,
              let r = t.range(of: #"(\d+)\s*ml"#, options: .regularExpression) else { return nil }
        return Int(String(t[r].filter { $0.isNumber }))
    }

    private func parseMinutes(_ text: String?) -> Int? {
        guard let t = text,
              let r = t.range(of: #"(\d+)\s*min"#, options: .regularExpression) else { return nil }
        return Int(String(t[r].filter { $0.isNumber }))
    }

    // MARK: DataSource
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, String>(
            collectionView: collectionView
        ) { [weak self] cv, indexPath, itemID in
            guard let self else { return UICollectionViewCell() }

            if itemID == Self.statsItemID {
                let cell = cv.dequeueReusableCell(
                    withReuseIdentifier: FHStatsCell.reuseId, for: indexPath) as! FHStatsCell
                cell.configure(totalML: self.statsItem.totalML, avgMin: self.statsItem.avgMin)
                return cell
            }

            if itemID == Self.footerItemID {
                return cv.dequeueReusableCell(
                    withReuseIdentifier: FHFooterCell.reuseId, for: indexPath)
            }

            // Entry cell — look up by UUID string
            let cell = cv.dequeueReusableCell(
                withReuseIdentifier: FHEntryCell.reuseId, for: indexPath) as! FHEntryCell
            if let uuid = UUID(uuidString: itemID),
               let entry = self.allEntries.first(where: { $0.id == uuid }) {
                cell.configure(entry: entry)
            }
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            let header = cv.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FHDayHeaderView.reuseId,
                for: indexPath) as! FHDayHeaderView
            guard let self else { return header }
            // Section 0 = stats (no header), sections 1…N = days
            let dayIndex = indexPath.section - 1
            guard dayIndex >= 0, dayIndex < self.sections.count else {
                header.configure(title: "")
                return header
            }
            header.configure(title: self.sections[dayIndex].title)
            return header
        }
    }

    // MARK: Layout
    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }

            if sectionIndex == 0 {
                // Stats
                let item  = NSCollectionLayoutItem(layoutSize: .init(
                    widthDimension: .fractionalWidth(1), heightDimension: .estimated(110)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                    widthDimension: .fractionalWidth(1), heightDimension: .estimated(110)),
                    subitems: [item])
                return NSCollectionLayoutSection(group: group)
            }

            if sectionIndex == self.footerSectionIndex {
                // Footer
                let item  = NSCollectionLayoutItem(layoutSize: .init(
                    widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                    widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)),
                    subitems: [item])
                return NSCollectionLayoutSection(group: group)
            }

            // Day section
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1), heightDimension: .estimated(72)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                widthDimension: .fractionalWidth(1), heightDimension: .estimated(72)),
                subitems: [item])
            let sec = NSCollectionLayoutSection(group: group)
            sec.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)
            let hSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1), heightDimension: .estimated(40))
            sec.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: hSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top)
            ]
            return sec
        }
    }
}

// MARK: - FHStatsCell

private final class FHStatsCell: UICollectionViewCell {
    static let reuseId = "FHStatsCell"

    private let totalCard: FHStatChip
    private let avgCard:   FHStatChip

    override init(frame: CGRect) {
        totalCard = FHStatChip(tint: UIColor(hexString: "#6B4EBA"),
                               bg:   UIColor(hexString: "#EDE8F8"))
        avgCard   = FHStatChip(tint: UIColor(hexString: "#C17D3C"),
                               bg:   UIColor(hexString: "#FDF0E3"))
        super.init(frame: frame)

        let stack = UIStackView(arrangedSubviews: [totalCard, avgCard])
        stack.axis         = .horizontal
        stack.spacing      = 12
        stack.distribution = .fillEqually
        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-8)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(totalML: Int, avgMin: Int) {
        totalCard.configure(title: "Total Today", value: "\(totalML)", unit: "ml")
        avgCard.configure(title:   "Avg Session",  value: "\(avgMin)",  unit: "min")
    }
}

// MARK: - FHStatChip

private final class FHStatChip: UIView {

    private let titleLabel: UILabel
    private let valueLabel: UILabel
    private let unitLabel:  UILabel

    init(tint: UIColor, bg: UIColor) {
        titleLabel = UILabel()
        valueLabel = UILabel()
        unitLabel  = UILabel()
        super.init(frame: .zero)

        backgroundColor    = bg
        layer.cornerRadius = 16
        clipsToBounds      = true

        titleLabel.font          = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor     = tint.withAlphaComponent(0.75)
        titleLabel.numberOfLines = 1

        valueLabel.font      = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = tint

        unitLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        unitLabel.textColor = tint.withAlphaComponent(0.7)

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
            $0.trailing.lessThanOrEqualToSuperview().inset(14)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalToSuperview().inset(14)
        }
        unitLabel.snp.makeConstraints {
            $0.leading.equalTo(valueLabel.snp.trailing).offset(3)
            $0.lastBaseline.equalTo(valueLabel)
            $0.trailing.lessThanOrEqualTo(titleLabel)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String, unit: String) {
        titleLabel.text = title
        valueLabel.text = value
        unitLabel.text  = unit
    }
}

// MARK: - FHDayHeaderView

private final class FHDayHeaderView: UICollectionReusableView {
    static let reuseId = "FHDayHeaderView"

    private let leftLine:  UIView
    private let rightLine: UIView
    private let label:     UILabel

    override init(frame: CGRect) {
        leftLine  = UIView()
        rightLine = UIView()
        label     = UILabel()
        super.init(frame: frame)

        backgroundColor = .clear
        let lineColor = UIColor(hexString: "#D8D3CC")
        leftLine.backgroundColor  = lineColor
        rightLine.backgroundColor = lineColor

        label.font      = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(hexString: "#888480")
        label.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(leftLine)
        addSubview(rightLine)
        addSubview(label)

        label.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(10)
            $0.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        leftLine.snp.makeConstraints {
            $0.centerY.equalTo(label)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(label.snp.leading).offset(-10)
            $0.height.equalTo(1)
        }
        rightLine.snp.makeConstraints {
            $0.centerY.equalTo(label)
            $0.leading.equalTo(label.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(1)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) { label.text = title }
}

// MARK: - FHEntryCell

private final class FHEntryCell: UICollectionViewCell {
    static let reuseId = "FHEntryCell"

    private let iconContainer: UIView
    private let iconImageView: UIImageView
    private let typeLabel:     UILabel
    private let subtitleLabel: UILabel
    private let valueLabel:    UILabel
    private let unitLabel:     UILabel
    private let checkView:     UIView
    private let checkImage:    UIImageView
    private let purple:        UIColor

    override init(frame: CGRect) {
        iconContainer = UIView()
        iconImageView = UIImageView()
        typeLabel     = UILabel()
        subtitleLabel = UILabel()
        valueLabel    = UILabel()
        unitLabel     = UILabel()
        checkView     = UIView()
        checkImage    = UIImageView()
        purple        = UIColor(hexString: "#6B4EBA")
        super.init(frame: frame)

        contentView.backgroundColor    = .white
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds      = true
        layer.shadowColor    = UIColor.black.cgColor
        layer.shadowOpacity  = 0.06
        layer.shadowOffset   = CGSize(width: 0, height: 2)
        layer.shadowRadius   = 6
        layer.masksToBounds  = false

        iconContainer.layer.cornerRadius = 20
        iconContainer.clipsToBounds      = true
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white

        typeLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        typeLabel.textColor = UIColor(hexString: "#222222")

        subtitleLabel.font      = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#888480")

        valueLabel.font          = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor     = purple
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        unitLabel.font          = .systemFont(ofSize: 11, weight: .medium)
        unitLabel.textColor     = purple.withAlphaComponent(0.7)
        unitLabel.textAlignment = .right

        checkView.backgroundColor    = purple
        checkView.layer.cornerRadius = 12
        checkView.clipsToBounds      = true
        checkImage.image = UIImage(
            systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
        checkImage.tintColor   = .white
        checkImage.contentMode = .scaleAspectFit

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(unitLabel)
        contentView.addSubview(checkView)
        checkView.addSubview(checkImage)

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        iconImageView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20) }
        checkView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        checkImage.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(12) }
        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(checkView.snp.leading).offset(-10)
            $0.top.equalToSuperview().offset(10)
        }
        unitLabel.snp.makeConstraints {
            $0.trailing.equalTo(valueLabel)
            $0.top.equalTo(valueLabel.snp.bottom).offset(1)
            $0.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        typeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(typeLabel.snp.bottom).offset(3)
            $0.leading.equalTo(typeLabel)
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: FeedingLogEntry) {
        let (name, icon, color): (String, String, UIColor) = {
            switch entry.typeRaw {
            case "breast":  return ("Breast",  "figure.and.child.holdinghands", UIColor(hexString: "#8B6DC4"))
            case "bottle":  return ("Bottle",  "baby.bottle.fill",               UIColor(hexString: "#7A9FD4"))
            case "formula": return ("Formula", "testtube.2",                     UIColor(hexString: "#7ABCB0"))
            case "solid":   return ("Solids",  "fork.knife",                     UIColor(hexString: "#C17D3C"))
            default:        return ("Feeding", "drop.fill",                      UIColor(hexString: "#8B6DC4"))
            }
        }()

        typeLabel.text                = name
        iconContainer.backgroundColor = color
        iconImageView.image = UIImage(
            systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))

        var parts: [String] = []
        if !entry.timeText.isEmpty { parts.append(entry.timeText) }
        if let n = entry.notesText, !n.isEmpty { parts.append(n) }
        subtitleLabel.text = parts.joined(separator: " • ")

        let (val, unit) = parseAmount(entry.volumeText)
        valueLabel.text = val
        unitLabel.text  = unit
    }

    private func parseAmount(_ text: String?) -> (String, String) {
        guard let t = text, !t.isEmpty else { return ("–", "") }
        let patterns: [(String, String)] = [
            (#"(\d+)\s*ml"#,  "ml"),
            (#"(\d+)\s*min"#, "min"),
            (#"(\d+)\s*g"#,   "g"),
            (#"(\d+)\s*sec"#, "sec"),
        ]
        for (pattern, unit) in patterns {
            if let r = t.range(of: pattern, options: .regularExpression) {
                return (String(t[r].filter { $0.isNumber }), unit)
            }
        }
        return (t, "")
    }
}

// MARK: - FHFooterCell

private final class FHFooterCell: UICollectionViewCell {
    static let reuseId = "FHFooterCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor   = UIColor(hexString: "#C0BAB0")
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text          = "End of history"
        label.font          = .systemFont(ofSize: 13, weight: .regular)
        label.textColor     = UIColor(hexString: "#C0BAB0")
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis      = .vertical
        stack.spacing   = 6
        stack.alignment = .center
        contentView.addSubview(stack)

        icon.snp.makeConstraints  { $0.width.height.equalTo(24) }
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

import UIKit
import SnapKit

// MARK: - SleepHistoryViewController

final class SleepHistoryViewController: UIViewController {

    // MARK: - Data

    private let allSessions: [SleepSession]
    private var sections: [(date: Date, sessions: [SleepSession])] = []

    private static let statsItemID  = "__sleep_stats__"
    private static let footerItemID = "__sleep_footer__"

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!

    private var footerSectionIndex: Int { sections.count + 1 }

    // MARK: - Init

    init() {
        self.allSessions = SleepSessionStore.load().sorted { $0.start > $1.start }
        super.init(nibName: nil, bundle: nil)
        buildSections()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSections() {
        let cal = Calendar.current
        var dict: [Date: [SleepSession]] = [:]
        for s in allSessions {
            let day = cal.startOfDay(for: s.start)
            dict[day, default: []].append(s)
        }
        sections = dict
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, sessions: $0.value.sorted { $0.start > $1.start }) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sleep History"
        view.backgroundColor = UIColor(hexString: "#f5f3fb")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = UIColor(hexString: "#8b6dc4")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "calendar"),
            style: .plain, target: nil, action: nil
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(hexString: "#8b6dc4")

        setupCollectionView()
        setupDataSource()
        applySnapshot()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Collection View

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)

        collectionView.register(SHStatsCell.self,  forCellWithReuseIdentifier: SHStatsCell.reuseId)
        collectionView.register(SHEntryCell.self,  forCellWithReuseIdentifier: SHEntryCell.reuseId)
        collectionView.register(SHFooterCell.self, forCellWithReuseIdentifier: SHFooterCell.reuseId)
        collectionView.register(
            SHDayHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SHDayHeaderView.reuseId
        )

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }

            if sectionIndex == 0 {
                // Stats chips
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(150 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(150 * Constraint.yCoeff)), subitems: [item])
                let sec   = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
                return sec

            } else if sectionIndex == self.footerSectionIndex {
                // Footer
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80 * Constraint.yCoeff)), subitems: [item])
                return NSCollectionLayoutSection(group: group)

            } else {
                // Day session entries
                let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(74 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(74 * Constraint.yCoeff)), subitems: [item])
                let sec   = NSCollectionLayoutSection(group: group)
                sec.interGroupSpacing = 10 * Constraint.yCoeff
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44 * Constraint.yCoeff))
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
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
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SHStatsCell.reuseId, for: indexPath) as! SHStatsCell
                cell.configure(sessions: self.allSessions)
                return cell

            } else if itemID == Self.footerItemID {
                return cv.dequeueReusableCell(withReuseIdentifier: SHFooterCell.reuseId, for: indexPath)

            } else {
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SHEntryCell.reuseId, for: indexPath) as! SHEntryCell
                if let uuid = UUID(uuidString: itemID),
                   let session = self.allSessions.first(where: { $0.id == uuid }) {
                    cell.configure(session: session)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader, let self else { return nil }
            let header = cv.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SHDayHeaderView.reuseId,
                for: indexPath
            ) as! SHDayHeaderView
            let dayIndex = indexPath.section - 1
            guard dayIndex >= 0, dayIndex < self.sections.count else { return header }
            let (date, sessions) = self.sections[dayIndex]
            header.configure(date: date, sessions: sessions)
            return header
        }
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()

        snap.appendSections([0])
        snap.appendItems([Self.statsItemID], toSection: 0)

        for (i, (_, sessions)) in sections.enumerated() {
            snap.appendSections([i + 1])
            snap.appendItems(sessions.map { $0.id.uuidString }, toSection: i + 1)
        }

        if !allSessions.isEmpty {
            snap.appendSections([footerSectionIndex])
            snap.appendItems([Self.footerItemID], toSection: footerSectionIndex)
        }

        dataSource.apply(snap, animatingDifferences: false)
    }
}

// MARK: - SHStatsCell

private final class SHStatsCell: UICollectionViewCell {
    static let reuseId = "SHStatsCell"

    private let totalChip: SHStatChip
    private let avgChip: SHStatChip

    override init(frame: CGRect) {
        totalChip = SHStatChip(iconName: "moon.fill",      title: "Total Sleep")
        avgChip   = SHStatChip(iconName: "chart.bar.fill", title: "Avg. Stretch")
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [totalChip, avgChip])
        stack.axis = .horizontal
        stack.spacing = 12 * Constraint.xCoeff
        stack.distribution = .fillEqually

        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(sessions: [SleepSession]) {
        let total = sessions.reduce(0.0) { $0 + $1.duration }
        let avg   = sessions.isEmpty ? 0.0 : (total / Double(sessions.count))

        totalChip.setValue(
            formatDuration(total),
            subtitle: "\(sessions.count) session\(sessions.count == 1 ? "" : "s") total"
        )
        avgChip.setValue(
            formatDuration(avg),
            subtitle: "Per session avg."
        )
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds / 3600)
        let m = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - SHStatChip

private final class SHStatChip: UIView {

    private let iconView: UIImageView
    private let titleLabel: UILabel
    private let chevronView: UIImageView
    private let valueLabel: UILabel
    private let subtitleLabel: UILabel

    init(iconName: String, title: String) {
        iconView     = UIImageView()
        titleLabel   = UILabel()
        chevronView  = UIImageView()
        valueLabel   = UILabel()
        subtitleLabel = UILabel()
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 16 * Constraint.yCoeff
        clipsToBounds = true

        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = UIColor(hexString: "#8b6dc4")
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        titleLabel.textColor = UIColor(hexString: "#555555")

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: cfg)
        chevronView.tintColor = UIColor(hexString: "#cccccc")

        valueLabel.font = .systemFont(ofSize: 26 * Constraint.yCoeff, weight: .bold)
        valueLabel.textColor = UIColor(hexString: "#222222")
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        subtitleLabel.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .regular)
        subtitleLabel.textColor = UIColor(hexString: "#8b6dc4")

        let spacer = UIView()
        let topRow = UIStackView(arrangedSubviews: [iconView, titleLabel, spacer, chevronView])
        topRow.axis = .horizontal
        topRow.spacing = 6
        topRow.alignment = .center

        iconView.snp.makeConstraints { $0.width.height.equalTo(16 * Constraint.yCoeff) }

        addSubview(topRow)
        addSubview(valueLabel)
        addSubview(subtitleLabel)

        topRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(topRow.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ value: String, subtitle: String) {
        valueLabel.text   = value
        subtitleLabel.text = subtitle
    }
}

// MARK: - SHDayHeaderView

private final class SHDayHeaderView: UICollectionReusableView {
    static let reuseId = "SHDayHeaderView"

    private let dateLabel: UILabel
    private let totalLabel: UILabel

    override init(frame: CGRect) {
        dateLabel  = UILabel()
        totalLabel = UILabel()
        super.init(frame: frame)
        backgroundColor = .clear

        dateLabel.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .bold)
        dateLabel.textColor = UIColor(hexString: "#222222")

        totalLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        totalLabel.textColor = UIColor(hexString: "#8b6dc4")

        addSubview(dateLabel)
        addSubview(totalLabel)

        dateLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(totalLabel.snp.leading).offset(-8)
        }
        totalLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(date: Date, sessions: [SleepSession]) {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            dateLabel.text = "Today"
        } else if cal.isDateInYesterday(date) {
            dateLabel.text = "Yesterday"
        } else {
            let df = DateFormatter(); df.dateFormat = "EEEE, MMM d"
            dateLabel.text = df.string(from: date)
        }

        let total = sessions.reduce(0.0) { $0 + $1.duration }
        let h = Int(total / 3600)
        let m = Int((total.truncatingRemainder(dividingBy: 3600)) / 60)
        totalLabel.text = (h > 0 ? "\(h)h \(m)m" : "\(m)m") + " total"
    }
}

// MARK: - SHEntryCell

private final class SHEntryCell: UICollectionViewCell {
    static let reuseId = "SHEntryCell"

    private let iconCircle: UIView
    private let iconView: UIImageView
    private let nameLabel: UILabel
    private let timeLabel: UILabel
    private let durationLabel: UILabel
    private let chevronView: UIImageView

    override init(frame: CGRect) {
        iconCircle    = UIView()
        iconView      = UIImageView()
        nameLabel     = UILabel()
        timeLabel     = UILabel()
        durationLabel = UILabel()
        chevronView   = UIImageView()
        super.init(frame: frame)

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        iconCircle.layer.cornerRadius = 22 * Constraint.yCoeff
        iconCircle.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white

        nameLabel.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        nameLabel.textColor = UIColor(hexString: "#222222")

        timeLabel.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        timeLabel.textColor = UIColor(hexString: "#999999")

        durationLabel.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .bold)
        durationLabel.textColor = UIColor(hexString: "#8b6dc4")

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: cfg)
        chevronView.tintColor = UIColor(hexString: "#cccccc")
        chevronView.contentMode = .scaleAspectFit

        iconCircle.addSubview(iconView)
        contentView.addSubview(iconCircle)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(chevronView)

        iconCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
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
        durationLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronView.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-8)
            $0.bottom.equalTo(contentView.snp.centerY).offset(-1)
        }
        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-8)
            $0.top.equalTo(contentView.snp.centerY).offset(2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(session: SleepSession) {
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        timeLabel.text = "\(tf.string(from: session.start)) – \(tf.string(from: session.end))"

        let dur = session.duration
        let h = Int(dur / 3600)
        let m = Int((dur.truncatingRemainder(dividingBy: 3600)) / 60)
        durationLabel.text = h > 0 ? "\(h)h \(m)m" : "\(m)m"

        let hour = Calendar.current.component(.hour, from: session.start)
        if hour >= 19 || hour < 6 {
            nameLabel.text = "Night Sleep"
            iconView.image = UIImage(systemName: "moon.fill")
            iconCircle.backgroundColor = UIColor(hexString: "#3d2b7a")
        } else if hour < 12 {
            nameLabel.text = "Morning Nap"
            iconView.image = UIImage(systemName: "sun.and.horizon.fill")
            iconCircle.backgroundColor = UIColor(hexString: "#f4a261").withAlphaComponent(0.85)
        } else {
            nameLabel.text = "Afternoon Nap"
            iconView.image = UIImage(systemName: "sun.max.fill")
            iconCircle.backgroundColor = UIColor(hexString: "#e76f51").withAlphaComponent(0.85)
        }
    }
}

// MARK: - SHFooterCell

private final class SHFooterCell: UICollectionViewCell {
    static let reuseId = "SHFooterCell"

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
            $0.top.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        label.snp.makeConstraints {
            $0.top.equalTo(sparkleView.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

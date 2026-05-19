import UIKit
import SnapKit

// MARK: - SleepViewController

final class SleepViewController: UIViewController {

    // MARK: - Section / Item

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case dateNav, ringStats, timeline, todayLog
    }

    private nonisolated enum Item: Hashable, Sendable {
        case dateNav, ringStats, timeline
        case session(UUID)
    }

    // MARK: - State

    private var sessions: [SleepSession] = []
    private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    private var activeStartDate: Date?
    private var liveTimer: Timer?

    private lazy var elapsedLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 32 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#8b6dc4")
        l.text = "0:00:00"
        return l
    }()

    private lazy var startedAtLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999")
        return l
    }()

    private lazy var liveTimerCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0eef8")
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.clipsToBounds = true
        v.alpha = 0

        let moonCircle = UIView()
        moonCircle.backgroundColor = UIColor(hexString: "#8b6dc4")
        moonCircle.layer.cornerRadius = 22 * Constraint.yCoeff
        moonCircle.clipsToBounds = true

        let moonIcon = UIImageView(image: UIImage(systemName: "moon.fill"))
        moonIcon.tintColor = .white
        moonIcon.contentMode = .scaleAspectFit
        moonCircle.addSubview(moonIcon)
        moonIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }

        let sleepingLabel = UILabel()
        sleepingLabel.text = "Sleeping"
        sleepingLabel.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        sleepingLabel.textColor = UIColor(hexString: "#444444")

        v.addSubview(moonCircle)
        v.addSubview(sleepingLabel)
        v.addSubview(self.elapsedLabel)
        v.addSubview(self.startedAtLabel)

        moonCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        sleepingLabel.snp.makeConstraints {
            $0.leading.equalTo(moonCircle.snp.trailing).offset(14 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        self.elapsedLabel.snp.makeConstraints {
            $0.leading.equalTo(sleepingLabel)
            $0.top.equalTo(sleepingLabel.snp.bottom).offset(2 * Constraint.yCoeff)
        }
        self.startedAtLabel.snp.makeConstraints {
            $0.leading.equalTo(sleepingLabel)
            $0.top.equalTo(self.elapsedLabel.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }

        return v
    }()

    // MARK: - Views

    private let headerView = SleepHeaderView()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120 * Constraint.yCoeff, right: 0)
        cv.register(SleepCalendarCell.self, forCellWithReuseIdentifier: SleepCalendarCell.reuseId)
        cv.register(SleepRingStatsCell.self, forCellWithReuseIdentifier: SleepRingStatsCell.reuseId)
        cv.register(SleepTimelineCell.self, forCellWithReuseIdentifier: SleepTimelineCell.reuseId)
        cv.register(SleepLogCell.self, forCellWithReuseIdentifier: SleepLogCell.reuseId)
        cv.register(
            SleepSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SleepSectionHeader.reuseId
        )
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private lazy var startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("  Start sleep", for: .normal)
        b.setImage(UIImage(systemName: "moon.fill"), for: .normal)
        b.tintColor = .white
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#8b6dc4")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
        b.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        return b
    }()

    private lazy var logPastButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Log past sleep", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .medium)
        b.setTitleColor(UIColor(hexString: "#8b6dc4"), for: .normal)
        b.addTarget(self, action: #selector(logPastTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupDataSource()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    deinit { liveTimer?.invalidate() }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(collectionView)
        view.addSubview(liveTimerCard)
        view.addSubview(startButton)
        view.addSubview(logPastButton)

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(110 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        liveTimerCard.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(startButton.snp.top).offset(-12 * Constraint.yCoeff)
        }
        startButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(logPastButton.snp.top).offset(-10 * Constraint.yCoeff)
            $0.height.equalTo(56 * Constraint.yCoeff)
        }
        logPastButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8 * Constraint.yCoeff)
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .dateNav:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SleepCalendarCell.reuseId, for: indexPath) as! SleepCalendarCell
                cell.configure(selected: self.selectedDate)
                cell.onDaySelected = { [weak self] date in
                    self?.selectedDate = date
                    self?.applySnapshot()
                }
                cell.onToggleExpand = { [weak self] in
                    guard let self else { return }
                    UIView.animate(withDuration: 0.3) {
                        self.collectionView.performBatchUpdates(nil)
                    }
                }
                return cell

            case .ringStats:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SleepRingStatsCell.reuseId, for: indexPath) as! SleepRingStatsCell
                let daySessions = self.sessionsForSelectedDate()
                cell.configure(sessions: daySessions, goalHours: 14, isLive: self.activeStartDate != nil, liveStart: self.activeStartDate)
                return cell

            case .timeline:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SleepTimelineCell.reuseId, for: indexPath) as! SleepTimelineCell
                cell.configure(sessions: self.sessionsForSelectedDate(), date: self.selectedDate)
                return cell

            case .session(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SleepLogCell.reuseId, for: indexPath) as! SleepLogCell
                if let session = self.sessions.first(where: { $0.id == id }) {
                    cell.configure(session: session)
                    cell.onDelete = { [weak self] in self?.deleteSession(id: id) }
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader, let self else { return nil }
            let header = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SleepSectionHeader.reuseId, for: indexPath) as! SleepSectionHeader
            if indexPath.section == Section.todayLog.rawValue {
                let title = Calendar.current.isDateInToday(self.selectedDate) ? "Today's sleeps" : self.formatDate(self.selectedDate)
                header.configure(title: title)
            } else {
                header.configure(title: "")
            }
            return header
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .dateNav:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)), subitems: [item])
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .ringStats:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(280 * Constraint.yCoeff)), subitems: [item])
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .timeline:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100 * Constraint.yCoeff)), subitems: [item])
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .todayLog:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300 * Constraint.yCoeff)), subitems: [item])
                let sec = NSCollectionLayoutSection(group: group)
                sec.interGroupSpacing = 10 * Constraint.yCoeff
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44 * Constraint.yCoeff))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                sec.boundarySupplementaryItems = [header]
                return sec
            }
        }
    }

    // MARK: - Data

    private func loadData() {
        sessions = SleepSessionStore.load()
        let name = BabyProfileStore.loadName() ?? "Baby"
        headerView.configure(name: name, birthday: BabyProfileStore.loadBirthday(), photo: BabyProfileStore.loadPhoto())
        applySnapshot()
        updateStartButton()
    }

    private func sessionsForSelectedDate() -> [SleepSession] {
        let cal = Calendar.current
        return sessions.filter { s in
            cal.isDate(s.start, inSameDayAs: selectedDate) || cal.isDate(s.end, inSameDayAs: selectedDate)
        }.sorted { $0.start > $1.start }
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections(Section.allCases)
        snap.appendItems([Item.dateNav], toSection: .dateNav)
        snap.appendItems([Item.ringStats], toSection: .ringStats)
        snap.appendItems([Item.timeline], toSection: .timeline)
        let daySessions = sessionsForSelectedDate()
        snap.appendItems(daySessions.map { Item.session($0.id) }, toSection: .todayLog)
        dataSource.apply(snap, animatingDifferences: true)
    }

    private func updateStartButton() {
        if activeStartDate != nil {
            startButton.setTitle("  Stop sleep", for: .normal)
            startButton.backgroundColor = UIColor(hexString: "#c0392b")
            startButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        } else {
            startButton.setTitle("  Start sleep", for: .normal)
            startButton.backgroundColor = UIColor(hexString: "#8b6dc4")
            startButton.setImage(UIImage(systemName: "moon.fill"), for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func startButtonTapped() {
        if activeStartDate == nil {
            let now = Date()
            activeStartDate = now
            selectedDate = Calendar.current.startOfDay(for: now)
            let tf = DateFormatter(); tf.dateFormat = "h:mm a"
            startedAtLabel.text = "Started at \(tf.string(from: now))"
            elapsedLabel.text = "0:00:00"
            liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.refreshLiveUI()
            }
            RunLoop.main.add(liveTimer!, forMode: .common)
            UIView.animate(withDuration: 0.35) { self.liveTimerCard.alpha = 1 }
            collectionView.contentInset.bottom = 210 * Constraint.yCoeff
        } else {
            guard let start = activeStartDate else { return }
            liveTimer?.invalidate(); liveTimer = nil
            let session = SleepSession(start: start, end: Date())
            sessions.insert(session, at: 0)
            SleepSessionStore.save(sessions)
            activeStartDate = nil
            selectedDate = Calendar.current.startOfDay(for: start)
            UIView.animate(withDuration: 0.25) { self.liveTimerCard.alpha = 0 }
            collectionView.contentInset.bottom = 120 * Constraint.yCoeff
        }
        updateStartButton()
        applySnapshot()
    }

    @objc private func logPastTapped() {
        let alert = UIAlertController(title: "Log past sleep", message: "This feature is coming soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func deleteSession(id: UUID) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.sessions.removeAll { $0.id == id }
            SleepSessionStore.save(self.sessions)
            self.applySnapshot()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func refreshLiveUI() {
        guard let start = activeStartDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        let h = Int(elapsed / 3600)
        let m = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        let s = Int(elapsed.truncatingRemainder(dividingBy: 60))
        elapsedLabel.text = String(format: "%d:%02d:%02d", h, m, s)
        var snap = dataSource.snapshot()
        if snap.itemIdentifiers(inSection: .ringStats).contains(Item.ringStats) {
            snap.reconfigureItems([Item.ringStats])
            dataSource.apply(snap, animatingDifferences: false)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "EEEE, MMM d"
        return df.string(from: date)
    }
}

// MARK: - SleepHeaderView

final class SleepHeaderView: UIView {

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.35)
        v.layer.cornerRadius = 22 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv
    }()

    private let avatarInitialLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4")
        l.textAlignment = .center
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888")
        return l
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "gearshape"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarInitialLabel)
        addSubview(nameLabel)
        addSubview(ageLabel)
        addSubview(settingsButton)

        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarInitialLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.bottom.equalTo(avatarView.snp.centerY).offset(-1)
        }
        ageLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(avatarView.snp.centerY).offset(2)
        }
        settingsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.centerY.equalTo(avatarView)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, birthday: Date?, photo: UIImage?) {
        nameLabel.text = name
        ageLabel.text = {
            guard let bd = birthday else { return "" }
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day],
                                           from: cal.startOfDay(for: bd),
                                           to: cal.startOfDay(for: Date()))
            let y = max(0, comps.year ?? 0)
            let m = max(0, comps.month ?? 0)
            let d = max(0, comps.day ?? 0)
            if y == 0 && m == 0 { return "\(d) days old" }
            if y == 0 { return "\(m) months \(d) days old" }
            return "\(y) years \(m) months \(d) days old"
        }()
        if let photo {
            avatarImageView.image = photo; avatarInitialLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarInitialLabel.text = String(name.prefix(1)).uppercased()
            avatarInitialLabel.isHidden = false
        }
    }
}

// MARK: - SleepDateNavCell

final class SleepDateNavCell: UICollectionViewCell {
    static let reuseId = "SleepDateNavCell"
    var onPrev: (() -> Void)?
    var onNext: (() -> Void)?

    private let prevBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        return b
    }()

    private let nextBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        return b
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#333333")
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(prevBtn)
        contentView.addSubview(dateLabel)
        contentView.addSubview(nextBtn)

        prevBtn.snp.makeConstraints { $0.leading.equalToSuperview().inset(8); $0.centerY.equalToSuperview(); $0.width.height.equalTo(36 * Constraint.yCoeff) }
        nextBtn.snp.makeConstraints { $0.trailing.equalToSuperview().inset(8); $0.centerY.equalToSuperview(); $0.width.height.equalTo(36 * Constraint.yCoeff) }
        dateLabel.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.equalTo(prevBtn.snp.trailing); $0.trailing.equalTo(nextBtn.snp.leading) }

        prevBtn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(date: Date) {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let df = DateFormatter(); df.dateFormat = "MMM d"
            dateLabel.text = "Today, \(df.string(from: date))"
        } else if cal.isDateInYesterday(date) {
            let df = DateFormatter(); df.dateFormat = "MMM d"
            dateLabel.text = "Yesterday, \(df.string(from: date))"
        } else {
            let df = DateFormatter(); df.dateFormat = "EEE, MMM d"
            dateLabel.text = df.string(from: date)
        }
    }

    @objc private func prevTapped() { onPrev?() }
    @objc private func nextTapped() { onNext?() }
}

// MARK: - SleepRingStatsCell

final class SleepRingStatsCell: UICollectionViewCell {
    static let reuseId = "SleepRingStatsCell"

    private let ringView = SleepRingView()

    private let totalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .center
        return l
    }()

    private let goalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999")
        l.textAlignment = .center
        return l
    }()

    private let divider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(hexString: "#f0f0f0"); return v
    }()

    private let napsTitle: UILabel = makeStatTitle("Naps")
    private let napsValue: UILabel = makeStatValue()
    private let stretchTitle: UILabel = makeStatTitle("Longest Stretch")
    private let stretchValue: UILabel = makeStatValue()

    private static func makeStatTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999")
        l.textAlignment = .center
        return l
    }

    private static func makeStatValue() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .center
        return l
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 20 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(ringView)
        contentView.addSubview(totalLabel)
        contentView.addSubview(goalLabel)
        contentView.addSubview(divider)
        contentView.addSubview(napsTitle)
        contentView.addSubview(napsValue)
        contentView.addSubview(stretchTitle)
        contentView.addSubview(stretchValue)

        ringView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(160 * Constraint.yCoeff)
        }
        totalLabel.snp.makeConstraints {
            $0.center.equalTo(ringView).offset(-8 * Constraint.yCoeff)
        }
        goalLabel.snp.makeConstraints {
            $0.centerX.equalTo(ringView)
            $0.top.equalTo(totalLabel.snp.bottom).offset(2 * Constraint.yCoeff)
        }
        divider.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.top.equalTo(ringView.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.height.equalTo(1)
        }

        let halfW = (UIScreen.main.bounds.width - 32) / 2
        napsTitle.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview()
            $0.width.equalTo(halfW)
        }
        napsValue.snp.makeConstraints {
            $0.top.equalTo(napsTitle.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.equalToSuperview()
            $0.width.equalTo(halfW)
        }
        stretchTitle.snp.makeConstraints {
            $0.top.equalTo(napsTitle)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(halfW)
        }
        stretchValue.snp.makeConstraints {
            $0.top.equalTo(napsValue)
            $0.trailing.equalToSuperview()
            $0.width.equalTo(halfW)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(sessions: [SleepSession], goalHours: Double, isLive: Bool, liveStart: Date?) {
        var totalSeconds = sessions.reduce(0.0) { $0 + $1.duration }
        if isLive, let start = liveStart { totalSeconds += Date().timeIntervalSince(start) }

        let totalH = Int(totalSeconds / 3600)
        let totalM = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        totalLabel.text = totalH > 0 ? "\(totalH)h \(totalM)m" : "\(totalM)m"
        goalLabel.text = "/\(Int(goalHours))h goal"

        let progress = min(totalSeconds / (goalHours * 3600), 1.0)
        ringView.setProgress(CGFloat(progress))

        let naps = sessions.filter { isNap($0) }.count
        napsValue.text = "\(naps)"

        let longest = sessions.max(by: { $0.duration < $1.duration })?.duration ?? 0
        let lH = Int(longest / 3600); let lM = Int((longest.truncatingRemainder(dividingBy: 3600)) / 60)
        stretchValue.text = lH > 0 ? "\(lH)h \(lM)m" : "\(lM)m"
        if sessions.isEmpty { stretchValue.text = "—"; napsValue.text = "0" }
    }

    private func isNap(_ s: SleepSession) -> Bool {
        let h = Calendar.current.component(.hour, from: s.start)
        return h >= 6 && h < 19
    }
}

// MARK: - SleepRingView

private final class SleepRingView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(hexString: "#f0eef8").cgColor
        trackLayer.lineWidth = 14
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(hexString: "#8b6dc4").cgColor
        progressLayer.lineWidth = 14
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setProgress(_ value: CGFloat) {
        progress = value
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - 14) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * .pi
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        progressLayer.strokeEnd = progress
    }
}

// MARK: - SleepTimelineCell

final class SleepTimelineCell: UICollectionViewCell {
    static let reuseId = "SleepTimelineCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Sleep timeline"
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f5f0ff")
        v.layer.cornerRadius = 16 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let amLabel: UILabel = makeTimeLabel("12am")
    private let noonLabel: UILabel = makeTimeLabel("12pm")
    private let pmLabel: UILabel = makeTimeLabel("11:59pm")

    private static func makeTimeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#aaaaaa")
        return l
    }

    private var segmentViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(trackView)
        contentView.addSubview(amLabel)
        contentView.addSubview(noonLabel)
        contentView.addSubview(pmLabel)

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }
        trackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(38 * Constraint.yCoeff)
        }
        amLabel.snp.makeConstraints {
            $0.top.equalTo(trackView.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.equalToSuperview()
        }
        noonLabel.snp.makeConstraints {
            $0.top.equalTo(amLabel)
            $0.centerX.equalToSuperview()
        }
        pmLabel.snp.makeConstraints {
            $0.top.equalTo(amLabel)
            $0.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(sessions: [SleepSession], date: Date) {
        segmentViews.forEach { $0.removeFromSuperview() }
        segmentViews = []

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = dayStart.addingTimeInterval(86400)

        for session in sessions {
            let clampedStart = max(session.start, dayStart)
            let clampedEnd = min(session.end, dayEnd)
            guard clampedEnd > clampedStart else { continue }

            let startFraction = clampedStart.timeIntervalSince(dayStart) / 86400
            let endFraction = clampedEnd.timeIntervalSince(dayStart) / 86400

            let seg = UIView()
            let isNightHour = cal.component(.hour, from: session.start) >= 19 || cal.component(.hour, from: session.start) < 6
            seg.backgroundColor = isNightHour ? UIColor(hexString: "#8b6dc4") : UIColor(hexString: "#f0b7a5")
            seg.layer.cornerRadius = 14 * Constraint.yCoeff
            trackView.addSubview(seg)

            seg.snp.makeConstraints {
                $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
                $0.leading.equalToSuperview().multipliedBy(startFraction).offset(startFraction * trackView.bounds.width == 0 ? startFraction : 0)
            }
            segmentViews.append(seg)

            seg.tag = Int(startFraction * 10000)
            seg.accessibilityValue = "\(startFraction),\(endFraction)"
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let trackW = trackView.bounds.width
        guard trackW > 0 else { return }

        for seg in segmentViews {
            guard let fracs = seg.accessibilityValue?.split(separator: ",").compactMap({ Double($0) }),
                  fracs.count == 2 else { continue }
            let x = CGFloat(fracs[0]) * trackW
            let w = max(CGFloat(fracs[1] - fracs[0]) * trackW, 8 * Constraint.xCoeff)
            seg.frame = CGRect(x: x, y: 4 * Constraint.yCoeff, width: w, height: trackView.bounds.height - 8 * Constraint.yCoeff)
            seg.layer.cornerRadius = seg.bounds.height / 2
        }
    }
}

// MARK: - SleepLogCell

final class SleepLogCell: UICollectionViewCell {
    static let reuseId = "SleepLogCell"
    var onDelete: (() -> Void)?

    private let iconCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 22 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private let timeRangeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999")
        return l
    }()

    private let durationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4")
        l.textAlignment = .right
        return l
    }()

    private lazy var menuButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        b.tintColor = UIColor(hexString: "#cccccc")
        b.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(iconCircle)
        iconCircle.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeRangeLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(menuButton)

        iconCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }
        durationLabel.snp.makeConstraints {
            $0.trailing.equalTo(menuButton.snp.leading).offset(-4 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.bottom.equalTo(contentView.snp.centerY).offset(-1)
        }
        timeRangeLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.top.equalTo(contentView.snp.centerY).offset(2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDelete = nil
    }

    func configure(session: SleepSession) {
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        timeRangeLabel.text = "\(tf.string(from: session.start)) – \(tf.string(from: session.end))"

        let dur = session.duration
        let h = Int(dur / 3600); let m = Int((dur.truncatingRemainder(dividingBy: 3600)) / 60)
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

    @objc private func menuTapped() { onDelete?() }
}

// MARK: - SleepCalendarCell

final class SleepCalendarCell: UICollectionViewCell {
    static let reuseId = "SleepCalendarCell"

    var onDaySelected: ((Date) -> Void)?
    var onToggleExpand: (() -> Void)?

    private(set) var isExpanded = false
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()

    private let accent = UIColor(hexString: "#8b6dc4")

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
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        return b
    }()
    private lazy var nextBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        return b
    }()
    private var dayButtons: [UIButton] = []

    private lazy var expandChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        return b
    }()
    private lazy var collapseChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        return b
    }()

    private let mainStack: UIStackView = {
        let s = UIStackView(); s.axis = .vertical; return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

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
    }

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
        let df = DateFormatter(); df.dateFormat = "MMMM yyyy"
        monthYearLabel.text = df.string(from: displayedMonth)

        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        let weekday = cal.component(.weekday, from: firstDay)
        let offset = (weekday + 5) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)!.count

        for (i, btn) in dayButtons.enumerated() {
            let dayNum = i - offset + 1
            if dayNum < 1 || dayNum > daysInMonth {
                btn.setTitle("", for: .normal); btn.isEnabled = false; btn.backgroundColor = .clear
            } else {
                btn.setTitle("\(dayNum)", for: .normal); btn.isEnabled = true
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
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev; reloadMonthGrid()
    }

    @objc private func nextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next; reloadMonthGrid()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
        attrs.frame.size.height = isExpanded ? 310 * Constraint.yCoeff : 90 * Constraint.yCoeff
        return attrs
    }
}

// MARK: - SleepSectionHeader

final class SleepSectionHeader: UICollectionReusableView {
    static let reuseId = "SleepSectionHeader"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) { titleLabel.text = title }
}

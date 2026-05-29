import UIKit
import SnapKit
import ActivityKit
import UserNotifications

// MARK: - Helpers

private extension Double {
    /// Returns nil if the value is zero (used for UserDefaults "not set" detection).
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - SleepViewController

final class SleepViewController: UIViewController {

    // MARK: - Section / Item

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case dateNav, ringStats, timeline, todayLog
    }

    private nonisolated enum Item: Hashable, Sendable {
        case dateNav, ringStats, timeline
        case empty
        case session(UUID)
    }

    // MARK: - State

    private var sessions: [SleepSession] = []
    private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    private var activeStartDate: Date?
    private var liveTimer: Timer?

    /// UserDefaults key that persists the sleep-start timestamp across background/kill
    private let sleepStartKey         = "activeSleepStartTimestamp"
    private let sleepPausedSecondsKey = "sleepTotalPausedSeconds"
    private let sleepPausedAtKey      = "sleepPausedAtTimestamp"

    /// Pause state
    private var isPaused:            Bool              = false
    private var pauseStartDate:      Date?             = nil
    private var totalPausedSeconds:  TimeInterval      = 0

    /// Running Live Activity shown on the lock screen / Dynamic Island
    private var currentLiveActivity: Activity<SleepTimerAttributes>?

    private var sleepGoalHours: Double {
        get { UserDefaults.standard.double(forKey: "sleepGoalHours").nonZero ?? 14 }
        set { UserDefaults.standard.set(newValue, forKey: "sleepGoalHours") }
    }

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

    private lazy var pauseResumeButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        b.setImage(UIImage(systemName: "pause.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.backgroundColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.12)
        b.layer.cornerRadius = 20 * Constraint.yCoeff
        b.addTarget(self, action: #selector(pauseResumeTapped), for: .touchUpInside)
        return b
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
        v.addSubview(self.pauseResumeButton)

        moonCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        self.pauseResumeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        sleepingLabel.snp.makeConstraints {
            $0.leading.equalTo(moonCircle.snp.trailing).offset(14 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(self.pauseResumeButton.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        self.elapsedLabel.snp.makeConstraints {
            $0.leading.equalTo(sleepingLabel)
            $0.trailing.lessThanOrEqualTo(self.pauseResumeButton.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.top.equalTo(sleepingLabel.snp.bottom).offset(2 * Constraint.yCoeff)
        }
        self.startedAtLabel.snp.makeConstraints {
            $0.leading.equalTo(sleepingLabel)
            $0.trailing.lessThanOrEqualTo(self.pauseResumeButton.snp.leading).offset(-8 * Constraint.xCoeff)
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
        cv.register(BabyEmptyLogCell.self, forCellWithReuseIdentifier: BabyEmptyLogCell.reuseId)
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
        b.titleLabel?.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hexString: "#a98fd4")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
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
        restoreActiveSessionIfNeeded()

        // Re-sync the UI the instant the user returns to the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        // Update notification when going to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        // Lock-screen notification action callbacks (posted by AppDelegate)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSleepTimerShouldPause),
            name: .sleepTimerShouldPause,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSleepTimerShouldResume),
            name: .sleepTimerShouldResume,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSleepTimerShouldStop),
            name: .sleepTimerShouldStop,
            object: nil
        )
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
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8 * Constraint.yCoeff)
            $0.height.equalTo(56 * Constraint.yCoeff)
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
                cell.configure(sessions: daySessions, goalHours: self.sleepGoalHours, isLive: self.activeStartDate != nil, liveStart: self.activeStartDate)
                cell.onGoalTap = { [weak self] in self?.presentGoalPicker() }
                return cell

            case .timeline:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: SleepTimelineCell.reuseId, for: indexPath) as! SleepTimelineCell
                cell.configure(
                    sessions:    self.sessionsForSelectedDate(),
                    date:        self.selectedDate,
                    activeStart: self.activeStartDate
                )
                return cell

            case .empty:
                return cv.dequeueReusableCell(withReuseIdentifier: BabyEmptyLogCell.reuseId, for: indexPath)

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
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80 * Constraint.yCoeff)))
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
        if daySessions.isEmpty {
            snap.appendItems([.empty], toSection: .todayLog)
        } else {
            snap.appendItems(daySessions.map { Item.session($0.id) }, toSection: .todayLog)
        }
        snap.reloadSections([.ringStats, .timeline, .todayLog])
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
            // ── Start sleep ──────────────────────────────────────────────
            let now = Date()
            activeStartDate = now
            selectedDate = Calendar.current.startOfDay(for: now)

            // Persist so the timer survives backgrounding / kill
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: sleepStartKey)

            let tf = DateFormatter(); tf.dateFormat = "h:mm a"
            startedAtLabel.text = "Started at \(tf.string(from: now))"
            elapsedLabel.text = "0:00:00"

            startPeriodicTimer()
            startSleepLiveActivity(from: now)
            registerSleepNotificationCategories() // register categories early; banner posts on background

            UIView.animate(withDuration: 0.35) { self.liveTimerCard.alpha = 1 }
            collectionView.contentInset.bottom = 210 * Constraint.yCoeff

        } else {
            // ── Stop sleep ───────────────────────────────────────────────
            guard let start = activeStartDate else { return }
            liveTimer?.invalidate(); liveTimer = nil

            // Compute effective duration (subtracts all paused time)
            let effectiveDuration = currentElapsed()
            let end = start.addingTimeInterval(effectiveDuration)

            // Clear persistence
            UserDefaults.standard.removeObject(forKey: sleepStartKey)
            UserDefaults.standard.removeObject(forKey: sleepPausedSecondsKey)
            UserDefaults.standard.removeObject(forKey: sleepPausedAtKey)

            // Reset pause state
            isPaused = false; pauseStartDate = nil; totalPausedSeconds = 0

            let session = SleepSession(start: start, end: end)
            sessions.insert(session, at: 0)
            SleepSessionStore.save(sessions)
            activeStartDate = nil
            selectedDate = Calendar.current.startOfDay(for: start)

            // Reset pause button icon for next session
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            pauseResumeButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: cfg), for: .normal)

            stopSleepLiveActivity()
            clearSleepNotification()

            UIView.animate(withDuration: 0.25) { self.liveTimerCard.alpha = 0 }
            collectionView.contentInset.bottom = 120 * Constraint.yCoeff
        }
        updateStartButton()
        applySnapshot()
    }

    @objc private func logPastTapped() {
        let vc = LogPastSleepViewController()
        vc.onSave = { [weak self] session in
            guard let self else { return }
            self.sessions.append(session)
            self.sessions.sort { $0.start > $1.start }
            SleepSessionStore.save(self.sessions)
            self.applySnapshot()
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
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

    private func presentGoalPicker() {
        let current = Int(sleepGoalHours)
        let alert = UIAlertController(title: "Sleep Goal", message: "Set the daily sleep goal in hours.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.text = "\(current)"
            tf.placeholder = "Hours (e.g. 14)"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text,
                  let hours = Double(text), hours > 0, hours <= 24 else { return }
            self.sleepGoalHours = hours
            self.applySnapshot()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    /// Returns elapsed wall-clock seconds minus all paused time (real effective sleep duration).
    private func currentElapsed() -> TimeInterval {
        guard let start = activeStartDate else { return 0 }
        var paused = totalPausedSeconds
        if isPaused, let pausedAt = pauseStartDate {
            paused += Date().timeIntervalSince(pausedAt)
        }
        return max(0, Date().timeIntervalSince(start) - paused)
    }

    private func refreshLiveUI() {
        guard activeStartDate != nil else { return }
        let elapsed = currentElapsed()
        let h = Int(elapsed / 3600)
        let m = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        let s = Int(elapsed.truncatingRemainder(dividingBy: 60))
        elapsedLabel.text = String(format: "%d:%02d:%02d", h, m, s)
        var snap = dataSource.snapshot()
        var toReconfigure: [Item] = []
        if snap.itemIdentifiers(inSection: .ringStats).contains(.ringStats)   { toReconfigure.append(.ringStats) }
        if snap.itemIdentifiers(inSection: .timeline).contains(.timeline)     { toReconfigure.append(.timeline) }
        if !toReconfigure.isEmpty {
            snap.reconfigureItems(toReconfigure)
            dataSource.apply(snap, animatingDifferences: false)
        }
    }

    // MARK: - Background / Foreground handling

    /// Called every time the user brings the app back to the foreground.
    @objc private func appWillEnterForeground() {
        guard activeStartDate != nil else { return }
        // Hide the lock-screen notification — the in-app card is now visible instead
        clearSleepNotification()
        // Immediately sync elapsed label — the periodic timer takes over after the next tick
        refreshLiveUI()
    }

    /// Posts the lock-screen notification the moment the app moves to the background
    /// (screen lock / home button). At this point iOS delivers it to the lock screen directly,
    /// bypassing the willPresent foreground-intercept path.
    @objc private func appDidEnterBackground() {
        guard activeStartDate != nil else { return }
        postSleepNotificationNow()
    }

    // MARK: - Pause / Resume

    /// Tapping the in-card pause/resume button.
    @objc private func pauseResumeTapped() {
        if isPaused { resumeTimer() } else { pauseTimer() }
    }

    /// Triggered by AppDelegate when the "Pause" lock-screen action fires.
    @objc private func handleSleepTimerShouldPause() {
        guard !isPaused else { return }
        DispatchQueue.main.async { self.pauseTimer() }
    }

    /// Triggered by AppDelegate when the "Resume" lock-screen action fires.
    @objc private func handleSleepTimerShouldResume() {
        guard isPaused else { return }
        DispatchQueue.main.async { self.resumeTimer() }
    }

    /// Triggered by AppDelegate when the "Stop" lock-screen action fires.
    @objc private func handleSleepTimerShouldStop() {
        guard activeStartDate != nil else { return }
        // The handler in AppDelegate also calls stopAndSaveIfNeeded() as a direct fallback,
        // so guard against a double-save by checking activeStartDate first.
        DispatchQueue.main.async { self.startButtonTapped() }
    }

    private func pauseTimer() {
        guard !isPaused, activeStartDate != nil else { return }
        isPaused = true
        pauseStartDate = Date()
        liveTimer?.invalidate(); liveTimer = nil

        // Persist the moment we paused so stopAndSaveIfNeeded() can compute correct duration
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: sleepPausedAtKey)

        // Swap button icon → play (resume)
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        pauseResumeButton.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)

        // Only update the lock-screen notification if the app is already backgrounded
        // (i.e. the action came from the lock screen, not an in-app tap)
        if UIApplication.shared.applicationState != .active {
            postSleepNotificationNow()
        }
    }

    private func resumeTimer() {
        guard isPaused, activeStartDate != nil else { return }

        // Accumulate the pause window that just ended
        if let pausedAt = pauseStartDate {
            totalPausedSeconds += Date().timeIntervalSince(pausedAt)
        }
        isPaused = false
        pauseStartDate = nil

        // Persist new accumulated total; clear the "paused at" timestamp
        UserDefaults.standard.set(totalPausedSeconds, forKey: sleepPausedSecondsKey)
        UserDefaults.standard.removeObject(forKey: sleepPausedAtKey)

        // Swap button icon → pause
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        pauseResumeButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: cfg), for: .normal)

        startPeriodicTimer()
        refreshLiveUI()

        // Only update the lock-screen notification if the app is already backgrounded
        if UIApplication.shared.applicationState != .active {
            postSleepNotificationNow()
        }
    }

    /// Restores an in-progress sleep session after the app was killed or backgrounded.
    private func restoreActiveSessionIfNeeded() {
        let ts = UserDefaults.standard.double(forKey: sleepStartKey)
        guard ts > 0 else { return }

        let start = Date(timeIntervalSince1970: ts)
        activeStartDate = start

        // Restore accumulated paused seconds
        totalPausedSeconds = UserDefaults.standard.double(forKey: sleepPausedSecondsKey)

        // Restore paused state if we were paused when the app was killed
        let pausedAtTs = UserDefaults.standard.double(forKey: sleepPausedAtKey)
        if pausedAtTs > 0 {
            isPaused = true
            pauseStartDate = Date(timeIntervalSince1970: pausedAtTs)
            // Show resume icon
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            pauseResumeButton.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
        }

        let tf = DateFormatter(); tf.dateFormat = "h:mm a"
        startedAtLabel.text = "Started at \(tf.string(from: start))"

        if !isPaused { startPeriodicTimer() }
        refreshLiveUI()
        registerSleepNotificationCategories() // categories ready; banner posts next time user backgrounds

        liveTimerCard.alpha = 1
        collectionView.contentInset.bottom = 210 * Constraint.yCoeff
        updateStartButton()
        applySnapshot()
    }

    /// Starts the 1-second UI-update timer.
    private func startPeriodicTimer() {
        liveTimer?.invalidate()
        liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshLiveUI()
        }
        RunLoop.main.add(liveTimer!, forMode: .common)
    }

    // MARK: - Live Activity (lock screen / Dynamic Island)

    private func startSleepLiveActivity(from start: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let babyName = BabyProfileStore.loadName() ?? "Baby"
        let attributes = SleepTimerAttributes(sessionID: UUID().uuidString)
        let state = SleepTimerAttributes.ContentState(startTime: start, babyName: babyName)
        do {
            currentLiveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Live Activity could not be started: \(error.localizedDescription)")
        }
    }

    private func stopSleepLiveActivity() {
        Task {
            // End all sleep activities (covers the case of a crash-restart re-launch)
            for activity in Activity<SleepTimerAttributes>.activities {
                await activity.end(.init(state: activity.content.state, staleDate: nil),
                                   dismissalPolicy: .immediate)
            }
            currentLiveActivity = nil
        }
    }

    // MARK: - Lock-screen notification

    private let sleepNotificationID = "sleepInProgressNotification"

    /// Requests permission and registers Pause/Resume/Stop categories.
    /// Call this when the sleep timer starts so the categories are ready
    /// before the first notification fires.
    private func registerSleepNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge]) { granted, _ in
            guard granted else { return }
            let pause  = UNNotificationAction(identifier: "PAUSE_SLEEP",  title: "Pause",      options: [])
            let resume = UNNotificationAction(identifier: "RESUME_SLEEP", title: "Resume",     options: [])
            let stop   = UNNotificationAction(identifier: "STOP_SLEEP",   title: "Stop Sleep", options: [.foreground])
            let running = UNNotificationCategory(identifier: "SLEEP_RUNNING",
                                                 actions: [pause, stop],
                                                 intentIdentifiers: [], options: [])
            let paused  = UNNotificationCategory(identifier: "SLEEP_PAUSED",
                                                 actions: [resume, stop],
                                                 intentIdentifiers: [], options: [])
            center.setNotificationCategories([running, paused])
        }
    }

    /// Posts (or replaces) the lock-screen notification.
    /// MUST be called only while the app is in the background — notifications
    /// delivered in the background go directly to the lock screen without
    /// going through the willPresent foreground-intercept path.
    private func postSleepNotificationNow() {
        guard let start = activeStartDate else { return }
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            // Remove any previous banner before posting a fresh one
            center.removeDeliveredNotifications(withIdentifiers: [self.sleepNotificationID])
            center.removePendingNotificationRequests(withIdentifiers: [self.sleepNotificationID])

            let content  = UNMutableNotificationContent()
            let babyName = BabyProfileStore.loadName() ?? "Baby"
            let elapsed  = self.currentElapsed()
            let h = Int(elapsed / 3600)
            let m = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
            let elapsedStr = h > 0 ? "\(h)h \(m)m" : "\(m)m"

            if self.isPaused {
                content.title = "\(babyName)'s sleep is paused ⏸"
                content.body  = "\(elapsedStr) elapsed · tap Resume to continue"
                content.categoryIdentifier = "SLEEP_PAUSED"
            } else {
                let tf = DateFormatter(); tf.dateFormat = "h:mm a"
                content.title = "\(babyName) is sleeping 🌙"
                content.body  = "Started \(tf.string(from: start)) · \(elapsedStr) elapsed"
                content.categoryIdentifier = "SLEEP_RUNNING"
            }
            content.sound = nil
            content.interruptionLevel = .active

            // 0.5 s delay guarantees the app is fully backgrounded before delivery
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(
                identifier: self.sleepNotificationID,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func clearSleepNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [sleepNotificationID])
        center.removeDeliveredNotifications(withIdentifiers: [sleepNotificationID])
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarInitialLabel)
        addSubview(nameLabel)
        addSubview(ageLabel)

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

    var onGoalTap: (() -> Void)?

    private let ringView = SleepRingView()

    private let totalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .center
        return l
    }()

    private lazy var goalButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        b.setTitleColor(UIColor(hexString: "#999999"), for: .normal)
        b.addTarget(self, action: #selector(goalTapped), for: .touchUpInside)
        return b
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(goalTapped))
        contentView.addGestureRecognizer(tap)

        contentView.addSubview(ringView)
        contentView.addSubview(totalLabel)
        contentView.addSubview(goalButton)
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
        goalButton.snp.makeConstraints {
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
        goalButton.setTitle("/\(Int(goalHours))h goal", for: .normal)

        let progress = min(totalSeconds / (goalHours * 3600), 1.0)
        ringView.setProgress(CGFloat(progress))

        let naps = sessions.filter { isNap($0) }.count
        napsValue.text = "\(naps)"

        let longest = sessions.max(by: { $0.duration < $1.duration })?.duration ?? 0
        let lH = Int(longest / 3600); let lM = Int((longest.truncatingRemainder(dividingBy: 3600)) / 60)
        stretchValue.text = lH > 0 ? "\(lH)h \(lM)m" : "\(lM)m"
        if sessions.isEmpty { stretchValue.text = "—"; napsValue.text = "0" }
    }

    @objc private func goalTapped() { onGoalTap?() }

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

// MARK: - SleepTrackView
// A self-contained view that owns its segment data and positions them in its own layoutSubviews.
// This avoids the timing problem where the parent cell's layoutSubviews fires before the
// track view has received real bounds from auto layout.

private final class SleepTrackView: UIView {

    struct Segment {
        let startFraction: CGFloat   // 0…1 fraction of the 24-h day
        let endFraction:   CGFloat
        let color:         UIColor
        let isLive:        Bool      // currently running → pulsing alpha
    }

    private var segments: [Segment] = []
    private var segViews: [UIView]  = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hexString: "#f5f0ff")
        layer.cornerRadius = 16 * Constraint.yCoeff
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func setSegments(_ segments: [Segment]) {
        segViews.forEach { $0.removeFromSuperview() }
        segViews = []
        self.segments = segments

        for seg in segments {
            let v = UIView()
            v.backgroundColor = seg.color
            v.clipsToBounds = true
            addSubview(v)
            segViews.append(v)

            if seg.isLive {
                // Gentle pulse to show it's live
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 1.0
                pulse.toValue   = 0.55
                pulse.duration  = 1.1
                pulse.autoreverses = true
                pulse.repeatCount  = .infinity
                v.layer.add(pulse, forKey: "livePulse")
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let trackW = bounds.width
        guard trackW > 0, segments.count == segViews.count else { return }

        let segH = bounds.height - 8 * Constraint.yCoeff
        let segY = 4 * Constraint.yCoeff
        let radius = segH / 2
        let minW   = segH   // minimum width = height so it's always at least a circle

        for (i, view) in segViews.enumerated() {
            let seg  = segments[i]
            let x    = seg.startFraction * trackW
            let rawW = (seg.endFraction - seg.startFraction) * trackW
            let w    = max(rawW, minW)
            view.frame = CGRect(x: x, y: segY, width: w, height: segH)
            view.layer.cornerRadius = radius
        }
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

    private let trackView = SleepTrackView()

    private static func makeTimeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#aaaaaa")
        return l
    }

    private let amLabel   = makeTimeLabel("12am")
    private let noonLabel = makeTimeLabel("12pm")
    private let pmLabel   = makeTimeLabel("11:59pm")

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(trackView)
        contentView.addSubview(amLabel)
        contentView.addSubview(noonLabel)
        contentView.addSubview(pmLabel)

        titleLabel.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        trackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(42 * Constraint.yCoeff)
        }
        amLabel.snp.makeConstraints {
            $0.top.equalTo(trackView.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.equalToSuperview()
        }
        noonLabel.snp.makeConstraints {
            $0.top.equalTo(amLabel); $0.centerX.equalToSuperview()
        }
        pmLabel.snp.makeConstraints {
            $0.top.equalTo(amLabel); $0.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Configure

    /// - Parameters:
    ///   - sessions:    All sessions for the selected day.
    ///   - date:        The day being displayed.
    ///   - activeStart: Start of a currently-running session (nil if none).
    func configure(sessions: [SleepSession], date: Date, activeStart: Date? = nil) {
        let cal      = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd   = dayStart.addingTimeInterval(86400)

        var built: [SleepTrackView.Segment] = []

        for session in sessions {
            let cs = max(session.start, dayStart)
            let ce = min(session.end,   dayEnd)
            guard ce > cs else { continue }

            let sf = CGFloat(cs.timeIntervalSince(dayStart) / 86400)
            let ef = CGFloat(ce.timeIntervalSince(dayStart) / 86400)
            built.append(.init(
                startFraction: sf,
                endFraction:   ef,
                color:         segmentColor(for: session.start),
                isLive:        false
            ))
        }

        // Add the currently-running session as a live (pulsing) segment
        if let activeStart, cal.isDate(activeStart, inSameDayAs: date) {
            let cs  = max(activeStart, dayStart)
            let now = min(Date(), dayEnd)
            if now > cs {
                let sf = CGFloat(cs.timeIntervalSince(dayStart)  / 86400)
                let ef = CGFloat(now.timeIntervalSince(dayStart) / 86400)
                built.append(.init(
                    startFraction: sf,
                    endFraction:   ef,
                    color:         UIColor(hexString: "#8b6dc4"),
                    isLive:        true
                ))
            }
        }

        trackView.setSegments(built)
    }

    // MARK: - Helpers

    private func segmentColor(for date: Date) -> UIColor {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 19 || hour < 6 {
            return UIColor(hexString: "#8b6dc4")                         // Night — purple
        } else if hour < 12 {
            return UIColor(hexString: "#f4a261").withAlphaComponent(0.85) // Morning nap — orange
        } else {
            return UIColor(hexString: "#f0b7a5")                         // Afternoon nap — peach
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
        slideCalendar(expandedView, toRight: true)
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = prev; reloadMonthGrid()
    }

    @objc private func nextMonth() {
        slideCalendar(expandedView, toRight: false)
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = next; reloadMonthGrid()
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

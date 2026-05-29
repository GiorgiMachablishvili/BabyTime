import UIKit
import SnapKit
import UserNotifications
import ActivityKit

// MARK: - FeedingViewController

final class FeedingViewController: UIViewController {

    // MARK: - Section / Item

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case weekCalendar, lastFeed, breastTimer, quickActions, todayLog
    }

    private nonisolated enum Item: Hashable, Sendable {
        case weekCalendar, lastFeed, breastTimer, quickActions
        case empty
        case log(UUID)
    }

    // MARK: - State

    private var logEntries: [FeedingLogEntry] = []
    private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    private var expandedLogIDs: Set<UUID> = []

    // MARK: Breast timer notification state

    private var breastTimerStart: Date?
    private var breastTimerSide  = "L"
    private let breastNotifID    = "breastFeedingTimerNotification"
    private let breastStartKey   = "activeBreastTimerStartTimestamp"
    private let breastSideKey    = "activeBreastTimerSide"

    // MARK: Breast timer Live Activity
    // Stored as Any to avoid @available stored-property restriction; cast inside helpers.
    private var _currentBreastActivity: Any? = nil

    // MARK: - Views

    private let headerView = FeedingHeaderView()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80 * Constraint.yCoeff, right: 0)
        cv.alwaysBounceVertical = true
        cv.register(BabyEmptyLogCell.self, forCellWithReuseIdentifier: BabyEmptyLogCell.reuseId)
        cv.register(FeedingWeekCalendarCell.self, forCellWithReuseIdentifier: FeedingWeekCalendarCell.reuseId)
        cv.register(FeedingLastFeedCell.self, forCellWithReuseIdentifier: FeedingLastFeedCell.reuseId)
        cv.register(FeedingBreastTimerCell.self, forCellWithReuseIdentifier: FeedingBreastTimerCell.reuseId)
        cv.register(FeedingQuickActionsCell.self, forCellWithReuseIdentifier: FeedingQuickActionsCell.reuseId)
        cv.register(FeedingViewCell.self, forCellWithReuseIdentifier: FeedingViewCell.reuseId)
        cv.register(
            FeedingSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: FeedingSectionHeaderView.reuseId
        )
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private let statsBar = FeedingStatsBarView()



    // feedingView kept for non-breast types (bottle/formula/solid)
    private lazy var feedingView: FeedingView = {
        let v = FeedingView()
        v.isHidden = true
        v.onTapCloseButton = { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.feedingView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.feedingView.isHidden = true
            }
        }
        v.onTapSave = { [weak self] type, volume, notes, time, date in
            self?.saveEntry(type: type, volume: volume, notes: notes, time: time, date: date)
        }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupDataSource()
        loadData()

        // Background / foreground handling for breast timer notification
        NotificationCenter.default.addObserver(
            self, selector: #selector(breastAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(breastAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleBreastTimerShouldStop),
            name: .breastTimerShouldStop, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(collectionView)
        view.addSubview(statsBar)
        view.addSubview(feedingView)

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(110 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(statsBar.snp.top)
        }
        statsBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.height.equalTo(70 * Constraint.yCoeff)
        }
        feedingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .weekCalendar:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: FeedingWeekCalendarCell.reuseId, for: indexPath) as! FeedingWeekCalendarCell
                cell.configure(selected: self.selectedDate)
                cell.onDaySelected = { [weak self] date in
                    self?.selectedDate = date
                    self?.applySnapshot()
                    self?.updateStats()
                }
                cell.onToggleExpand = { [weak self] in
                    guard let self else { return }
                    UIView.animate(withDuration: 0.3) {
                        self.collectionView.performBatchUpdates(nil)
                    }
                }
                return cell

            case .lastFeed:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: FeedingLastFeedCell.reuseId, for: indexPath) as! FeedingLastFeedCell
                cell.configure(lastEntry: self.logEntries.first)
                return cell

            case .breastTimer:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: FeedingBreastTimerCell.reuseId, for: indexPath) as! FeedingBreastTimerCell
                cell.onStart = { [weak self] start, side in
                    guard let self else { return }
                    self.breastTimerStart = start
                    self.breastTimerSide  = side
                    UserDefaults.standard.set(start.timeIntervalSince1970, forKey: self.breastStartKey)
                    UserDefaults.standard.set(side, forKey: self.breastSideKey)
                    self.registerBreastNotificationCategories()
                    self.startBreastLiveActivity(start: start, side: side)
                }
                cell.onSave = { [weak self] elapsed, side in
                    guard let self else { return }
                    // Clear notification state first so the handler won't double-save
                    self.breastTimerStart = nil
                    UserDefaults.standard.removeObject(forKey: self.breastStartKey)
                    UserDefaults.standard.removeObject(forKey: self.breastSideKey)
                    self.clearBreastNotification()
                    self.stopBreastLiveActivity()
                    // Persist the feeding entry
                    let totalMin = Int(elapsed / 60)
                    let totalSec = Int(elapsed.truncatingRemainder(dividingBy: 60))
                    let value = totalMin > 0 ? "\(totalMin) min \(totalSec) sec" : "\(totalSec) sec"
                    let tf = DateFormatter(); tf.dateFormat = "h:mm a"
                    let df = DateFormatter(); df.dateFormat = "MMM d"
                    let now = Date()
                    self.saveEntry(type: .breast, volume: value, notes: "Side: \(side)", time: tf.string(from: now), date: df.string(from: now))
                }
                return cell

            case .quickActions:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: FeedingQuickActionsCell.reuseId, for: indexPath) as! FeedingQuickActionsCell
                cell.onQuickLog = { [weak self] type in
                    self?.quickLog(type: type)
                }
                return cell

            case .empty:
                return cv.dequeueReusableCell(withReuseIdentifier: BabyEmptyLogCell.reuseId, for: indexPath)

            case .log(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: FeedingViewCell.reuseId, for: indexPath) as! FeedingViewCell
                if let entry = self.logEntries.first(where: { $0.id == id }) {
                    cell.configure(entry: entry, isExpanded: self.expandedLogIDs.contains(id))
                    cell.onMenuTap = { [weak self] in self?.confirmDelete(id: id) }
                    cell.onTap = { [weak self] in
                        guard let self else { return }
                        if self.expandedLogIDs.contains(id) {
                            self.expandedLogIDs.remove(id)
                        } else {
                            self.expandedLogIDs.insert(id)
                        }
                        if #available(iOS 15.0, *) {
                            var snap = self.dataSource.snapshot()
                            snap.reconfigureItems([.log(id)])
                            self.dataSource.apply(snap, animatingDifferences: true)
                        } else {
                            self.applySnapshot()
                        }
                    }
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader, let self else { return nil }
            let header = cv.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: FeedingSectionHeaderView.reuseId,
                for: indexPath
            ) as! FeedingSectionHeaderView
            if indexPath.section == Section.todayLog.rawValue {
                let title = Calendar.current.isDateInToday(self.selectedDate)
                    ? "Today"
                    : self.formatDate(self.selectedDate)
                header.configureTodayHeader(title: title)
                header.onTapViewAll = { [weak self] in
                    self?.openFeedingHistory()
                }
            } else {
                header.configureSimple(title: "")
            }
            return header
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .weekCalendar:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .lastFeed:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(90 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .breastTimer:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(170 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(170 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .quickActions:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(200 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
                return sec

            case .todayLog:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80 * Constraint.yCoeff)))
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300 * Constraint.yCoeff)),
                    subitems: [item]
                )
                let sec = NSCollectionLayoutSection(group: group)
                sec.interGroupSpacing = 8 * Constraint.yCoeff
                sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16)
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(40 * Constraint.yCoeff)
                )
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

    // MARK: - Data

    private func loadData() {
        logEntries = FeedingLogStore.loadEntries()
            .sorted { ($0.savedAtEpochSeconds ?? 0) > ($1.savedAtEpochSeconds ?? 0) }

        let name = BabyProfileStore.loadName() ?? "Baby"
        headerView.configure(name: name, birthday: BabyProfileStore.loadBirthday(), photo: BabyProfileStore.loadPhoto())
        headerView.onCalendarTap = { [weak self] in self?.presentDatePicker() }

        applySnapshot()
        updateStats()
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections(Section.allCases)
        snap.appendItems([Item.weekCalendar], toSection: .weekCalendar)
        snap.appendItems([Item.lastFeed], toSection: .lastFeed)
        snap.appendItems([Item.breastTimer], toSection: .breastTimer)
        snap.appendItems([Item.quickActions], toSection: .quickActions)

        let cal = Calendar.current
        let filtered = logEntries.filter {
            cal.isDate(Date(timeIntervalSince1970: $0.savedAtEpochSeconds ?? 0), inSameDayAs: selectedDate)
        }
        if filtered.isEmpty {
            snap.appendItems([.empty], toSection: .todayLog)
        } else {
            snap.appendItems(filtered.map { Item.log($0.id) }, toSection: .todayLog)
        }
        snap.reloadSections([.todayLog])
        dataSource.apply(snap, animatingDifferences: true)

        // lastFeed has a stable identifier so the diffable source won't re-call
        // the cell provider automatically — force a reconfigure to show the latest entry
        var reconfigSnap = dataSource.snapshot()
        reconfigSnap.reconfigureItems([.lastFeed])
        dataSource.apply(reconfigSnap, animatingDifferences: false)
    }

    private func updateStats() {
        let cal = Calendar.current
        let filtered = logEntries.filter {
            cal.isDate(Date(timeIntervalSince1970: $0.savedAtEpochSeconds ?? 0), inSameDayAs: selectedDate)
        }
        var totalML = 0
        for e in filtered {
            if let vol = e.volumeText {
                let digits = vol.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                totalML += Int(digits) ?? 0
            }
        }
        var avgInterval: Double? = nil
        if filtered.count >= 2 {
            let times = filtered.compactMap { $0.savedAtEpochSeconds }.sorted()
            let intervals = zip(times, times.dropFirst()).map { $1 - $0 }
            avgInterval = (intervals.reduce(0, +) / Double(intervals.count)) / 3600.0
        }
        statsBar.configure(totalML: totalML, feedCount: filtered.count, avgIntervalHours: avgInterval)
    }

    // MARK: - Actions

    private func quickLog(type: FeedingTypeView.FeedingType) {
        let vc = FeedingSessionViewController()
        vc.feedingType = type
        vc.modalPresentationStyle = .fullScreen
        vc.onSave = { [weak self] value, notes in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let time = formatter.string(from: Date())
            formatter.dateFormat = "MMM d"
            let date = formatter.string(from: Date())
            self.saveEntry(type: type, volume: value, notes: notes, time: time, date: date)
        }
        present(vc, animated: true)
    }

    private func saveEntry(type: FeedingTypeView.FeedingType, volume: String?, notes: String?, time: String, date: String) {
        let vmType: FeedingViewCell.ViewModel.FeedingType
        switch type {
        case .breast: vmType = .breast
        case .bottle: vmType = .bottle
        case .formula: vmType = .formula
        case .solid: vmType = .solid
        }
        FeedingLogStore.add(FeedingViewCell.ViewModel(type: vmType, volumeText: volume, notesText: notes, timeText: time, dateText: date))
        loadData()
    }

    private func confirmDelete(id: UUID) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteEntry(id: id)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteEntry(id: UUID) {
        var entries = FeedingLogStore.loadEntries()
        entries.removeAll { $0.id == id }
        FeedingLogStore.saveEntries(entries)
        loadData()
    }

    private func presentDatePicker() {
        let vc = FeedingDatePickerViewController(date: selectedDate)
        vc.onDateSelected = { [weak self] date in
            self?.selectedDate = Calendar.current.startOfDay(for: date)
            self?.applySnapshot()
            self?.updateStats()
        }
        let nav = UINavigationController(rootViewController: vc)
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(nav, animated: true)
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: date)
    }

    private func openFeedingHistory() {
        let vc = FeedingHistoryViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Breast timer lock-screen notification

    /// Posts lock-screen notification when app enters background with timer running.
    @objc private func breastAppDidEnterBackground() {
        guard breastTimerStart != nil else { return }
        postBreastNotificationNow()
    }

    /// Removes the lock-screen notification when the app returns to foreground.
    @objc private func breastAppWillEnterForeground() {
        clearBreastNotification()
    }

    /// Handles the "Stop & Save" action from the lock screen.
    @objc private func handleBreastTimerShouldStop() {
        guard breastTimerStart != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // stopAndSave() → fires onSave → calls stopBreastLiveActivity()
            let ip = IndexPath(item: 0, section: Section.breastTimer.rawValue)
            (self.collectionView.cellForItem(at: ip) as? FeedingBreastTimerCell)?.stopAndSave()
            // If cell is off-screen, onSave won't fire — end activity directly
            self.stopBreastLiveActivity()
        }
    }

    /// Registers the "Stop & Save" action category.
    private func registerBreastNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge]) { granted, _ in
            guard granted else { return }
            let stop = UNNotificationAction(identifier: "STOP_BREAST",
                                            title: "Stop & Save",
                                            options: [.foreground])
            let cat = UNNotificationCategory(identifier: "BREAST_RUNNING",
                                             actions: [stop],
                                             intentIdentifiers: [], options: [])
            center.setNotificationCategories([cat])
        }
    }

    /// Posts the breast-timer notification. Call only while backgrounded.
    private func postBreastNotificationNow() {
        guard let start = breastTimerStart else { return }
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            center.removeDeliveredNotifications(withIdentifiers: [self.breastNotifID])
            center.removePendingNotificationRequests(withIdentifiers: [self.breastNotifID])

            let elapsed  = max(0, Date().timeIntervalSince(start))
            let m = Int(elapsed / 60)
            let s = Int(elapsed.truncatingRemainder(dividingBy: 60))
            let elapsedStr = m > 0 ? "\(m)m \(s)s" : "\(s)s"

            let content  = UNMutableNotificationContent()
            let babyName = BabyProfileStore.loadName() ?? "Baby"
            content.title = "🤱 \(babyName) is breastfeeding"
            content.body  = "Side \(self.breastTimerSide) · \(elapsedStr) elapsed"
            content.categoryIdentifier = "BREAST_RUNNING"
            content.sound = nil
            content.interruptionLevel = .active

            // Small delay so app is fully backgrounded before delivery
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request  = UNNotificationRequest(identifier: self.breastNotifID,
                                                  content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func clearBreastNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [breastNotifID])
        center.removeDeliveredNotifications(withIdentifiers: [breastNotifID])
    }

    // MARK: - Live Activity helpers

    private func startBreastLiveActivity(start: Date, side: String) {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let babyName = BabyProfileStore.loadName() ?? "Baby"
        let state = BreastTimerAttributes.ContentState(startTime: start,
                                                       side: side,
                                                       babyName: babyName)
        let attrs = BreastTimerAttributes(sessionID: UUID().uuidString)

        do {
            let activity = try Activity<BreastTimerAttributes>.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            _currentBreastActivity = activity
        } catch {
            // Live Activities not available or already running — fall back to notification-only
            print("[BreastTimer] Live Activity request failed: \(error)")
        }
    }

    private func stopBreastLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        guard let activity = _currentBreastActivity as? Activity<BreastTimerAttributes> else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        _currentBreastActivity = nil
    }
}

// MARK: - FeedingHeaderView

final class FeedingHeaderView: UIView {

    var onCalendarTap: (() -> Void)?

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0b7a5").withAlphaComponent(0.3)
        v.layer.cornerRadius = 22 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let avatarInitialLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#c0684a")
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

    private lazy var calendarButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "calendar"), for: .normal)
        b.tintColor = UIColor(hexString: "#9b7fd4")
        b.addTarget(self, action: #selector(calTapped), for: .touchUpInside)
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
        addSubview(calendarButton)

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
        calendarButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.centerY.equalTo(avatarView)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, birthday: Date?, photo: UIImage?) {
        nameLabel.text = "\(name)'s Day"
        if let photo {
            avatarImageView.image = photo
            avatarInitialLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarInitialLabel.text = String(name.prefix(1)).uppercased()
            avatarInitialLabel.isHidden = false
        }
        if let birthday {
            ageLabel.text = Self.ageText(from: birthday)
        } else {
            ageLabel.text = ""
        }
    }

    @objc private func calTapped() { onCalendarTap?() }

    static func ageText(from birthday: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day],
                                       from: cal.startOfDay(for: birthday),
                                       to: cal.startOfDay(for: Date()))
        let y = max(0, comps.year ?? 0)
        let m = max(0, comps.month ?? 0)
        let d = max(0, comps.day ?? 0)
        if y == 0 && m == 0 { return "\(d) days old" }
        if y == 0 { return "\(m) months \(d) days old" }
        return "\(y) years \(m) months \(d) days old"
    }
}

// MARK: - FeedingWeekCalendarCell

final class FeedingWeekCalendarCell: UICollectionViewCell {
    static let reuseId = "FeedingWeekCalendarCell"

    var onDaySelected: ((Date) -> Void)?
    var onToggleExpand: (() -> Void)?

    private(set) var isExpanded = false
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()

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
        b.tintColor = UIColor(hexString: "#9b7fd4")
        b.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        return b
    }()
    private lazy var nextBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        b.tintColor = UIColor(hexString: "#9b7fd4")
        b.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        return b
    }()
    private var dayButtons: [UIButton] = []

    // MARK: Chevrons
    private lazy var expandChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        b.tintColor = UIColor(hexString: "#9b7fd4")
        b.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        return b
    }()
    private lazy var collapseChevron: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        b.tintColor = UIColor(hexString: "#9b7fd4")
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
        let purple = UIColor(hexString: "#9b7fd4")
        for i in 0..<7 {
            guard i < weekDates.count else { continue }
            let date = weekDates[i]
            weekNumLabels[i].text = "\(cal.component(.day, from: date))"
            let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
            let isToday = cal.isDateInToday(date)
            weekCircles[i].backgroundColor = isSelected ? purple : .clear
            weekNumLabels[i].textColor = isSelected ? .white : (isToday ? purple : UIColor(hexString: "#333333"))
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
        let purple = UIColor(hexString: "#9b7fd4")

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
                    btn.backgroundColor = purple
                    btn.setTitleColor(.white, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .bold)
                } else if isToday {
                    btn.backgroundColor = purple.withAlphaComponent(0.12)
                    btn.setTitleColor(purple, for: .normal)
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

// MARK: - FeedingLastFeedCell

final class FeedingLastFeedCell: UICollectionViewCell {
    static let reuseId = "FeedingLastFeedCell"

    private let accentStrip: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#9b7fd4")
        return v
    }()

    private let lastFeedTitle: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "LAST FEED", attributes: [
            .kern: 1.2,
            .font: UIFont.systemFont(ofSize: 10 * Constraint.yCoeff, weight: .semibold),
            .foregroundColor: UIColor(hexString: "#9b7fd4")
        ])
        return l
    }()

    private let timeAgoLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    private let typeBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let typeBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .semibold)
        return l
    }()

    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888")
        return l
    }()

    private let iconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#9b7fd4").withAlphaComponent(0.12)
        v.layer.cornerRadius = 22 * Constraint.yCoeff
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "drop.fill"))
        iv.tintColor = UIColor(hexString: "#9b7fd4")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(accentStrip)
        contentView.addSubview(lastFeedTitle)
        contentView.addSubview(timeAgoLabel)
        contentView.addSubview(typeBadge)
        typeBadge.addSubview(typeBadgeLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(iconCircle)
        iconCircle.addSubview(iconView)

        accentStrip.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(5 * Constraint.xCoeff)
        }
        lastFeedTitle.snp.makeConstraints {
            $0.leading.equalTo(accentStrip.snp.trailing).offset(14 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        timeAgoLabel.snp.makeConstraints {
            $0.leading.equalTo(lastFeedTitle)
            $0.top.equalTo(lastFeedTitle.snp.bottom).offset(4 * Constraint.yCoeff)
        }
        typeBadge.snp.makeConstraints {
            $0.leading.equalTo(lastFeedTitle)
            $0.bottom.equalToSuperview().inset(12 * Constraint.yCoeff)
        }
        typeBadgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
        }
        amountLabel.snp.makeConstraints {
            $0.leading.equalTo(typeBadge.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.centerY.equalTo(typeBadge)
        }
        iconCircle.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(lastEntry: FeedingLogEntry?) {
        guard let entry = lastEntry else {
            timeAgoLabel.text = "No feeds yet"
            typeBadge.isHidden = true
            amountLabel.isHidden = true
            return
        }
        typeBadge.isHidden = false
        amountLabel.isHidden = false

        let entryDate = Date(timeIntervalSince1970: entry.savedAtEpochSeconds ?? 0)
        let elapsed = Date().timeIntervalSince(entryDate)
        let hours = Int(elapsed / 3600)
        let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        timeAgoLabel.text = hours > 0 ? "\(hours)h \(minutes)m ago" : "\(minutes)m ago"

        let accentColor: UIColor
        let iconName: String
        switch entry.typeRaw {
        case "breast":
            accentColor = UIColor(hexString: "#E8613A")
            iconName = "heart.fill"
            typeBadge.backgroundColor = accentColor.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = accentColor
            typeBadgeLabel.text = "Breast"
        case "bottle":
            accentColor = UIColor(hexString: "#9b7fd4")
            iconName = "waterbottle"
            typeBadge.backgroundColor = accentColor.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = accentColor
            typeBadgeLabel.text = "Bottle"
        case "formula":
            accentColor = UIColor(hexString: "#4a9fc4")
            iconName = "drop.fill"
            typeBadge.backgroundColor = accentColor.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = accentColor
            typeBadgeLabel.text = "Formula"
        case "solid":
            accentColor = UIColor(hexString: "#5aac7c")
            iconName = "fork.knife"
            typeBadge.backgroundColor = accentColor.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = accentColor
            typeBadgeLabel.text = "Solids"
        default:
            typeBadge.isHidden = true
            accentColor = UIColor(hexString: "#9b7fd4")
            iconName = "drop.fill"
        }

        accentStrip.backgroundColor = accentColor
        lastFeedTitle.attributedText = NSAttributedString(string: "LAST FEED", attributes: [
            .kern: 1.2,
            .font: UIFont.systemFont(ofSize: 10 * Constraint.yCoeff, weight: .semibold),
            .foregroundColor: accentColor
        ])
        iconCircle.backgroundColor = accentColor.withAlphaComponent(0.12)
        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = accentColor

        amountLabel.text = entry.volumeText
    }
}

// MARK: - FeedingQuickActionsCell

final class FeedingQuickActionsCell: UICollectionViewCell {
    static let reuseId = "FeedingQuickActionsCell"

    var onQuickLog: ((FeedingTypeView.FeedingType) -> Void)?

    private lazy var breastBtn  = makeBtn(
        title: "Start Breast", icon: "heart.fill",
        cardColor:   UIColor(hexString: "#E8613A"),
        circleBg:    UIColor(white: 1, alpha: 0.22),
        iconTint:    .white,
        labelColor:  .white,
        tag: 0
    )
    private lazy var bottleBtn  = makeBtn(
        title: "Bottle", icon: "waterbottle",
        cardColor:   UIColor(hexString: "#9b7fd4"),
        circleBg:    UIColor(white: 1, alpha: 0.22),
        iconTint:    .white,
        labelColor:  .white,
        tag: 1
    )
    private lazy var solidsBtn  = makeBtn(
        title: "Solids", icon: "fork.knife",
        cardColor:   UIColor(hexString: "#5aac7c"),
        circleBg:    UIColor(white: 1, alpha: 0.22),
        iconTint:    .white,
        labelColor:  .white,
        tag: 2
    )
    private lazy var formulaBtn = makeBtn(
        title: "Formula", icon: "drop.fill",
        cardColor:   UIColor(hexString: "#4a9fc4"),
        circleBg:    UIColor(white: 1, alpha: 0.22),
        iconTint:    .white,
        labelColor:  .white,
        tag: 3
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        let topRow = UIStackView(arrangedSubviews: [breastBtn, bottleBtn])
        topRow.axis = .horizontal
        topRow.spacing = 10 * Constraint.xCoeff
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [solidsBtn, formulaBtn])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 10 * Constraint.xCoeff
        bottomRow.distribution = .fillEqually

        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = 10 * Constraint.yCoeff
        grid.distribution = .fillEqually

        contentView.addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeBtn(title: String, icon: String,
                         cardColor: UIColor, circleBg: UIColor,
                         iconTint: UIColor, labelColor: UIColor,
                         tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = cardColor
        container.layer.cornerRadius = 20 * Constraint.yCoeff
        container.clipsToBounds = true

        // Icon circle
        let iconCircle = UIView()
        iconCircle.backgroundColor = circleBg
        iconCircle.layer.cornerRadius = 28 * Constraint.yCoeff
        iconCircle.clipsToBounds = true
        iconCircle.isUserInteractionEnabled = false

        let iv = UIImageView(image: UIImage(systemName: icon))
        iv.tintColor = iconTint
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        iconCircle.addSubview(iv)
        iv.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(26 * Constraint.yCoeff) }

        // "+" badge — sits on top of the circle, added to container so it isn't clipped by the circle
        let badge = UIView()
        badge.backgroundColor = UIColor(hexString: "#4a90d9")
        badge.layer.cornerRadius = 10 * Constraint.yCoeff
        badge.isUserInteractionEnabled = false
        let plusLbl = UILabel()
        plusLbl.text = "+"
        plusLbl.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        plusLbl.textColor = .white
        plusLbl.textAlignment = .center
        plusLbl.isUserInteractionEnabled = false
        badge.addSubview(plusLbl)
        plusLbl.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Label
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        lbl.textColor = labelColor
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.isUserInteractionEnabled = false

        container.addSubview(iconCircle)
        container.addSubview(badge)
        container.addSubview(lbl)

        iconCircle.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10 * Constraint.yCoeff)
            $0.width.height.equalTo(56 * Constraint.yCoeff)
        }
        // Badge at bottom-right edge of the circle
        badge.snp.makeConstraints {
            $0.width.height.equalTo(20 * Constraint.yCoeff)
            $0.trailing.equalTo(iconCircle).offset(2 * Constraint.xCoeff)
            $0.bottom.equalTo(iconCircle).offset(2 * Constraint.yCoeff)
        }
        lbl.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.bottom.lessThanOrEqualToSuperview().inset(10 * Constraint.yCoeff)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(btnTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.tag = tag
        return container
    }

    @objc private func btnTapped(_ g: UITapGestureRecognizer) {
        guard let tag = g.view?.tag else { return }
        let types: [FeedingTypeView.FeedingType] = [.breast, .bottle, .solid, .formula]
        guard tag < types.count else { return }
        UIView.animate(withDuration: 0.1, animations: {
            g.view?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) { g.view?.transform = .identity }
        }
        onQuickLog?(types[tag])
    }
}

// MARK: - FeedingBreastTimerCell

final class FeedingBreastTimerCell: UICollectionViewCell {
    static let reuseId = "FeedingBreastTimerCell"

    /// Called the instant the timer starts. Provides (startDate, side "L"/"R").
    var onStart: ((Date, String) -> Void)?

    /// Called when the timer stops (user tapped Stop or external stopAndSave).
    /// Provides (totalElapsed seconds, side "L"/"R").
    var onSave: ((TimeInterval, String) -> Void)?

    // MARK: State
    private let accent = UIColor(hexString: "#E8613A")
    private var selectedSide = "L"
    private var isRunning = false
    private var sessionStart: Date?
    private var accumulatedSeconds: TimeInterval = 0
    private var liveTimer: Timer?

    // MARK: Views
    private lazy var emojiLabel: UILabel = {
        let l = UILabel()
        l.text = "🤱"
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff)
        return l
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "BREASTFEEDING TIMER", attributes: [
            .kern: 1.1,
            .font: UIFont.systemFont(ofSize: 10 * Constraint.yCoeff, weight: .semibold),
            .foregroundColor: UIColor(hexString: "#999999")
        ])
        return l
    }()

    private lazy var lBtn: UIButton = makeSideBtn(title: "L", tag: 0)
    private lazy var rBtn: UIButton = makeSideBtn(title: "R", tag: 1)

    private lazy var timerLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 52 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        l.text = "00:00"
        l.textAlignment = .center
        return l
    }()

    private lazy var startStopBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("▶  Start Timer", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#E8613A")
        b.layer.cornerRadius = 22 * Constraint.yCoeff
        b.addTarget(self, action: #selector(startStopTapped), for: .touchUpInside)
        return b
    }()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(lBtn)
        contentView.addSubview(rBtn)
        contentView.addSubview(timerLabel)
        contentView.addSubview(startStopBtn)

        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(16 * Constraint.yCoeff)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(6 * Constraint.xCoeff)
            $0.centerY.equalTo(emojiLabel)
        }
        rBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.centerY.equalTo(emojiLabel)
            $0.width.height.equalTo(34 * Constraint.yCoeff)
        }
        lBtn.snp.makeConstraints {
            $0.trailing.equalTo(rBtn.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.centerY.equalTo(emojiLabel)
            $0.width.height.equalTo(34 * Constraint.yCoeff)
        }
        timerLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emojiLabel.snp.bottom).offset(6 * Constraint.yCoeff)
        }
        startStopBtn.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.top.equalTo(timerLabel.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.height.equalTo(46 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(16 * Constraint.yCoeff)
        }

        updateSideButtons()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { liveTimer?.invalidate() }

    // MARK: Helpers

    private func makeSideBtn(title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .bold)
        b.layer.cornerRadius = 17 * Constraint.yCoeff
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor(hexString: "#E8613A").cgColor
        b.tag = tag
        b.addTarget(self, action: #selector(sideTapped(_:)), for: .touchUpInside)
        return b
    }

    private func updateSideButtons() {
        for btn in [lBtn, rBtn] {
            let isSelected = (btn.tag == 0 && selectedSide == "L") || (btn.tag == 1 && selectedSide == "R")
            btn.backgroundColor = isSelected ? accent : .clear
            btn.setTitleColor(isSelected ? .white : accent, for: .normal)
        }
    }

    private func updateDisplay(elapsed: TimeInterval) {
        let totalSeconds = Int(elapsed)
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", m, s)
    }

    // MARK: Actions

    @objc private func sideTapped(_ btn: UIButton) {
        guard !isRunning else { return }   // side can't change while running
        selectedSide = btn.tag == 0 ? "L" : "R"
        updateSideButtons()
    }

    /// Stops the timer and fires `onSave`. Safe to call from outside (e.g. lock-screen action).
    func stopAndSave() {
        guard isRunning else { return }
        liveTimer?.invalidate(); liveTimer = nil
        isRunning = false
        if let start = sessionStart { accumulatedSeconds += Date().timeIntervalSince(start) }
        sessionStart = nil

        let finalElapsed = accumulatedSeconds
        onSave?(finalElapsed, selectedSide)

        // Reset UI
        accumulatedSeconds = 0
        updateDisplay(elapsed: 0)
        timerLabel.textColor = UIColor(hexString: "#222222")
        startStopBtn.setTitle("▶  Start Timer", for: .normal)
        startStopBtn.backgroundColor = accent
        lBtn.isEnabled = true
        rBtn.isEnabled = true
    }

    @objc private func startStopTapped() {
        if isRunning {
            stopAndSave()
        } else {
            // ── Start ────────────────────────────────────────────────────
            let now = Date()
            sessionStart = now
            isRunning = true
            timerLabel.textColor = accent
            startStopBtn.setTitle("⏹  Stop & Save", for: .normal)
            startStopBtn.backgroundColor = UIColor(hexString: "#c0392b")
            lBtn.isEnabled = false
            rBtn.isEnabled = false

            onStart?(now, selectedSide)   // notify the VC so it can set up the notification

            liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self, let start = self.sessionStart else { return }
                self.updateDisplay(elapsed: self.accumulatedSeconds + Date().timeIntervalSince(start))
            }
            RunLoop.main.add(liveTimer!, forMode: .common)
        }
    }
}

// MARK: - FeedingStatsBarView

final class FeedingStatsBarView: UIView {

    private let totalLabel = UILabel()
    private let feedsLabel = UILabel()
    private let avgLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressRatio: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 20 * Constraint.yCoeff
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: -2)

        for l in [totalLabel, feedsLabel, avgLabel] {
            l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .medium)
            l.textColor = UIColor(hexString: "#555555")
            l.textAlignment = .center
        }

        progressTrack.backgroundColor = UIColor(hexString: "#f0f0f0")
        progressTrack.layer.cornerRadius = 3
        progressFill.backgroundColor = UIColor(hexString: "#9b7fd4")
        progressFill.layer.cornerRadius = 3
        progressTrack.addSubview(progressFill)

        let div1 = makeDivider()
        let div2 = makeDivider()

        addSubview(totalLabel)
        addSubview(div1)
        addSubview(feedsLabel)
        addSubview(div2)
        addSubview(avgLabel)
        addSubview(progressTrack)

        totalLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.centerY.equalToSuperview().offset(-8 * Constraint.yCoeff)
        }
        div1.snp.makeConstraints {
            $0.leading.equalTo(totalLabel.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(totalLabel)
            $0.width.equalTo(1)
            $0.height.equalTo(16 * Constraint.yCoeff)
        }
        feedsLabel.snp.makeConstraints {
            $0.leading.equalTo(div1.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(totalLabel)
        }
        div2.snp.makeConstraints {
            $0.leading.equalTo(feedsLabel.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(totalLabel)
            $0.width.equalTo(1)
            $0.height.equalTo(16 * Constraint.yCoeff)
        }
        avgLabel.snp.makeConstraints {
            $0.leading.equalTo(div2.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(totalLabel)
        }
        progressTrack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(12 * Constraint.yCoeff)
            $0.height.equalTo(5 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e0e0e0")
        return v
    }

    func configure(totalML: Int, feedCount: Int, avgIntervalHours: Double?) {
        totalLabel.text = "Total: \(totalML) ml"
        feedsLabel.text = "Feeds: \(feedCount)"
        avgLabel.text = avgIntervalHours.map { "Avg: \(String(format: "%.1f", $0))h" } ?? "Avg: —"
        progressRatio = min(CGFloat(totalML) / 800.0, 1.0)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let trackW = progressTrack.bounds.width
        guard trackW > 0 else { return }
        progressFill.frame = CGRect(x: 0, y: 0, width: trackW * progressRatio, height: progressTrack.bounds.height)
    }
}

// MARK: - FeedingDatePickerViewController

private final class FeedingDatePickerViewController: UIViewController {

    var onDateSelected: ((Date) -> Void)?

    private let picker = UIDatePicker()
    private let initialDate: Date

    init(date: Date) {
        self.initialDate = date
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Date"
        view.backgroundColor = UIColor.viewsBackGourdColor

        picker.datePickerMode = .date
        picker.date = initialDate
        picker.tintColor = UIColor(hexString: "#9b7fd4")
        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .inline
        }

        view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(done)
        )
        navigationController?.navigationBar.tintColor = UIColor(hexString: "#9b7fd4")
    }

    @objc private func done() {
        onDateSelected?(picker.date)
        dismiss(animated: true)
    }
}

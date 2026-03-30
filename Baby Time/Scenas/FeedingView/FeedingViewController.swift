import UIKit
import SnapKit

class FeedingViewController: UIViewController {

    static let openReminderIdUserDefaultsKey = "FeedingReminderOpenReminderId"

    enum Section: Int, CaseIterable {
        case reminders = 0
        case log = 1
    }

    private var reminders: [FeedingReminder] = []
    private var logEntries: [FeedingLogEntry] = []

    private enum LogRow: Hashable {
        case header(String)
        case entry(UUID)
    }

    private var logRows: [LogRow] = []
    private var entryById: [UUID: FeedingLogEntry] = [:]

    private let dayHeaderFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        view.onTapPlus = { [weak self] in
            guard let self else { return }
            feedingActionCardButtonPressed()
        }
        view.onTapCalendar = { [weak self] in
            self?.presentCalendar()
        }
        return view
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8 * Constraint.xCoeff
        layout.sectionInset = UIEdgeInsets(top: 8 * Constraint.xCoeff, left: 8 * Constraint.yCoeff, bottom: 8 * Constraint.xCoeff, right: 8 * Constraint.yCoeff)
        layout.estimatedItemSize = CGSize(width: 374 * Constraint.yCoeff, height: 84 * Constraint.xCoeff)
        layout.headerReferenceSize = CGSize(width: 0, height: 72 * Constraint.xCoeff)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(FeedingReminderCell.self, forCellWithReuseIdentifier: FeedingReminderCell.reuseId)
        view.register(FeedingViewCell.self, forCellWithReuseIdentifier: "FeedingViewCell")
        view.register(FeedingDayHeaderCell.self, forCellWithReuseIdentifier: FeedingDayHeaderCell.reuseId)
        view.register(FeedingSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FeedingSectionHeaderView.reuseId)
        view.isScrollEnabled = true
        view.alwaysBounceVertical = true
        return view
    }()

    private lazy var feedingView: FeedingView = {
        let view = FeedingView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.feedingView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.feedingView.isHidden = true
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        loadReminders()
        loadLogItems()
        setupUI()
        setupConstraints()
        configureViews()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadReminders()
        loadLogItems()
        collectionView.reloadData()
        updateEmptyState()
        openToReminderIfPending()
    }

    private func openToReminderIfPending() {
        guard let idStr = UserDefaults.standard.string(forKey: Self.openReminderIdUserDefaultsKey),
              let reminderId = UUID(uuidString: idStr) else { return }
        UserDefaults.standard.removeObject(forKey: Self.openReminderIdUserDefaultsKey)
        guard let index = reminders.firstIndex(where: { $0.id == reminderId }) else { return }
        let indexPath = IndexPath(item: index, section: Section.reminders.rawValue)
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }

    private func loadReminders() {
        reminders = FeedingReminderStore.load().sorted { r1, r2 in
            if r1.dayTimestamp != r2.dayTimestamp { return r1.dayTimestamp < r2.dayTimestamp }
            if r1.hour != r2.hour { return r1.hour < r2.hour }
            return r1.minute < r2.minute
        }
    }

    private func loadLogItems() {
        logEntries = FeedingLogStore.loadEntries()
            .sorted { ($0.savedAtEpochSeconds ?? 0) > ($1.savedAtEpochSeconds ?? 0) }
        rebuildLogRows()
    }

    private func rebuildLogRows() {
        entryById = Dictionary(uniqueKeysWithValues: logEntries.map { ($0.id, $0) })
        var rows: [LogRow] = []
        var lastHeader: String?

        for e in logEntries {
            let date = Date(timeIntervalSince1970: e.savedAtEpochSeconds ?? 0)
            let header = dayHeaderFormatter.string(from: date)
            if header != lastHeader {
                rows.append(.header(header))
                lastHeader = header
            }
            rows.append(.entry(e.id))
        }
        logRows = rows
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(emptyStateView)
        view.addSubview(collectionView)
        view.addSubview(feedingView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }
        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(24 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        feedingView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Feeding",
            subtitle: "Reminders & log",
            showsPlusButton: true,
            plusColor: .feedingViewColor,
            showsCalendarButton: true,
            calendarColor: .feedingViewColor
        )
        emptyStateView.configure(
            icon: UIImage(systemName: "fork.knife"),
            iconTint: .feedingViewColor.withAlphaComponent(0.95),
            circleColor: .feedingViewColor.withAlphaComponent(0.40),
            title: "No feedings yet",
            subtitle: "Tap the + button to log a feeding or add a reminder above"
        )
        feedingView.onTapSave = { [weak self] type, volume, notes, time, date in
            guard let self = self else { return }
            let vmType: FeedingViewCell.ViewModel.FeedingType
            switch type {
            case .breast: vmType = .breast
            case .bottle: vmType = .bottle
            case .formula: vmType = .formula
            case .solid: vmType = .solid
            }
            let vm = FeedingViewCell.ViewModel(type: vmType, volumeText: volume, notesText: notes, timeText: time, dateText: date)
            FeedingLogStore.add(vm)
            self.loadLogItems()
            self.collectionView.reloadData()
            self.updateEmptyState()
        }
    }

    private func updateEmptyState() {
        let hasContent = !reminders.isEmpty || !logEntries.isEmpty
        emptyStateView.isHidden = hasContent
        collectionView.isHidden = !hasContent
    }

    private func presentCalendar() {
        if #available(iOS 16.0, *) {
            let vc = FeedingCalendarViewController()
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
            return
        }
        presentReminderEdit(reminder: nil)
    }

    private func presentReminderEdit(reminder: FeedingReminder?, forDate: Date? = nil) {
        FeedingReminderNotificationManager.requestAuthorization { [weak self] granted in
            guard let self else { return }
            if !granted {
                let alert = UIAlertController(title: "Notifications Off", message: "Enable notifications in Settings to get feeding reminders.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let vc = FeedingReminderEditViewController()
            vc.reminder = reminder
            vc.forDate = forDate
            vc.onSave = { [weak self] updated in
                self?.saveReminder(updated)
            }
            vc.onDelete = { [weak self] id in
                self?.deleteReminder(id: id)
            }
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
    }

    private func saveReminder(_ reminder: FeedingReminder) {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
        } else {
            reminders.append(reminder)
        }
        reminders.sort { r1, r2 in
            if r1.dayTimestamp != r2.dayTimestamp { return r1.dayTimestamp < r2.dayTimestamp }
            if r1.hour != r2.hour { return r1.hour < r2.hour }
            return r1.minute < r2.minute
        }
        FeedingReminderStore.save(reminders)
        FeedingReminderNotificationManager.schedule(reminder)
        collectionView.reloadData()
        updateEmptyState()
    }

    private func deleteReminder(id: UUID) {
        reminders.removeAll { $0.id == id }
        FeedingReminderStore.save(reminders)
        FeedingReminderNotificationManager.unschedule(reminderId: id)
        collectionView.reloadData()
        updateEmptyState()
    }

    private func viewModel(from reminder: FeedingReminder) -> FeedingViewCell.ViewModel {
        let type: FeedingViewCell.ViewModel.FeedingType
        switch reminder.feedingType {
        case .breast: type = .breast
        case .bottle: type = .bottle
        case .formula: type = .formula
        case .solid: type = .solid
        }
        return FeedingViewCell.ViewModel(
            type: type,
            volumeText: nil,
            notesText: reminder.note.isEmpty ? nil : reminder.note,
            timeText: reminder.timeString,
            dateText: reminder.dateString
        )
    }

    private func moveReminderToHistory(_ reminder: FeedingReminder) {
        guard let reminderIndex = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        let vm = viewModel(from: reminder)
        FeedingLogStore.add(vm)
        loadLogItems()
        reminders.remove(at: reminderIndex)
        FeedingReminderStore.save(reminders)
        FeedingReminderNotificationManager.unschedule(reminderId: reminder.id)

        let deletePath = IndexPath(item: reminderIndex, section: Section.reminders.rawValue)
        let insertPath = IndexPath(item: 0, section: Section.log.rawValue)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [deletePath])
            collectionView.reloadSections(IndexSet(integer: Section.log.rawValue))
        } completion: { [weak self] _ in
            self?.updateEmptyState()
        }
    }

    @objc private func feedingActionCardButtonPressed() {
        feedingView.isHidden = false
        feedingView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) {
            self.feedingView.transform = .identity
        }
    }
}

extension FeedingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .reminders: return reminders.count
        case .log: return logRows.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FeedingSectionHeaderView.reuseId, for: indexPath) as! FeedingSectionHeaderView
        switch Section(rawValue: indexPath.section)! {
        case .reminders:
            header.configure(title: "Feeding Reminder", subtitle: "", showsAddButton: false)
            header.onTapAdd = { [weak self] in
                self?.presentReminderEdit(reminder: nil)
            }
        case .log:
            header.configure(title: "Feeding Log", subtitle: "", showsAddButton: false)
            header.onTapAdd = { [weak self] in
                self?.feedingActionCardButtonPressed()
            }
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .reminders:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedingReminderCell.reuseId, for: indexPath) as! FeedingReminderCell
            let reminder = reminders[indexPath.item]
            cell.configure(reminder: reminder)
            cell.onCircleTap = { [weak self] in
                self?.moveReminderToHistory(reminder)
            }
            cell.onTap = { [weak self] in
                self?.presentReminderEdit(reminder: reminder)
            }
            return cell
        case .log:
            let row = logRows[indexPath.item]
            switch row {
            case .header(let title):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedingDayHeaderCell.reuseId, for: indexPath) as! FeedingDayHeaderCell
                cell.configure(title: title)
                return cell
            case .entry(let id):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedingViewCell", for: indexPath) as! FeedingViewCell
                if let entry = entryById[id] {
                    cell.configure(with: viewModel(from: entry))
                    cell.onDelete = { [weak self] in
                        self?.deleteEntry(id: id)
                    }
                }
                return cell
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 16 * Constraint.yCoeff
        switch Section(rawValue: indexPath.section)! {
        case .reminders: return CGSize(width: width, height: 88 * Constraint.xCoeff)
        case .log:
            switch logRows[indexPath.item] {
            case .header:
                return CGSize(width: collectionView.bounds.width, height: 44 * Constraint.xCoeff)
            case .entry:
                return CGSize(width: width, height: 100 * Constraint.xCoeff)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 72 * Constraint.xCoeff)
    }

    private func deleteEntry(id: UUID) {
        logEntries.removeAll { $0.id == id }
        FeedingLogStore.saveEntries(logEntries)
        rebuildLogRows()
        collectionView.reloadSections(IndexSet(integer: Section.log.rawValue))
        updateEmptyState()
    }

    private func viewModel(from entry: FeedingLogEntry) -> FeedingViewCell.ViewModel {
        let type: FeedingViewCell.ViewModel.FeedingType
        switch entry.typeRaw {
        case "breast": type = .breast
        case "bottle": type = .bottle
        case "formula": type = .formula
        case "solid": type = .solid
        default: type = .solid
        }
        return FeedingViewCell.ViewModel(
            type: type,
            volumeText: entry.volumeText,
            notesText: entry.notesText,
            timeText: entry.timeText,
            dateText: entry.dateText
        )
    }
}

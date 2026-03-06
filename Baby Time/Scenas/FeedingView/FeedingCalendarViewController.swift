import UIKit
import SnapKit

@available(iOS 16.0, *)
final class FeedingCalendarViewController: UIViewController {

    private var selectedDate: Date?
    private var remindersForSelectedDay: [FeedingReminder] = []
    private var dateSelection: UICalendarSelectionSingleDate?

    private lazy var calendarView: UICalendarView = {
        let view = UICalendarView()
        view.calendar = .current
        view.locale = .current
        view.fontDesign = .rounded
        return view
    }()

    private lazy var dayTitleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 18, weight: .semibold)
        view.textColor = .label
        view.text = "Select a day"
        return view
    }()

    private lazy var addButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Add time & note", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .feedingViewColor
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .insetGrouped)
        view.delegate = self
        view.dataSource = self
        view.register(FeedingReminderTableCell.self, forCellReuseIdentifier: FeedingReminderTableCell.reuseId)
        view.rowHeight = 76
        view.backgroundColor = .clear
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feeding Reminders"
        view.backgroundColor = .viewsBackGourdColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        let selection = UICalendarSelectionSingleDate(delegate: self)
        dateSelection = selection
        calendarView.selectionBehavior = selection
        selectToday()
        setupUI()
        setupConstraints()
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    private func selectToday() {
        let today = Calendar.current.startOfDay(for: Date())
        selectedDate = today
        dateSelection?.setSelected(Calendar.current.dateComponents([.year, .month, .day], from: today), animated: false)
        refreshDayTitle()
        loadRemindersForSelectedDay()
    }

    private func setupUI() {
        view.addSubview(calendarView)
        view.addSubview(dayTitleLabel)
        view.addSubview(addButton)
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        calendarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.height.equalTo(280 * Constraint.xCoeff)
        }
        dayTitleLabel.snp.makeConstraints {
            $0.top.equalTo(calendarView.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
        }
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(dayTitleLabel)
            $0.trailing.equalToSuperview().offset(-20 * Constraint.yCoeff)
            $0.height.equalTo(44 * Constraint.xCoeff)
            $0.width.greaterThanOrEqualTo(140 * Constraint.yCoeff)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(dayTitleLabel.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func refreshDayTitle() {
        guard let d = selectedDate else {
            dayTitleLabel.text = "Select a day"
            return
        }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        dayTitleLabel.text = f.string(from: d)
    }

    private func loadRemindersForSelectedDay() {
        guard let d = selectedDate else {
            remindersForSelectedDay = []
            return
        }
        remindersForSelectedDay = FeedingReminderStore.reminders(for: d)
        tableView.reloadData()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    @objc private func addTapped() {
        guard let day = selectedDate else {
            let alert = UIAlertController(title: "Select a day", message: "Tap a date on the calendar first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        FeedingReminderNotificationManager.requestAuthorization { [weak self] granted in
            guard let self else { return }
            if !granted {
                let alert = UIAlertController(title: "Notifications Off", message: "Enable notifications in Settings to get feeding reminders.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let vc = FeedingReminderEditViewController()
            vc.forDate = day
            vc.onSave = { [weak self] reminder in
                var all = FeedingReminderStore.load()
                if let idx = all.firstIndex(where: { $0.id == reminder.id }) {
                    all[idx] = reminder
                } else {
                    all.append(reminder)
                }
                FeedingReminderStore.save(all)
                FeedingReminderNotificationManager.schedule(reminder)
                self?.loadRemindersForSelectedDay()
            }
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
    }

    private func editReminder(_ reminder: FeedingReminder) {
        let vc = FeedingReminderEditViewController()
        vc.reminder = reminder
        vc.onSave = { [weak self] updated in
            var all = FeedingReminderStore.load()
            if let idx = all.firstIndex(where: { $0.id == updated.id }) {
                all[idx] = updated
            }
            FeedingReminderStore.save(all)
            FeedingReminderNotificationManager.schedule(updated)
            self?.loadRemindersForSelectedDay()
        }
        vc.onDelete = { [weak self] id in
            var all = FeedingReminderStore.load()
            all.removeAll { $0.id == id }
            FeedingReminderStore.save(all)
            FeedingReminderNotificationManager.unschedule(reminderId: id)
            self?.loadRemindersForSelectedDay()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
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
        FeedingLogStore.add(viewModel(from: reminder))
        var all = FeedingReminderStore.load()
        all.removeAll { $0.id == reminder.id }
        FeedingReminderStore.save(all)
        FeedingReminderNotificationManager.unschedule(reminderId: reminder.id)
        loadRemindersForSelectedDay()
    }
}

@available(iOS 16.0, *)
extension FeedingCalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selectedDate = dateComponents.flatMap { Calendar.current.date(from: $0) }
        refreshDayTitle()
        loadRemindersForSelectedDay()
    }
}

@available(iOS 16.0, *)
extension FeedingCalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        remindersForSelectedDay.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FeedingReminderTableCell.reuseId, for: indexPath) as! FeedingReminderTableCell
        let reminder = remindersForSelectedDay[indexPath.row]
        cell.configure(reminder: reminder)
        cell.onCircleTap = { [weak self] in
            self?.moveReminderToHistory(reminder)
        }
        cell.onTap = { [weak self] in
            self?.editReminder(reminder)
        }
        return cell
    }
}

/// Table cell for reminder: circle on left (tap = move to history), time + note.
final class FeedingReminderTableCell: UITableViewCell {

    static let reuseId = "FeedingReminderTableCell"

    var onCircleTap: (() -> Void)?
    var onTap: (() -> Void)?

    private lazy var circleButton: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .clear
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.feedingViewColor.cgColor
        view.clipsToBounds = true
        return view
    }()

    private lazy var circleFilled: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()

    private lazy var typeLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 17, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var noteLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.textColor = .secondaryLabel
        view.numberOfLines = 2
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(circleButton)
        circleButton.addSubview(circleFilled)
        contentView.addSubview(typeLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(noteLabel)
        circleButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(32 * Constraint.yCoeff)
            $0.height.equalTo(32 * Constraint.xCoeff)
        }
        circleFilled.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(20 * Constraint.yCoeff)
            $0.height.equalTo(20 * Constraint.xCoeff)
        }
        typeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(circleButton.snp.trailing).offset(12 * Constraint.yCoeff)
        }
        timeLabel.snp.makeConstraints {
            $0.centerY.equalTo(typeLabel)
            $0.leading.equalTo(typeLabel.snp.trailing).offset(8 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16 * Constraint.yCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(typeLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(typeLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16 * Constraint.yCoeff)
        }
        circleButton.addTarget(self, action: #selector(circleTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func circleTapped() {
        circleFilled.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.circleFilled.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.circleFilled.transform = .identity
            }) { _ in
                self.onCircleTap?()
            }
        }
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: contentView)
        if circleButton.frame.contains(loc) { return }
        onTap?()
    }

    func configure(reminder: FeedingReminder) {
        switch reminder.feedingType {
        case .breast: typeLabel.text = "Breast"
        case .bottle: typeLabel.text = "Bottle"
        case .formula: typeLabel.text = "Formula"
        case .solid: typeLabel.text = "Solid"
        }
        timeLabel.text = reminder.timeString
        noteLabel.text = reminder.note.isEmpty ? "No note" : reminder.note
        circleFilled.isHidden = true
    }
}

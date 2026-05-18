import UIKit
import SnapKit

@available(iOS 16.0, *)
final class VaccinationCalendarViewController: UIViewController {

    private let accent = UIColor(hexString: "#8b6dc4")
    private var selectedDate: Date?
    private var remindersForSelectedDay: [VaccinationReminder] = []
    private var dateSelection: UICalendarSelectionSingleDate?

    var onWillDismiss: (() -> Void)?

    private lazy var calendarView: UICalendarView = {
        let v = UICalendarView()
        v.calendar = .current
        v.locale = .current
        v.fontDesign = .rounded
        return v
    }()

    private lazy var dayTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .label
        l.text = "Select a day"
        return l
    }()

    private lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add time & note", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = accent
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        return b
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self
        tv.dataSource = self
        tv.register(VaccinationReminderTableCell.self, forCellReuseIdentifier: VaccinationReminderTableCell.reuseId)
        tv.rowHeight = 72
        tv.backgroundColor = .clear
        return tv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRemindersForSelectedDay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vaccination Reminders"
        view.backgroundColor = .viewsBackGourdColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        let selection = UICalendarSelectionSingleDate(delegate: self)
        dateSelection = selection
        calendarView.selectionBehavior = selection
        calendarView.tintColor = accent
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
            $0.height.equalTo(380 * Constraint.xCoeff)
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
            tableView.reloadData()
            return
        }
        remindersForSelectedDay = VaccinationReminderStore.reminders(for: d)
        tableView.reloadData()
    }

    @objc private func doneTapped() {
        onWillDismiss?()
        dismiss(animated: true)
    }

    @objc private func addTapped() {
        guard let day = selectedDate else {
            let alert = UIAlertController(title: "Select a day", message: "Tap a date on the calendar first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        VaccinationReminderNotificationManager.requestAuthorization { [weak self] granted in
            guard let self else { return }
            if !granted {
                let alert = UIAlertController(title: "Notifications Off", message: "Enable notifications in Settings to get vaccination reminders.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let vc = VaccinationReminderEditViewController()
            vc.forDate = day
            vc.onSave = { [weak self] reminder in
                var all = VaccinationReminderStore.load()
                if let idx = all.firstIndex(where: { $0.id == reminder.id }) {
                    all[idx] = reminder
                } else {
                    all.append(reminder)
                }
                VaccinationReminderStore.save(all)
                VaccinationReminderNotificationManager.schedule(reminder)
                Self.upsertVaccine(from: reminder)
                self?.onWillDismiss?()
                self?.dismiss(animated: true)
            }
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
    }

    private func editReminder(_ reminder: VaccinationReminder) {
        let vc = VaccinationReminderEditViewController()
        vc.reminder = reminder
        vc.onSave = { [weak self] updated in
            var all = VaccinationReminderStore.load()
            if let idx = all.firstIndex(where: { $0.id == updated.id }) {
                all[idx] = updated
            }
            VaccinationReminderStore.save(all)
            VaccinationReminderNotificationManager.schedule(updated)
            Self.upsertVaccine(from: updated)
            self?.onWillDismiss?()
            self?.dismiss(animated: true)
        }
        vc.onDelete = { [weak self] id in
            var all = VaccinationReminderStore.load()
            all.removeAll { $0.id == id }
            VaccinationReminderStore.save(all)
            VaccinationReminderNotificationManager.unschedule(reminderId: id)
            VaccineStore.delete(id: id)
            self?.loadRemindersForSelectedDay()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private static func upsertVaccine(from reminder: VaccinationReminder) {
        let label = reminder.note.isEmpty ? "Vaccination" : reminder.note
        let v = Vaccine(
            id: reminder.id,
            name: label,
            fullName: label,
            ageRange: "",
            scheduledDate: reminder.date,
            scheduledHour: reminder.hour,
            scheduledMinute: reminder.minute
        )
        VaccineStore.upsert(v)
    }
}

@available(iOS 16.0, *)
extension VaccinationCalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selectedDate = dateComponents.flatMap { Calendar.current.date(from: $0) }
        refreshDayTitle()
        loadRemindersForSelectedDay()
    }
}

@available(iOS 16.0, *)
extension VaccinationCalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        remindersForSelectedDay.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VaccinationReminderTableCell.reuseId, for: indexPath) as! VaccinationReminderTableCell
        let reminder = remindersForSelectedDay[indexPath.row]
        cell.configure(reminder: reminder)
        cell.onTap = { [weak self] in self?.editReminder(reminder) }
        return cell
    }
}

// MARK: - VaccinationReminderTableCell

final class VaccinationReminderTableCell: UITableViewCell {

    static let reuseId = "VaccinationReminderTableCell"

    var onTap: (() -> Void)?

    private let accent = UIColor(hexString: "#8b6dc4")

    private lazy var iconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private lazy var timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private lazy var noteLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(iconView)
        iconView.addSubview(iconImageView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(noteLabel)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(iconView.snp.trailing).offset(12 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16 * Constraint.yCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(timeLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16 * Constraint.yCoeff)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func cardTapped() { onTap?() }

    func configure(reminder: VaccinationReminder) {
        iconView.backgroundColor = UIColor(hexString: "#8b6dc4")
        iconImageView.image = UIImage(systemName: "syringe")
        timeLabel.text = reminder.timeString
        noteLabel.text = reminder.note.isEmpty ? "No note" : reminder.note
    }
}

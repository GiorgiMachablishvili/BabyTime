import UIKit
import SnapKit

@available(iOS 16.0, *)
final class VisitCalendarViewController: UIViewController {

    var kind: VisitReminder.Kind = .vaccination
    private var selectedDate: Date?
    private var visitsForSelectedDay: [VisitReminder] = []
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
        view.setTitle("Add note & reminder", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .growthViewColor
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .insetGrouped)
        view.delegate = self
        view.dataSource = self
        view.register(VisitReminderTableCell.self, forCellReuseIdentifier: VisitReminderTableCell.reuseId)
        view.rowHeight = 76
        view.backgroundColor = .clear
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = kind == .vaccination ? "Vaccination" : "Doctor Visit"
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
        loadVisits()
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
            $0.width.greaterThanOrEqualTo(160 * Constraint.yCoeff)
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

    private func loadVisits() {
        guard let d = selectedDate else {
            visitsForSelectedDay = []
            tableView.reloadData()
            return
        }
        visitsForSelectedDay = VisitReminderStore.visits(for: d, kind: kind)
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
        VisitReminderNotificationManager.requestAuthorization { [weak self] granted in
            guard let self else { return }
            if !granted {
                let alert = UIAlertController(title: "Notifications Off", message: "Enable notifications in Settings to get reminders.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let vc = VisitEditViewController()
            vc.kind = self.kind
            vc.forDate = day
            vc.onSave = { [weak self] visit in
                var all = VisitReminderStore.load(kind: self?.kind ?? .vaccination)
                if let idx = all.firstIndex(where: { $0.id == visit.id }) {
                    all[idx] = visit
                } else {
                    all.append(visit)
                }
                VisitReminderStore.save(all, kind: visit.kind)
                VisitReminderNotificationManager.schedule(visit)
                self?.loadVisits()
            }
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
    }

    private func editVisit(_ visit: VisitReminder) {
        let vc = VisitEditViewController()
        vc.kind = kind
        vc.visit = visit
        vc.onSave = { [weak self] updated in
            var all = VisitReminderStore.load(kind: self?.kind ?? .vaccination)
            if let idx = all.firstIndex(where: { $0.id == updated.id }) {
                all[idx] = updated
            }
            VisitReminderStore.save(all, kind: updated.kind)
            VisitReminderNotificationManager.schedule(updated)
            self?.loadVisits()
        }
        vc.onDelete = { [weak self] id in
            var all = VisitReminderStore.load(kind: self?.kind ?? .vaccination)
            all.removeAll { $0.id == id }
            VisitReminderStore.save(all, kind: self?.kind ?? .vaccination)
            VisitReminderNotificationManager.unschedule(visitId: id, kind: self?.kind ?? .vaccination)
            self?.loadVisits()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

@available(iOS 16.0, *)
extension VisitCalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selectedDate = dateComponents.flatMap { Calendar.current.date(from: $0) }
        refreshDayTitle()
        loadVisits()
    }
}

@available(iOS 16.0, *)
extension VisitCalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visitsForSelectedDay.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VisitReminderTableCell.reuseId, for: indexPath) as! VisitReminderTableCell
        let visit = visitsForSelectedDay[indexPath.row]
        cell.configure(visit: visit)
        cell.onTap = { [weak self] in
            self?.editVisit(visit)
        }
        return cell
    }
}

final class VisitReminderTableCell: UITableViewCell {
    static let reuseId = "VisitReminderTableCell"
    var onTap: (() -> Void)?

    private lazy var dateLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .semibold)
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

    private lazy var daysLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12, weight: .medium)
        view.textColor = .tertiaryLabel
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(dateLabel)
        contentView.addSubview(noteLabel)
        contentView.addSubview(daysLabel)
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalToSuperview().offset(16)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.leading.equalTo(dateLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        daysLabel.snp.makeConstraints {
            $0.top.equalTo(noteLabel.snp.bottom).offset(4)
            $0.leading.equalTo(dateLabel)
            $0.bottom.equalToSuperview().offset(-14)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        onTap?()
    }

    func configure(visit: VisitReminder) {
        dateLabel.text = visit.shortDateString
        noteLabel.text = visit.note.isEmpty ? "No note" : visit.note
        let days = visit.notifyDaysBefore.sorted()
        daysLabel.text = "Notify: \(days.map { "\($0)d before" }.joined(separator: ", "))"
    }
}

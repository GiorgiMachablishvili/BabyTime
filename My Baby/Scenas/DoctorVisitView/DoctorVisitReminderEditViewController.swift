import UIKit
import SnapKit

final class DoctorVisitReminderEditViewController: UIViewController {

    var reminder: VisitReminder?
    var forDate: Date?
    var onSave: ((VisitReminder) -> Void)?
    var onDelete: ((UUID) -> Void)?

    private let accent = UIColor(hexString: "#8b6dc4")
    private var selectedDays: Set<Int> = []
    private var dayButtons: [UIButton] = []

    private lazy var timePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.preferredDatePickerStyle = .wheels
        return dp
    }()

    private lazy var notifyLabel: UILabel = {
        let l = UILabel()
        l.text = "Notify me before"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var daysStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10 * Constraint.yCoeff
        sv.distribution = .fillEqually
        return sv
    }()

    private lazy var noteLabel: UILabel = {
        let l = UILabel()
        l.text = "Note"
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var noteTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "e.g. Dr. Smith, Clinic A"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 16)
        return tf
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = accent
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        return b
    }()

    private lazy var deleteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Reminder", for: .normal)
        b.setTitleColor(.systemRed, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return b
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .onDrag
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = reminder == nil ? "New Reminder" : "Edit Reminder"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        buildDayButtons()
        setupUI()
        setupConstraints()
        setupKeyboardAvoidance()

        if let r = reminder {
            var comps = DateComponents()
            comps.hour = r.hour
            comps.minute = r.minute
            timePicker.date = Calendar.current.date(from: comps) ?? Date()
            noteTextField.text = r.note
            selectedDays = Set(r.notifyDaysBefore)
            deleteButton.isHidden = false
        } else {
            deleteButton.isHidden = true
        }

        refreshDayButtons()
        updateButtonAvailability()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    private func updateButtonAvailability() {
        let visitDate = reminder?.visitDate ?? forDate ?? Date()
        let today = Calendar.current.startOfDay(for: Date())
        let visitDay = Calendar.current.startOfDay(for: visitDate)
        let daysUntil = Calendar.current.dateComponents([.day], from: today, to: visitDay).day ?? 0

        for b in dayButtons {
            let available = b.tag <= daysUntil
            b.isUserInteractionEnabled = available
            if !available {
                selectedDays.remove(b.tag)
                b.backgroundColor = .clear
                b.setTitleColor(UIColor.systemGray3, for: .normal)
                b.layer.borderColor = UIColor.systemGray4.cgColor
            }
        }
    }

    private func buildDayButtons() {
        for days in VisitReminder.notifyDaysBeforeOptions.filter({ [1, 3, 5, 10].contains($0) }).reversed() {
            let b = UIButton(type: .system)
            let label = days == 1 ? "1 day" : "\(days) days"
            b.setTitle(label, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            b.layer.cornerRadius = 10
            b.layer.borderWidth = 1.5
            b.clipsToBounds = true
            b.tag = days
            b.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
            daysStack.addArrangedSubview(b)
            dayButtons.append(b)
        }
    }

    private func refreshDayButtons() {
        for b in dayButtons {
            let selected = selectedDays.contains(b.tag)
            b.backgroundColor = selected ? accent : .clear
            b.setTitleColor(selected ? .white : accent, for: .normal)
            b.layer.borderColor = accent.cgColor
        }
    }

    @objc private func dayButtonTapped(_ sender: UIButton) {
        if selectedDays.contains(sender.tag) {
            selectedDays.remove(sender.tag)
        } else {
            selectedDays.insert(sender.tag)
        }
        refreshDayButtons()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(timePicker)
        contentView.addSubview(notifyLabel)
        contentView.addSubview(daysStack)
        contentView.addSubview(noteLabel)
        contentView.addSubview(noteTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(deleteButton)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        timePicker.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
        }
        notifyLabel.snp.makeConstraints {
            $0.top.equalTo(timePicker.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
        }
        daysStack.snp.makeConstraints {
            $0.top.equalTo(notifyLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
            $0.height.equalTo(44 * Constraint.xCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(daysStack.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
        }
        noteTextField.snp.makeConstraints {
            $0.top.equalTo(noteLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
            $0.height.equalTo(44 * Constraint.xCoeff)
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(noteTextField.snp.bottom).offset(32 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
            $0.height.equalTo(50 * Constraint.xCoeff)
        }
        deleteButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(contentView).offset(-24 * Constraint.xCoeff)
        }
    }

    private func setupKeyboardAvoidance() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        DispatchQueue.main.async {
            let saveFrame = self.saveButton.convert(self.saveButton.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(saveFrame.insetBy(dx: 0, dy: -20), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let note = (noteTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let id = reminder?.id ?? UUID()
        let day = reminder?.visitDate ?? forDate ?? Date()
        let updated = VisitReminder(
            id: id,
            visitDate: day,
            note: note,
            notifyDaysBefore: Array(selectedDays),
            kind: .doctorVisit,
            hour: hour,
            minute: minute
        )
        dismiss(animated: true) { [weak self] in
            self?.onSave?(updated)
        }
    }

    @objc private func deleteTapped() {
        guard let id = reminder?.id else { return }
        onDelete?(id)
        dismiss(animated: true)
    }
}

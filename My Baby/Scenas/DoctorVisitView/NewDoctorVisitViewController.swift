import UIKit
import SnapKit
import UserNotifications

// MARK: - NewDoctorVisitViewController

final class NewDoctorVisitViewController: UIViewController {

    var onSave: (() -> Void)?

    // MARK: - State

    private var selectedVisitType: String = "WELL-CHECK"
    private var selectedNotifyDays: Set<Int> = [5]

    // MARK: - Scroll / Content

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .onDrag
        return s
    }()
    private lazy var contentView = UIView()

    // MARK: - Nav bar area

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = UIColor(hexString: "#444444")
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()

    private lazy var navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "New Doctor Visit"
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .center
        return l
    }()

    // MARK: - Header

    private lazy var iconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#ede9f8")
        v.layer.cornerRadius = 32 * Constraint.yCoeff
        return v
    }()

    private lazy var iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cross.case.fill"))
        iv.tintColor = UIColor(hexString: "#8b6dc4")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var headerTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Add Doctor Visit"
        l.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        l.textAlignment = .center
        return l
    }()

    private lazy var headerSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Keep track of your little one's health journey and\nupcoming checkups."
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888")
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    // MARK: - Form card

    private lazy var formCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowRadius  = 12
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        return v
    }()

    // Field labels
    private lazy var doctorNameLabel    = makeFieldLabel("Doctor Name")
    private lazy var visitTypeLabel     = makeFieldLabel("Visit Type")
    private lazy var dateLabel          = makeFieldLabel("Date")
    private lazy var timeLabel          = makeFieldLabel("Time")
    private lazy var locationLabel      = makeFieldLabel("Location / Clinic")
    private lazy var notesLabel         = makeFieldLabel("Notes")

    // Doctor name field
    private lazy var doctorNameField = makeTextField(placeholder: "e.g. Dr. Sarah Jenkins")

    // Visit type pills (2×2 grid)
    private let visitTypes: [(title: String, type: String)] = [
        ("Well-check", "WELL-CHECK"),
        ("Sick visit", "SICK VISIT"),
        ("Vaccination", "VACCINATION"),
        ("Specialist", "SPECIALIST")
    ]

    private lazy var visitTypeRow1: UIStackView = makeVisitTypeRow(indices: 0...1)
    private lazy var visitTypeRow2: UIStackView = makeVisitTypeRow(indices: 2...3)

    private lazy var visitTypeStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [visitTypeRow1, visitTypeRow2])
        s.axis = .vertical
        s.spacing = 10 * Constraint.yCoeff
        return s
    }()

    // Date field
    private lazy var dateField: UITextField = {
        let tf = makeTextField(placeholder: "dd/mm/yyyy")
        tf.inputView = datePicker
        let bar = UIToolbar(); bar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDate))
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        tf.inputAccessoryView = bar
        tf.rightView  = makeCalendarIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        return dp
    }()

    // Time field
    private lazy var timeField: UITextField = {
        let tf = makeTextField(placeholder: "HH:MM AM")
        tf.inputView = timePicker
        let bar = UIToolbar(); bar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTime))
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        tf.inputAccessoryView = bar
        tf.rightView = makeClockIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var timePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(timePickerChanged(_:)), for: .valueChanged)
        var comps = DateComponents(); comps.hour = 10; comps.minute = 30
        if let d = Calendar.current.date(from: comps) { dp.date = d }
        return dp
    }()

    // Date + Time row
    private lazy var dateTimeRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [dateFieldContainer, timeFieldContainer])
        s.axis = .horizontal
        s.spacing = 12 * Constraint.xCoeff
        s.distribution = .fillEqually
        return s
    }()

    private lazy var dateFieldContainer: UIView = makeDateTimeFieldContainer(
        label: dateLabel,
        field: dateField
    )
    private lazy var timeFieldContainer: UIView = makeDateTimeFieldContainer(
        label: timeLabel,
        field: timeField
    )

    // Location / Clinic field
    private lazy var locationField: UITextField = {
        let tf = makeTextField(placeholder: "Willow Creek Clinic")
        tf.rightView = makeLocationIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    // Notes text view
    private lazy var notesTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor(hexString: "#f4f4f4")
        tv.layer.cornerRadius = 12 * Constraint.yCoeff
        tv.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tv.textColor = UIColor(hexString: "#888888")
        tv.text = notesPlaceholder
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        tv.delegate = self
        return tv
    }()

    private let notesPlaceholder = "Mention the slight cough and appetite changes..."

    // MARK: - Notify me before

    private lazy var notifyMeLabel: UILabel = {
        let l = UILabel()
        l.text = "Notify me before"
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#888888")
        return l
    }()

    private let notifyOptions = [10, 5, 3, 1]

    private lazy var notifyButtonsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10 * Constraint.xCoeff
        s.distribution = .fillEqually
        for days in notifyOptions {
            let b = UIButton(type: .custom)
            b.setTitle(days == 1 ? "1 day" : "\(days) days", for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
            b.layer.cornerRadius = 12 * Constraint.yCoeff
            b.layer.borderWidth  = 1.5
            b.tag = days
            b.addTarget(self, action: #selector(notifyDaysTapped(_:)), for: .touchUpInside)
            s.addArrangedSubview(b)
        }
        return s
    }()

    // MARK: - Save button

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "externaldrive.fill"), for: .normal)
        b.setTitle("  Save Record", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.tintColor = .white
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#3d2b7a")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    private lazy var saveSyncLabel: UILabel = {
        let l = UILabel()
        l.text = "Updates synced to your family profile"
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#aaaaaa")
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()

        // Default date/time
        let dateDf = DateFormatter(); dateDf.dateFormat = "dd/MM/yyyy"
        dateField.text = dateDf.string(from: Date())

        let timeDf = DateFormatter(); timeDf.dateFormat = "h:mm a"
        timeField.text = timeDf.string(from: timePicker.date)

        updateVisitTypePills()
        updateNotifyButtons()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(navTitleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(iconCircle)
        iconCircle.addSubview(iconView)
        contentView.addSubview(headerTitleLabel)
        contentView.addSubview(headerSubtitleLabel)

        contentView.addSubview(formCard)
        formCard.addSubview(doctorNameLabel)
        formCard.addSubview(doctorNameField)
        formCard.addSubview(visitTypeLabel)
        formCard.addSubview(visitTypeStack)
        formCard.addSubview(dateTimeRow)
        formCard.addSubview(locationLabel)
        formCard.addSubview(locationField)
        formCard.addSubview(notesLabel)
        formCard.addSubview(notesTextView)

        contentView.addSubview(notifyMeLabel)
        contentView.addSubview(notifyButtonsStack)
        contentView.addSubview(saveButton)
        contentView.addSubview(saveSyncLabel)
    }

    private func setupConstraints() {
        let hPad: CGFloat = 20 * Constraint.xCoeff

        // Nav
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12 * Constraint.yCoeff)
            $0.leading.equalToSuperview().offset(hPad)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        navTitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.centerX.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Header
        iconCircle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(64 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }
        headerTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        headerSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(headerTitleLabel.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }

        // Form card
        formCard.snp.makeConstraints {
            $0.top.equalTo(headerSubtitleLabel.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }

        let fPad: CGFloat = 16 * Constraint.xCoeff
        let fieldH: CGFloat = 50 * Constraint.yCoeff

        // Doctor name
        doctorNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        doctorNameField.snp.makeConstraints {
            $0.top.equalTo(doctorNameLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        // Visit type
        visitTypeLabel.snp.makeConstraints {
            $0.top.equalTo(doctorNameField.snp.bottom).offset(18 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        visitTypeStack.snp.makeConstraints {
            $0.top.equalTo(visitTypeLabel.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }

        // Date + Time side by side — no separate labels inside stack, labels are inside each container
        dateTimeRow.snp.makeConstraints {
            $0.top.equalTo(visitTypeStack.snp.bottom).offset(18 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }

        // Location
        locationLabel.snp.makeConstraints {
            $0.top.equalTo(dateTimeRow.snp.bottom).offset(18 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        locationField.snp.makeConstraints {
            $0.top.equalTo(locationLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        // Notes
        notesLabel.snp.makeConstraints {
            $0.top.equalTo(locationField.snp.bottom).offset(18 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        notesTextView.snp.makeConstraints {
            $0.top.equalTo(notesLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(100 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(20 * Constraint.yCoeff)
        }

        // Notify me before
        notifyMeLabel.snp.makeConstraints {
            $0.top.equalTo(formCard.snp.bottom).offset(22 * Constraint.yCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        notifyButtonsStack.snp.makeConstraints {
            $0.top.equalTo(notifyMeLabel.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(48 * Constraint.yCoeff)
        }

        // Save
        saveButton.snp.makeConstraints {
            $0.top.equalTo(notifyButtonsStack.snp.bottom).offset(24 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(56 * Constraint.yCoeff)
        }
        saveSyncLabel.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(36 * Constraint.yCoeff)
        }
    }

    // MARK: - Visit Type Pills

    private func makeVisitTypeRow(indices: ClosedRange<Int>) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10 * Constraint.xCoeff
        stack.distribution = .fillEqually
        for i in indices {
            guard i < visitTypes.count else { continue }
            let item = visitTypes[i]
            let btn = UIButton(type: .custom)
            btn.setTitle(item.title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
            btn.layer.cornerRadius = 20 * Constraint.yCoeff
            btn.layer.borderWidth = 1.5
            btn.tag = i
            btn.snp.makeConstraints { $0.height.equalTo(42 * Constraint.yCoeff) }
            btn.addTarget(self, action: #selector(visitTypeTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
        return stack
    }

    private func updateVisitTypePills() {
        let accentColor = UIColor(hexString: "#5ec89b")  // mint/green from screenshot
        let borderColor = UIColor(hexString: "#dddddd")

        for row in [visitTypeRow1, visitTypeRow2] {
            for case let btn as UIButton in row.arrangedSubviews {
                let type = visitTypes[btn.tag].type
                let isSelected = type == selectedVisitType
                btn.backgroundColor = isSelected ? accentColor.withAlphaComponent(0.18) : .white
                btn.layer.borderColor = (isSelected ? accentColor : borderColor).cgColor
                btn.setTitleColor(isSelected ? accentColor : UIColor(hexString: "#555555"), for: .normal)
            }
        }
    }

    @objc private func visitTypeTapped(_ sender: UIButton) {
        selectedVisitType = visitTypes[sender.tag].type
        updateVisitTypePills()
    }

    // MARK: - Date / Time containers

    private func makeDateTimeFieldContainer(label: UILabel, field: UITextField) -> UIView {
        let container = UIView()
        container.addSubview(label)
        container.addSubview(field)
        label.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        field.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(50 * Constraint.yCoeff)
        }
        return container
    }

    // MARK: - Notify buttons

    private func daysUntilVisitDate() -> Int {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        let visitDate = dateField.text.flatMap { df.date(from: $0) } ?? datePicker.date
        let today = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: visitDate)
        return Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
    }

    private func updateNotifyButtons() {
        let purple   = UIColor(hexString: "#8b6dc4")
        let disabled = UIColor(hexString: "#cccccc")
        let daysLeft = daysUntilVisitDate()

        for case let btn as UIButton in notifyButtonsStack.arrangedSubviews {
            let option     = btn.tag
            let isEligible = daysLeft >= option
            let isSelected = isEligible && selectedNotifyDays.contains(option)

            if !isEligible { selectedNotifyDays.remove(option) }

            btn.isEnabled = isEligible
            btn.backgroundColor   = isSelected ? purple : .white
            btn.layer.borderColor = (isEligible ? purple : disabled).cgColor
            btn.setTitleColor(isSelected ? .white : (isEligible ? purple : disabled), for: .normal)
            btn.alpha = isEligible ? 1.0 : 0.45
        }
    }

    @objc private func notifyDaysTapped(_ sender: UIButton) {
        let days = sender.tag
        if selectedNotifyDays.contains(days) { selectedNotifyDays.remove(days) }
        else { selectedNotifyDays.insert(days) }
        updateNotifyButtons()
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func calendarIconTapped() { dateField.becomeFirstResponder() }
    @objc private func clockIconTapped()    { timeField.becomeFirstResponder() }
    @objc private func locationIconTapped() { locationField.becomeFirstResponder() }

    @objc private func doneDate() {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        dateField.text = df.string(from: datePicker.date)
        view.endEditing(true)
        updateNotifyButtons()
    }

    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        dateField.text = df.string(from: sender.date)
        updateNotifyButtons()
    }

    @objc private func doneTime() {
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        timeField.text = df.string(from: timePicker.date)
        view.endEditing(true)
    }

    @objc private func timePickerChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        timeField.text = df.string(from: sender.date)
    }

    @objc private func saveTapped() {
        let doctor = doctorNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !doctor.isEmpty else {
            shake(doctorNameField)
            doctorNameField.layer.borderColor = UIColor.red.cgColor
            doctorNameField.layer.borderWidth = 1.5
            return
        }

        // Reset validation
        doctorNameField.layer.borderWidth = 0

        // Parse date
        let dateDf = DateFormatter(); dateDf.dateFormat = "dd/MM/yyyy"
        let visitDay = dateField.text.flatMap { dateDf.date(from: $0) } ?? Date()

        // Parse time
        let timeComps = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        var combined = Calendar.current.dateComponents([.year, .month, .day], from: visitDay)
        combined.hour   = timeComps.hour   ?? 10
        combined.minute = timeComps.minute ?? 30
        let visitDate = Calendar.current.date(from: combined) ?? visitDay

        let clinic = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes  = notesTextView.text == notesPlaceholder ? "" : (notesTextView.text ?? "")

        let visitTitle: String = {
            switch selectedVisitType {
            case "WELL-CHECK":  return "Well-check"
            case "SICK VISIT":  return "Sick visit"
            case "VACCINATION": return "Vaccination"
            case "SPECIALIST":  return "Specialist"
            default:            return "Visit"
            }
        }()

        let visit = DoctorVisit(
            doctorName: doctor,
            clinic: clinic,
            visitDate: visitDate,
            visitType: selectedVisitType,
            visitTitle: visitTitle,
            notes: notes
        )

        DoctorVisitStore.upsert(visit)
        if AuthStore.isLoggedIn { APIClient.upsertDoctorVisit(visit) { _ in } }
        scheduleNotifications(doctorName: doctor, visitDate: visitDate, notifyDays: selectedNotifyDays)

        dismiss(animated: true) { [weak self] in
            self?.onSave?()
        }
    }

    // MARK: - Notifications

    private func scheduleNotifications(doctorName: String, visitDate: Date, notifyDays: Set<Int>) {
        guard !notifyDays.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            for days in notifyDays {
                guard let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: visitDate),
                      fireDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Doctor Visit Reminder 🏥"
                content.body  = "Visit with \(doctorName) is in \(days == 1 ? "1 day" : "\(days) days"). Don't forget!"
                content.sound = .default

                var comps = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
                comps.hour   = 9
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "doctorvisit_\(doctorName)_minus\(days)d"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height + 20
        scrollView.verticalScrollIndicatorInsets.bottom = frame.height
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Helpers

    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.4
        anim.values = [-8, 8, -6, 6, -4, 4, 0]
        view.layer.add(anim, forKey: "shake")
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#444444")
        return l
    }

    private func makeTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor(hexString: "#f4f4f4")
        tf.layer.cornerRadius = 12 * Constraint.yCoeff
        tf.leftView  = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tf.textColor = .label
        return tf
    }

    private func makeCalendarIconButton() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "calendar"), for: .normal)
        btn.tintColor = UIColor(hexString: "#aaaaaa")
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 44)
        btn.addTarget(self, action: #selector(calendarIconTapped), for: .touchUpInside)
        container.addSubview(btn)
        return container
    }

    private func makeClockIconButton() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "clock"), for: .normal)
        btn.tintColor = UIColor(hexString: "#aaaaaa")
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 44)
        btn.addTarget(self, action: #selector(clockIconTapped), for: .touchUpInside)
        container.addSubview(btn)
        return container
    }

    private func makeLocationIconButton() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "mappin.and.ellipse"), for: .normal)
        btn.tintColor = UIColor(hexString: "#aaaaaa")
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 44)
        btn.addTarget(self, action: #selector(locationIconTapped), for: .touchUpInside)
        container.addSubview(btn)
        return container
    }
}

// MARK: - UITextViewDelegate

extension NewDoctorVisitViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == notesPlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = notesPlaceholder
            textView.textColor = UIColor(hexString: "#888888")
        }
    }
}

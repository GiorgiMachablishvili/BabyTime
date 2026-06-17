import UIKit
import SnapKit
import UserNotifications

// MARK: - NewVaccinationViewController

final class NewVaccinationViewController: UIViewController {

    var onSave: (() -> Void)?

    // MARK: - Age Groups

    private let ageGroups = [
        "Birth", "1-2 months", "2 months", "4 months",
        "6 months", "6-9 months", "9 months", "12 months",
        "12-15 months", "15 months", "18 months",
        "2 years", "4-6 years", "11-12 years", "16-18 years", "Adult"
    ]
    private var selectedAgeGroup = "6-9 months"
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
        l.text = "New Vaccination"
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
        l.text = "Add Vaccine Record"
        l.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        l.textAlignment = .center
        return l
    }()

    private lazy var headerSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Keep track of your little one's immunization\njourney for a healthy start."
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
    private lazy var vaccineNameLabel     = makeFieldLabel("Vaccine Name")
    private lazy var diseaseDetailsLabel  = makeFieldLabel("Disease Details")
    private lazy var adminDateLabel       = makeFieldLabel("Administration Date")
    private lazy var adminTimeLabel       = makeFieldLabel("Administration Time")
    private lazy var ageGroupLabel        = makeFieldLabel("Age Group")
    private lazy var providerLabel        = makeFieldLabel("Health Provider (Optional)")

    // Text fields
    private lazy var vaccineNameField     = makeTextField(placeholder: "e.g. MMR")
    private lazy var diseaseDetailsField  = makeTextField(placeholder: "e.g. Measles, Mumps, Rubella")

    private lazy var adminDateField: UITextField = {
        let tf = makeTextField(placeholder: "dd/mm/yyyy")
        tf.inputView = adminDatePicker
        let bar = UIToolbar(); bar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDate))
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        tf.inputAccessoryView = bar
        tf.rightView  = makeCalendarIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var adminDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(adminDateChanged(_:)), for: .valueChanged)
        return dp
    }()

    private lazy var adminTimeField: UITextField = {
        let tf = makeTextField(placeholder: "HH:MM AM")
        tf.inputView = adminTimePicker
        let bar = UIToolbar(); bar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTime))
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        tf.inputAccessoryView = bar
        tf.rightView = makeClockIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var adminTimePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.preferredDatePickerStyle = .wheels
        dp.addTarget(self, action: #selector(adminTimeChanged(_:)), for: .valueChanged)
        // Default to 10:30 AM
        var comps = DateComponents(); comps.hour = 10; comps.minute = 30
        if let d = Calendar.current.date(from: comps) { dp.date = d }
        return dp
    }()

    private lazy var ageGroupField: UITextField = {
        let tf = makeTextField(placeholder: "Select age group")
        tf.text = selectedAgeGroup
        tf.inputView = ageGroupPicker
        let bar = UIToolbar(); bar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAgeGroup))
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        tf.inputAccessoryView = bar
        tf.rightView  = makeAgeGroupIconButton()
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var ageGroupPicker: UIPickerView = {
        let p = UIPickerView()
        p.delegate   = self
        p.dataSource = self
        if let idx = ageGroups.firstIndex(of: selectedAgeGroup) {
            p.selectRow(idx, inComponent: 0, animated: false)
        }
        return p
    }()

    private lazy var providerField = makeTextField(placeholder: "e.g. Dr. Sarah Mitchell")


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

        let dateDf = DateFormatter(); dateDf.dateFormat = "dd/MM/yyyy"
        adminDateField.text = dateDf.string(from: Date())

        let timeDf = DateFormatter(); timeDf.dateFormat = "h:mm a"
        adminTimeField.text = timeDf.string(from: adminTimePicker.date)  // shows "10:30 AM"

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
        formCard.addSubview(vaccineNameLabel)
        formCard.addSubview(vaccineNameField)
        formCard.addSubview(diseaseDetailsLabel)
        formCard.addSubview(diseaseDetailsField)
        formCard.addSubview(adminDateLabel)
        formCard.addSubview(adminDateField)
        formCard.addSubview(adminTimeLabel)
        formCard.addSubview(adminTimeField)
        formCard.addSubview(ageGroupLabel)
        formCard.addSubview(ageGroupField)
        formCard.addSubview(providerLabel)
        formCard.addSubview(providerField)

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

        vaccineNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        vaccineNameField.snp.makeConstraints {
            $0.top.equalTo(vaccineNameLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        diseaseDetailsLabel.snp.makeConstraints {
            $0.top.equalTo(vaccineNameField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        diseaseDetailsField.snp.makeConstraints {
            $0.top.equalTo(diseaseDetailsLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        adminDateLabel.snp.makeConstraints {
            $0.top.equalTo(diseaseDetailsField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        adminDateField.snp.makeConstraints {
            $0.top.equalTo(adminDateLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        adminTimeLabel.snp.makeConstraints {
            $0.top.equalTo(adminDateField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        adminTimeField.snp.makeConstraints {
            $0.top.equalTo(adminTimeLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        ageGroupLabel.snp.makeConstraints {
            $0.top.equalTo(adminTimeField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        ageGroupField.snp.makeConstraints {
            $0.top.equalTo(ageGroupLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
        }

        providerLabel.snp.makeConstraints {
            $0.top.equalTo(ageGroupField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
        }
        providerField.snp.makeConstraints {
            $0.top.equalTo(providerLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(fPad)
            $0.height.equalTo(fieldH)
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

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func calendarIconTapped() {
        adminDateField.becomeFirstResponder()
    }

    @objc private func clockIconTapped() {
        adminTimeField.becomeFirstResponder()
    }

    @objc private func doneTime() {
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        adminTimeField.text = df.string(from: adminTimePicker.date)
        view.endEditing(true)
    }

    @objc private func adminTimeChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        adminTimeField.text = df.string(from: sender.date)
    }

    @objc private func ageGroupIconTapped() {
        ageGroupField.becomeFirstResponder()
    }

    @objc private func doneDate() {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        adminDateField.text = df.string(from: adminDatePicker.date)
        view.endEditing(true)
        updateNotifyButtons()
    }

    @objc private func adminDateChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        adminDateField.text = df.string(from: sender.date)
        updateNotifyButtons()
    }

    @objc private func doneAgeGroup() {
        view.endEditing(true)
    }

    @objc private func notifyDaysTapped(_ sender: UIButton) {
        let days = sender.tag
        if selectedNotifyDays.contains(days) {
            selectedNotifyDays.remove(days)
        } else {
            selectedNotifyDays.insert(days)
        }
        updateNotifyButtons()
    }

    private func daysUntilAdminDate() -> Int {
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
        let adminDate = adminDateField.text.flatMap { df.date(from: $0) } ?? adminDatePicker.date
        let today = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: adminDate)
        return Calendar.current.dateComponents([.day], from: today, to: target).day ?? 0
    }

    private func updateNotifyButtons() {
        let purple   = UIColor(hexString: "#8b6dc4")
        let disabled = UIColor(hexString: "#cccccc")
        let daysLeft = daysUntilAdminDate()

        for case let btn as UIButton in notifyButtonsStack.arrangedSubviews {
            let option    = btn.tag
            let isEligible = daysLeft >= option
            let isSelected = isEligible && selectedNotifyDays.contains(option)

            // If date changed and this option is no longer eligible, deselect it
            if !isEligible { selectedNotifyDays.remove(option) }

            btn.isEnabled = isEligible
            btn.backgroundColor   = isSelected ? purple : .white
            btn.layer.borderColor = (isEligible ? purple : disabled).cgColor
            btn.setTitleColor(isSelected ? .white : (isEligible ? purple : disabled), for: .normal)
            btn.alpha = isEligible ? 1.0 : 0.45
        }
    }

    @objc private func saveTapped() {
        let name = vaccineNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            vaccineNameField.layer.borderColor = UIColor.red.cgColor
            vaccineNameField.layer.borderWidth = 1.5
            return
        }

        let fullName = diseaseDetailsField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? name
        let ageRange = ageGroupField.text ?? selectedAgeGroup
        let doctor   = providerField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse admin date
        let dateDf = DateFormatter(); dateDf.dateFormat = "dd/MM/yyyy"
        let adminDate = adminDateField.text.flatMap { dateDf.date(from: $0) } ?? Date()

        // Extract hour & minute from time picker
        let timeComps = Calendar.current.dateComponents([.hour, .minute], from: adminTimePicker.date)
        let hour   = timeComps.hour   ?? 0
        let minute = timeComps.minute ?? 0

        // Combine date + time into a single Date for scheduledDate
        var combined = Calendar.current.dateComponents([.year, .month, .day], from: adminDate)
        combined.hour   = hour
        combined.minute = minute
        let scheduledDateTime = Calendar.current.date(from: combined) ?? adminDate

        let vaccine = Vaccine(
            name: name,
            fullName: fullName.isEmpty ? name : fullName,
            ageRange: ageRange,
            scheduledDate: scheduledDateTime,
            scheduledHour: hour,
            scheduledMinute: minute,
            doctorName: doctor.flatMap { $0.isEmpty ? nil : $0 }
        )

        VaccineStore.upsert(vaccine)
        if AuthStore.isLoggedIn { APIClient.upsertVaccine(vaccine) { _ in } }
        scheduleNotifications(vaccineName: name, adminDate: scheduledDateTime, notifyDays: selectedNotifyDays)
        dismiss(animated: true) { [weak self] in
            self?.onSave?()
        }
    }

    // MARK: - Notifications

    private func scheduleNotifications(vaccineName: String, adminDate: Date, notifyDays: Set<Int>) {
        guard !notifyDays.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            for days in notifyDays {
                // Calculate the notification fire date
                guard let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: adminDate),
                      fireDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Vaccination Reminder 💉"
                content.body  = "\(vaccineName) is due in \(days == 1 ? "1 day" : "\(days) days"). Don't forget to schedule!"
                content.sound = .default

                // Fire at 9 AM on the calculated date
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
                comps.hour   = 9
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "vaccine_\(vaccineName)_minus\(days)d"
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

    private func makeCalendarIconButton() -> UIView {
        // container gives the button 8pt trailing gap from the field edge
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "calendar"), for: .normal)
        btn.tintColor = UIColor(hexString: "#aaaaaa")
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 44)  // leaves 8pt trailing
        btn.addTarget(self, action: #selector(calendarIconTapped), for: .touchUpInside)
        container.addSubview(btn)
        return container
    }

    private func makeAgeGroupIconButton() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        btn.tintColor = UIColor(hexString: "#aaaaaa")
        btn.frame = CGRect(x: 0, y: 0, width: 36, height: 44)
        btn.addTarget(self, action: #selector(ageGroupIconTapped), for: .touchUpInside)
        container.addSubview(btn)
        return container
    }

    private func makeFieldIcon(_ systemName: String) -> UIView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = UIColor(hexString: "#aaaaaa")
        iv.contentMode = .scaleAspectFit
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 24))
        iv.frame = CGRect(x: 8, y: 0, width: 20, height: 24)
        container.addSubview(iv)
        return container
    }
}

// MARK: - UIPickerView

extension NewVaccinationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { ageGroups.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { ageGroups[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedAgeGroup = ageGroups[row]
        ageGroupField.text = selectedAgeGroup
    }
}


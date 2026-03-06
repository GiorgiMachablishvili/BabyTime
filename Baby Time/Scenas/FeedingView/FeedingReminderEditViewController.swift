import UIKit
import SnapKit

final class FeedingReminderEditViewController: UIViewController {

    var reminder: FeedingReminder?
    /// When adding a new reminder, use this day. If nil, use today.
    var forDate: Date?
    var onSave: ((FeedingReminder) -> Void)?
    var onDelete: ((UUID) -> Void)?

    private var selectedFeedingType: FeedingTypeView.FeedingType = .solid

    private lazy var feedingTypeView: FeedingTypeView = {
        let view = FeedingTypeView()
        return view
    }()

    private lazy var timePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.datePickerMode = .time
        view.preferredDatePickerStyle = .wheels
        return view
    }()

    private lazy var noteTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "e.g. Bottle 120 ml, oatmeal"
        view.borderStyle = .roundedRect
        view.font = .systemFont(ofSize: 16)
        return view
    }()

    private lazy var noteLabel: UILabel = {
        let view = UILabel()
        view.text = "Note / What to feed"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Save", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .feedingViewColor
        view.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var deleteButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Delete Reminder", for: .normal)
        view.setTitleColor(.systemRed, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .onDrag
        view.alwaysBounceVertical = true
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = reminder == nil ? "New Reminder" : "Edit Reminder"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        setupUI()
        setupConstraints()
        setupKeyboardAvoidance()
        feedingTypeView.onTypeChanged = { [weak self] type in
            self?.selectedFeedingType = type
        }
        if let r = reminder {
            var comps = DateComponents()
            comps.hour = r.hour
            comps.minute = r.minute
            timePicker.date = Calendar.current.date(from: comps) ?? Date()
            noteTextField.text = r.note
            deleteButton.isHidden = false
            let type: FeedingTypeView.FeedingType
            switch r.feedingType {
            case .breast: type = .breast
            case .bottle: type = .bottle
            case .formula: type = .formula
            case .solid: type = .solid
            }
            selectedFeedingType = type
            feedingTypeView.setSelectedType(type)
        } else {
            deleteButton.isHidden = true
            feedingTypeView.setSelectedType(.solid)
        }
        forDate = forDate ?? Date()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(feedingTypeView)
        contentView.addSubview(timePicker)
        contentView.addSubview(noteLabel)
        contentView.addSubview(noteTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(deleteButton)
        feedingTypeView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        feedingTypeView.snp.makeConstraints {
            $0.top.equalTo(contentView.snp.top).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
            $0.height.equalTo(98 * Constraint.xCoeff)
        }
        timePicker.snp.makeConstraints {
            $0.top.equalTo(feedingTypeView.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.yCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(timePicker.snp.bottom).offset(24 * Constraint.xCoeff)
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
            $0.bottom.equalTo(contentView.snp.bottom).offset(-24 * Constraint.xCoeff)
        }
    }

    private func setupKeyboardAvoidance() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = frame.height
        scrollView.contentInset.bottom = keyboardHeight
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let saveFrame = self.saveButton.convert(self.saveButton.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(saveFrame.insetBy(dx: 0, dy: -20), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let note = (noteTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let id = reminder?.id ?? UUID()
        let isEnabled = reminder?.isEnabled ?? true
        let day = reminder?.date ?? forDate ?? Date()
        let typeRaw: String
        switch selectedFeedingType {
        case .breast: typeRaw = "breast"
        case .bottle: typeRaw = "bottle"
        case .formula: typeRaw = "formula"
        case .solid: typeRaw = "solid"
        }
        let updated = FeedingReminder(id: id, date: day, hour: hour, minute: minute, note: note, isEnabled: isEnabled, feedingTypeRaw: typeRaw)
        onSave?(updated)
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        guard let id = reminder?.id else { return }
        onDelete?(id)
        dismiss(animated: true)
    }
}

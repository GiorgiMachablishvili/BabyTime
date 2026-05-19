import UIKit
import SnapKit

/// Bottom sheet for adding a doctor visit entry (date, time, note). Same as AddVaccinationView.
final class AddDoctorVisitView: UIView {

    var onTapCloseButton: (() -> Void)?
    /// (visitDate, hour, minute, note)
    var onTapSave: ((Date, Int, Int, String) -> Void)?

    private lazy var blurEffectView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.9)
        return view
    }()

    private lazy var sheetView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .onDrag
        view.alwaysBounceVertical = true
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Add Doctor Visit"
        view.font = .systemFont(ofSize: 20, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var closeButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        view.tintColor = .label
        view.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return view
    }()

    private lazy var datePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.datePickerMode = .date
        view.preferredDatePickerStyle = .compact
        return view
    }()

    private lazy var dateLabel: UILabel = {
        let view = UILabel()
        view.text = "Date"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var timePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.datePickerMode = .time
        view.preferredDatePickerStyle = .wheels
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.text = "Time"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var noteLabel: UILabel = {
        let view = UILabel()
        view.text = "Note / Reason"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var noteTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "e.g. Routine checkup, follow-up"
        view.borderStyle = .roundedRect
        view.font = .systemFont(ofSize: 16)
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Save", for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        view.setTitleColor(.labelWhiteColor, for: .normal)
        view.backgroundColor = .pressButtonColor
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
        setupConstraints()
        setupKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        addSubview(blurEffectView)
        addSubview(sheetView)
        sheetView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(dateLabel)
        contentView.addSubview(datePicker)
        contentView.addSubview(timeLabel)
        contentView.addSubview(timePicker)
        contentView.addSubview(noteLabel)
        contentView.addSubview(noteTextField)
        contentView.addSubview(saveButton)
    }

    private func setupConstraints() {
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        sheetView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(520 * Constraint.xCoeff)
        }
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(sheetView)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(contentView).inset(16 * Constraint.xCoeff)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(10 * Constraint.xCoeff)
            make.trailing.equalTo(contentView).offset(-10 * Constraint.yCoeff)
            make.height.width.equalTo(44 * Constraint.xCoeff)
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalTo(contentView).offset(20)
        }
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(contentView).inset(20)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(16)
            make.leading.equalTo(contentView).offset(20)
        }
        timePicker.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(contentView).inset(20)
            make.height.equalTo(120)
        }
        noteLabel.snp.makeConstraints { make in
            make.top.equalTo(timePicker.snp.bottom).offset(16)
            make.leading.equalTo(contentView).offset(20)
        }
        noteTextField.snp.makeConstraints { make in
            make.top.equalTo(noteLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(contentView).inset(20)
            make.height.equalTo(44)
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(noteTextField.snp.bottom).offset(24)
            make.leading.trailing.equalTo(contentView).inset(30)
            make.height.equalTo(50)
            make.bottom.equalTo(contentView).offset(-24)
        }
    }

    private func setupKeyboardObservers() {
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
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let noteFrame = self.noteTextField.convert(self.noteTextField.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(noteFrame.insetBy(dx: 0, dy: -20), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
    }

    @objc private func closeTapped() {
        onTapCloseButton?()
    }

    @objc private func saveTapped() {
        let visitDate = Calendar.current.startOfDay(for: datePicker.date)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let note = (noteTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        onTapSave?(visitDate, hour, minute, note)
        onTapCloseButton?()
    }
}

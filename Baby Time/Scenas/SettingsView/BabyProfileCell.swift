import UIKit
import SnapKit

final class BabyProfileCell: UICollectionViewCell {

    static let reuseId = "BabyProfileCell"

    enum Gender: String {
        case boy = "Boy"
        case girl = "Girl"
        case other = "Other"
    }

    var onTapSave: ((_ name: String?, _ birthday: String?, _ gender: String) -> Void)?
    var onTapProfilePhoto: (() -> Void)?

    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

    private lazy var iconCircle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        view.clipsToBounds = true
        view.makeRoundCorners(30)
        return view
    }()

    private lazy var iconImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UIColor.systemOrange.withAlphaComponent(0.7)
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var plusButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.tintColor = .white
        view.backgroundColor = UIColor.systemTeal
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 20, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()

    private let nameTitleLabel = BabyProfileCell.makeFieldTitle("Baby's Name")
    private let birthdayTitleLabel = BabyProfileCell.makeFieldTitle("Birthday")
    private let genderTitleLabel = BabyProfileCell.makeFieldTitle("Gender")

    private let nameTextField = BabyProfileCell.makeTextField(placeholder: "Enter name")
    private let birthdayTextField = BabyProfileCell.makeTextField(placeholder: "dd.mm.yyyy")

    private lazy var calendarButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "calendar"), for: .normal)
        view.tintColor = UIColor.label.withAlphaComponent(0.6)
        return view
    }()

    private let boyButton = GenderButton(title: "Boy")
    private let girlButton = GenderButton(title: "Girl")
    private let otherButton = GenderButton(title: "Other")

    private lazy var genderStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [boyButton, girlButton, otherButton])
        view.axis = .horizontal
        view.spacing = 12
        view.distribution = .fillEqually
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Save Profile", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.7)
        view.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private var selectedGender: Gender = .other {
        didSet { updateGenderUI() }
    }

    private lazy var datePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.datePickerMode = .date
        view.preferredDatePickerStyle = .wheels
        view.maximumDate = Date()
        return view
    }()

    private lazy var birthdayFormatter: DateFormatter = {
        let view = DateFormatter()
        view.dateFormat = "dd.MM.yyyy"
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
        selectedGender = .other
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//        let r = min(iconCircle.bounds.width, iconCircle.bounds.height) / 2
//        iconCircle.layer.cornerRadius = r
//        iconImage.layer.cornerRadius = r
//        iconImage.clipsToBounds = true
//        plusButton.layer.cornerRadius = plusButton.bounds.height / 2
//    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameTextField.text = nil
        birthdayTextField.text = nil
    }

    func configure(title: String, icon: UIImage?, profileImage: UIImage? = nil, nameText: String? = nil, birthdayText: String? = nil, genderText: String? = nil) {
        titleLabel.text = title
        if let profileImage = profileImage {
            iconImage.image = profileImage
            iconImage.contentMode = .scaleAspectFill
            iconImage.tintColor = nil
        } else {
            iconImage.image = icon
            iconImage.contentMode = .scaleAspectFit
            iconImage.tintColor = UIColor.systemOrange.withAlphaComponent(0.7)
        }

        nameTextField.text = nameText
        birthdayTextField.text = birthdayText
        if let g = genderText, let gender = Gender(rawValue: g) {
            selectedGender = gender
        }
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(container)

        container.addSubview(iconCircle)
        iconCircle.addSubview(iconImage)
        container.addSubview(plusButton)

        container.addSubview(titleLabel)

        container.addSubview(nameTitleLabel)
        container.addSubview(nameTextField)

        container.addSubview(birthdayTitleLabel)
        container.addSubview(birthdayTextField)
        birthdayTextField.addSubview(calendarButton)
        
        container.addSubview(genderTitleLabel)
        container.addSubview(genderStack)

        container.addSubview(saveButton)
        
        // Configure birthday date picker input
        birthdayTextField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancelDate))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDoneDate))
        toolbar.items = [cancel, flexible, done]
        birthdayTextField.inputAccessoryView = toolbar
    }

    private func setupConstraints() {
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconCircle.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(18 * Constraint.yCoeff)
            $0.width.equalTo(60 * Constraint.yCoeff)
            $0.height.equalTo(60 * Constraint.xCoeff)
        }

        iconImage.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        plusButton.snp.makeConstraints {
            $0.trailing.equalTo(iconCircle.snp.trailing).offset(4 * Constraint.yCoeff)
            $0.bottom.equalTo(iconCircle.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.width.equalTo(30 * Constraint.yCoeff)
            $0.height.equalTo(30 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconCircle)
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12 * Constraint.yCoeff)
            $0.trailing.equalToSuperview().offset(-16 * Constraint.yCoeff)
        }

        nameTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
            $0.height.equalTo(48 * Constraint.xCoeff)
        }

        birthdayTitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
        }

        birthdayTextField.snp.makeConstraints {
            $0.top.equalTo(birthdayTitleLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
            $0.height.equalTo(48 * Constraint.xCoeff)
        }

        calendarButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-14 * Constraint.yCoeff)
            $0.width.equalTo(22 * Constraint.yCoeff)
            $0.height.equalTo(22 * Constraint.xCoeff)
        }

        genderTitleLabel.snp.makeConstraints {
            $0.top.equalTo(birthdayTextField.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
        }

        genderStack.snp.makeConstraints {
            $0.top.equalTo(genderTitleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
            $0.height.equalTo(44 * Constraint.xCoeff)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(genderStack.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(18 * Constraint.yCoeff)
            $0.height.equalTo(54 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().offset(-18 * Constraint.xCoeff)
        }
    }

    private func setupActions() {
        boyButton.onTap = { [weak self] in self?.selectedGender = .boy }
        girlButton.onTap = { [weak self] in self?.selectedGender = .girl }
        otherButton.onTap = { [weak self] in self?.selectedGender = .other }

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        plusButton.addTarget(self, action: #selector(profilePhotoTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(profilePhotoTapped))
        iconCircle.addGestureRecognizer(tap)
        iconCircle.isUserInteractionEnabled = true
    }

    @objc private func profilePhotoTapped() {
        onTapProfilePhoto?()
    }

    private func updateGenderUI() {
        boyButton.setSelected(selectedGender == .boy, selectedColor: UIColor.systemOrange.withAlphaComponent(0.7))
        girlButton.setSelected(selectedGender == .girl, selectedColor: UIColor.systemOrange.withAlphaComponent(0.7))
        otherButton.setSelected(selectedGender == .other, selectedColor: UIColor.systemOrange.withAlphaComponent(0.7))
    }

    @objc private func saveTapped() {
        onTapSave?(nameTextField.text, birthdayTextField.text, selectedGender.rawValue)
    }

    @objc private func calendarTapped() {
        // Show the date picker by focusing the text field
        birthdayTextField.becomeFirstResponder()
        // Initialize text with current picker date if empty
        if (birthdayTextField.text ?? "").isEmpty {
            birthdayTextField.text = birthdayFormatter.string(from: datePicker.date)
        }
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        birthdayTextField.text = birthdayFormatter.string(from: sender.date)
    }

    @objc private func didTapCancelDate() {
        birthdayTextField.resignFirstResponder()
    }

    @objc private func didTapDoneDate() {
        // Ensure text reflects the current picker date
        birthdayTextField.text = birthdayFormatter.string(from: datePicker.date)
        birthdayTextField.resignFirstResponder()
    }

    // Helpers
    private static func makeFieldTitle(_ text: String) -> UILabel {
        let view = UILabel()
        view.text = text
        view.font = .systemFont(ofSize: 13, weight: .semibold)
        view.textColor = UIColor.secondaryLabel
        return view
    }

    private static func makeTextField(placeholder: String) -> UITextField {
        let view = UITextField()
        view.placeholder = placeholder
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 12
        view.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        view.leftViewMode = .always
        view.textColor = .label
        return view
    }
}


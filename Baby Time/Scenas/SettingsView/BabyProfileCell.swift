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

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        return v
    }()

    private let iconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        v.layer.cornerRadius = 18
        v.clipsToBounds = true
        return v
    }()

    private let iconImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.systemOrange.withAlphaComponent(0.7)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor.label.withAlphaComponent(0.85)
        return l
    }()

    private let nameTitleLabel = BabyProfileCell.makeFieldTitle("Baby's Name")
    private let birthdayTitleLabel = BabyProfileCell.makeFieldTitle("Birthday")
    private let genderTitleLabel = BabyProfileCell.makeFieldTitle("Gender")

    private let nameTextField = BabyProfileCell.makeTextField(placeholder: "Enter name")
    private let birthdayTextField = BabyProfileCell.makeTextField(placeholder: "dd.mm.yyyy")

    private let calendarButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "calendar"), for: .normal)
        b.tintColor = UIColor.label.withAlphaComponent(0.6)
        return b
    }()

    private let boyButton = GenderButton(title: "Boy")
    private let girlButton = GenderButton(title: "Girl")
    private let otherButton = GenderButton(title: "Other")

    private lazy var genderStack: UIStackView = {
        let st = UIStackView(arrangedSubviews: [boyButton, girlButton, otherButton])
        st.axis = .horizontal
        st.spacing = 12
        st.distribution = .fillEqually
        return st
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save Profile", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.7)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.layer.cornerRadius = 18
        b.clipsToBounds = true
        return b
    }()

    private var selectedGender: Gender = .other {
        didSet { updateGenderUI() }
    }

    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.maximumDate = Date()
        return dp
    }()

    private let birthdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df
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

    override func prepareForReuse() {
        super.prepareForReuse()
        nameTextField.text = nil
        birthdayTextField.text = nil
    }

    func configure(title: String, icon: UIImage?) {
        titleLabel.text = title
        iconImage.image = icon
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(container)

        container.addSubview(iconCircle)
        iconCircle.addSubview(iconImage)

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
            $0.top.leading.equalToSuperview().offset(18)
            $0.size.equalTo(36)
        }

        iconImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconCircle)
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
        }

        nameTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(18)
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(48)
        }

        birthdayTitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(18)
        }

        birthdayTextField.snp.makeConstraints {
            $0.top.equalTo(birthdayTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(48)
        }

        calendarButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-14)
            $0.size.equalTo(22)
        }

        genderTitleLabel.snp.makeConstraints {
            $0.top.equalTo(birthdayTextField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(18)
        }

        genderStack.snp.makeConstraints {
            $0.top.equalTo(genderTitleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(44)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(genderStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(54)
            $0.bottom.equalToSuperview().offset(-18)
        }
    }

    private func setupActions() {
        boyButton.onTap = { [weak self] in self?.selectedGender = .boy }
        girlButton.onTap = { [weak self] in self?.selectedGender = .girl }
        otherButton.onTap = { [weak self] in self?.selectedGender = .other }

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
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
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = UIColor.secondaryLabel
        return l
    }

    private static func makeTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor.systemGray6
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.textColor = .label
        return tf
    }
}

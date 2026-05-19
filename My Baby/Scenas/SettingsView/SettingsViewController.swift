import UIKit
import SnapKit

final class SettingsViewController: UIViewController {

    // MARK: - State

    private var profileImage: UIImage?
    private var profileName: String?
    private var profileBirthday: Date?
    private var profileGender: String = "Other"
    private var selectedGender: Gender = .other { didSet { updateGenderButtons() } }

    private enum Gender: String {
        case boy = "Boy", girl = "Girl", other = "Other"
    }

    // MARK: - Header

    private lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        return v
    }()

    private lazy var avatarButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#c5d8dc")
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 20 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        return b
    }()

    private lazy var headerTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "BabyTime"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .label
        return l
    }()

    private lazy var gearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "gearshape"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        return b
    }()

    // MARK: - Scroll

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .onDrag
        return s
    }()

    private lazy var contentView = UIView()

    // MARK: - Profile card

    private lazy var profileSectionLabel = makeSectionTitle("BABY PROFILE")

    private lazy var profileCard: UIView = makeCard()

    private lazy var profilePhotoButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#c5d8dc")
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 40 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        return b
    }()

    private lazy var cameraOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.layer.cornerRadius = 40 * Constraint.yCoeff
        v.clipsToBounds = true
        v.isUserInteractionEnabled = false
        let img = UIImageView(image: UIImage(systemName: "camera.fill"))
        img.tintColor = .white
        img.contentMode = .scaleAspectFit
        v.addSubview(img)
        img.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        return v
    }()

    private lazy var nameLabel = makeFieldLabel("Baby's Name")
    private lazy var nameTextField = makeTextField(placeholder: "Enter name")

    private lazy var birthdayLabel = makeFieldLabel("Birthday")
    private lazy var birthdayTextField: UITextField = {
        let tf = makeTextField(placeholder: "dd.mm.yyyy")
        tf.inputView = datePicker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDate))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDate))
        toolbar.items = [cancel, flex, done]
        tf.inputAccessoryView = toolbar
        let calIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calIcon.tintColor = .secondaryLabel
        calIcon.contentMode = .scaleAspectFit
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        calIcon.frame = CGRect(x: 6, y: 0, width: 22, height: 24)
        container.addSubview(calIcon)
        tf.rightView = container
        tf.rightViewMode = .always
        return tf
    }()

    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.maximumDate = Date()
        dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        return dp
    }()

    private lazy var genderLabel = makeFieldLabel("Gender")

    private lazy var boyButton = GenderButton(title: "Boy")
    private lazy var girlButton = GenderButton(title: "Girl")
    private lazy var otherButton = GenderButton(title: "Other")

    private lazy var genderStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [boyButton, girlButton, otherButton])
        s.axis = .horizontal
        s.spacing = 10
        s.distribution = .fillEqually
        return s
    }()

    private lazy var saveProfileButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save Profile", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#6c5fcd")
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        return b
    }()

    private lazy var profileSavedLabel: UILabel = {
        let l = UILabel()
        l.text = "⊙ Profile saved"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Preferences section

    private lazy var prefSectionLabel = makeSectionTitle("PREFERENCES")

    private lazy var notificationsRow = makeSettingsRow(icon: "bell", title: "Notifications", subtitle: "Coming soon")
    private lazy var exportRow = makeSettingsRow(icon: "square.and.arrow.up", title: "Export Data", subtitle: "Coming soon")
    private lazy var darkModeRow = makeSettingsRow(icon: "moon", title: "Dark Mode", subtitle: "Coming soon")

    // MARK: - Danger zone

    private lazy var deleteAccountButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Account", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#e53935")
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadProfile()
        setupUI()
        setupConstraints()
        setupGenderButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadProfile()
        refreshProfileUI()
    }

    // MARK: - Load

    private func loadProfile() {
        profileImage   = BabyProfileStore.loadPhoto()
        profileName    = BabyProfileStore.loadName()
        profileBirthday = BabyProfileStore.loadBirthday()
        profileGender  = BabyProfileStore.loadGender() ?? "Other"
        selectedGender = Gender(rawValue: profileGender) ?? .other
    }

    private func refreshProfileUI() {
        if let img = profileImage {
            profilePhotoButton.setBackgroundImage(img, for: .normal)
            profilePhotoButton.setImage(nil, for: .normal)
            profilePhotoButton.contentHorizontalAlignment = .fill
            profilePhotoButton.contentVerticalAlignment = .fill
            avatarButton.setBackgroundImage(img, for: .normal)
            avatarButton.setImage(nil, for: .normal)
            avatarButton.contentHorizontalAlignment = .fill
            avatarButton.contentVerticalAlignment = .fill
        }
        nameTextField.text = profileName
        if let bday = profileBirthday {
            let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
            birthdayTextField.text = df.string(from: bday)
        }
        selectedGender = Gender(rawValue: profileGender) ?? .other
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(avatarButton)
        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(gearButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(profileSectionLabel)
        contentView.addSubview(profileCard)

        profileCard.addSubview(profilePhotoButton)
        profileCard.addSubview(cameraOverlay)
        profileCard.addSubview(nameLabel)
        profileCard.addSubview(nameTextField)
        profileCard.addSubview(birthdayLabel)
        profileCard.addSubview(birthdayTextField)
        profileCard.addSubview(genderLabel)
        profileCard.addSubview(genderStack)
        profileCard.addSubview(saveProfileButton)
        profileCard.addSubview(profileSavedLabel)

        contentView.addSubview(prefSectionLabel)
        contentView.addSubview(notificationsRow)
        contentView.addSubview(exportRow)
        contentView.addSubview(darkModeRow)
        contentView.addSubview(deleteAccountButton)
    }

    private func setupConstraints() {
        let hPad = 16 * Constraint.xCoeff

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        avatarButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(hPad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        headerTitleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        gearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(hPad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Profile section
        profileSectionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        profileCard.snp.makeConstraints {
            $0.top.equalTo(profileSectionLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        profilePhotoButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(80 * Constraint.yCoeff)
        }
        cameraOverlay.snp.makeConstraints {
            $0.edges.equalTo(profilePhotoButton)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(profilePhotoButton.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(46 * Constraint.yCoeff)
        }
        birthdayLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        birthdayTextField.snp.makeConstraints {
            $0.top.equalTo(birthdayLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(46 * Constraint.yCoeff)
        }
        genderLabel.snp.makeConstraints {
            $0.top.equalTo(birthdayTextField.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        genderStack.snp.makeConstraints {
            $0.top.equalTo(genderLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(42 * Constraint.yCoeff)
        }
        saveProfileButton.snp.makeConstraints {
            $0.top.equalTo(genderStack.snp.bottom).offset(18 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(50 * Constraint.yCoeff)
        }
        profileSavedLabel.snp.makeConstraints {
            $0.top.equalTo(saveProfileButton.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16 * Constraint.xCoeff)
        }

        // Preferences section
        prefSectionLabel.snp.makeConstraints {
            $0.top.equalTo(profileCard.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        notificationsRow.snp.makeConstraints {
            $0.top.equalTo(prefSectionLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        exportRow.snp.makeConstraints {
            $0.top.equalTo(notificationsRow.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        darkModeRow.snp.makeConstraints {
            $0.top.equalTo(exportRow.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        deleteAccountButton.snp.makeConstraints {
            $0.top.equalTo(darkModeRow.snp.bottom).offset(32 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(50 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(32 * Constraint.xCoeff)
        }
    }

    private func setupGenderButtons() {
        boyButton.onTap   = { [weak self] in self?.selectedGender = .boy }
        girlButton.onTap  = { [weak self] in self?.selectedGender = .girl }
        otherButton.onTap = { [weak self] in self?.selectedGender = .other }
        updateGenderButtons()
    }

    private func updateGenderButtons() {
        let purple = UIColor(hexString: "#6c5fcd")
        boyButton.setSelected(selectedGender == .boy,   selectedColor: purple)
        girlButton.setSelected(selectedGender == .girl,  selectedColor: purple)
        otherButton.setSelected(selectedGender == .other, selectedColor: purple)
    }

    // MARK: - Actions

    @objc private func avatarTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.openPicker(sourceType: .camera)
        })
        alert.addAction(UIAlertAction(title: "Use Gallery", style: .default) { [weak self] _ in
            self?.openPicker(sourceType: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    private func openPicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveProfile() {
        let name = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        profileName = name.isEmpty ? nil : name
        profileGender = selectedGender.rawValue
        BabyProfileStore.saveName(profileName)
        BabyProfileStore.saveBirthday(profileBirthday)
        BabyProfileStore.saveGender(profileGender)
        view.endEditing(true)
        showSaved()
    }

    private func showSaved() {
        profileSavedLabel.isHidden = false
        profileSavedLabel.alpha = 0
        UIView.animate(withDuration: 0.3) { self.profileSavedLabel.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.3) { self.profileSavedLabel.alpha = 0 } completion: { _ in
                self.profileSavedLabel.isHidden = true
            }
        }
    }

    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This will permanently delete all your baby data. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        present(alert, animated: true)
    }

    private func performDeleteAccount() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        UserDefaults.standard.synchronize()

        guard let windowScene = view.window?.windowScene else { return }
        let welcome = WelcomeViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = welcome
        window.makeKeyAndVisible()
        if let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.window = window
        }
    }

    @objc private func cancelDate() { birthdayTextField.resignFirstResponder() }

    @objc private func doneDate() {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        birthdayTextField.text = df.string(from: datePicker.date)
        profileBirthday = datePicker.date
        birthdayTextField.resignFirstResponder()
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        birthdayTextField.text = df.string(from: sender.date)
        profileBirthday = sender.date
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 6
        return v
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tf.layer.cornerRadius = 10
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .label
        return tf
    }

    private func makeSettingsRow(icon: String, title: String, subtitle: String) -> UIView {
        let card = makeCard()

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(white: 0.94, alpha: 1)
        iconBg.layer.cornerRadius = 10
        card.addSubview(iconBg)

        let iconImg = UIImageView(image: UIImage(systemName: icon))
        iconImg.tintColor = .secondaryLabel
        iconImg.contentMode = .scaleAspectFit
        iconBg.addSubview(iconImg)

        let titleL = UILabel()
        titleL.text = title
        titleL.font = .systemFont(ofSize: 15, weight: .semibold)
        titleL.textColor = .label
        card.addSubview(titleL)

        let subL = UILabel()
        subL.text = subtitle
        subL.font = .systemFont(ofSize: 12)
        subL.textColor = .secondaryLabel
        card.addSubview(subL)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 0.75, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        card.addSubview(chevron)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(38 * Constraint.yCoeff)
        }
        iconImg.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8 * Constraint.xCoeff)
            $0.height.equalTo(14 * Constraint.yCoeff)
        }
        titleL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12 * Constraint.xCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }
        subL.snp.makeConstraints {
            $0.top.equalTo(titleL.snp.bottom).offset(2 * Constraint.xCoeff)
            $0.leading.equalTo(titleL)
        }

        return card
    }
}

// MARK: - Image picker

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        profileImage = image
        BabyProfileStore.savePhoto(image)

        profilePhotoButton.setBackgroundImage(image, for: .normal)
        profilePhotoButton.setImage(nil, for: .normal)
        profilePhotoButton.contentHorizontalAlignment = .fill
        profilePhotoButton.contentVerticalAlignment = .fill

        avatarButton.setBackgroundImage(image, for: .normal)
        avatarButton.setImage(nil, for: .normal)
        avatarButton.contentHorizontalAlignment = .fill
        avatarButton.contentVerticalAlignment = .fill
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

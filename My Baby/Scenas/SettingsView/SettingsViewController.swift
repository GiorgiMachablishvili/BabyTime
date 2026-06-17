import UIKit
import SnapKit

final class SettingsViewController: UIViewController {

    // MARK: - State

    private var profiles: [BabyProfile] = []
    private var selectedIndex: Int = 0
    private var selectedGender: Gender = .other { didSet { updateGenderButtons() } }

    private enum Gender: String {
        case boy = "Boy", girl = "Girl", other = "Other"
    }

    // MARK: - Top header

    private lazy var pageTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "BABY PROFILE"
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        return l
    }()

    // MARK: - Profile switcher

    private lazy var switcherScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceHorizontal = true
        return s
    }()

    private lazy var switcherStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 20 * Constraint.xCoeff
        s.alignment = .top
        return s
    }()

    // MARK: - Scroll / content

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .onDrag
        return s
    }()

    private lazy var contentView = UIView()

    // MARK: - Profile card

    private lazy var profileCard: UIView = makeCard()

    private lazy var profilePhotoButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#c5d8dc")
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 45 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        return b
    }()

    private lazy var cameraButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#6c5fcd")
        b.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        return b
    }()

    private lazy var nameLabel = makeFieldLabel("Baby's Name")
    private lazy var nameTextField = makeTextField(placeholder: "Enter name")

    private lazy var birthdayLabel = makeFieldLabel("Birthday")
    private lazy var birthdayTextField: UITextField = {
        let tf = makeTextField(placeholder: "dd.mm.yyyy")
        tf.inputView = datePicker
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDate))
        let flex   = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done   = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDate))
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

    private lazy var boyButton   = GenderButton(title: "Boy")
    private lazy var girlButton  = GenderButton(title: "Girl")
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
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#6c5fcd")
        b.layer.cornerRadius = 26 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        return b
    }()

    private lazy var profileSavedLabel: UILabel = {
        let l = UILabel()
        l.text = "✓ Profile saved"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Preferences

    private lazy var prefSectionLabel = makeSectionTitle("PREFERENCES")
    private lazy var notificationsRow = makeSettingsRow(icon: "bell",                title: "Notifications", subtitle: "Coming soon")
    private lazy var exportRow        = makeSettingsRow(icon: "square.and.arrow.up", title: "Export Data",    subtitle: "Coming soon")
    private lazy var darkModeRow      = makeDarkModeRow()

    // MARK: - Delete

    private lazy var deleteChildButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Child Profile", for: .normal)
        b.setTitleColor(UIColor(hexString: "#e53935"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = .clear
        b.layer.cornerRadius = 16 * Constraint.yCoeff
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor(hexString: "#e53935").cgColor
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(deleteChildTapped), for: .touchUpInside)
        return b
    }()

    private lazy var legalLinksView: UIView = makeLegalLinksView()

    private lazy var deleteAccountButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Delete Account", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#e53935")
        b.layer.cornerRadius = 16 * Constraint.yCoeff
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupConstraints()
        setupGenderButtons()
        loadAndRefresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadAndRefresh()
    }

    // MARK: - Load

    private func loadAndRefresh() {
        profiles = BabyProfileStore.loadProfiles()
        selectedIndex = BabyProfileStore.selectedIndex()
        rebuildSwitcher()
        fillForm(from: currentProfile())
    }

    private func currentProfile() -> BabyProfile? {
        guard selectedIndex < profiles.count else { return profiles.first }
        return profiles[selectedIndex]
    }

    // MARK: - Profile switcher

    private func rebuildSwitcher() {
        switcherStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (i, profile) in profiles.enumerated() {
            let item = makeProfileSwitcherItem(profile: profile, index: i, isSelected: i == selectedIndex)
            switcherStack.addArrangedSubview(item)
        }

        // "Add New" button
        let addItem = makeAddNewItem()
        switcherStack.addArrangedSubview(addItem)
    }

    private func makeProfileSwitcherItem(profile: BabyProfile, index: Int, isSelected: Bool) -> UIView {
        let container = UIView()
        container.tag = index

        let ring = UIView()
        ring.layer.cornerRadius = 32 * Constraint.yCoeff
        ring.layer.borderWidth  = isSelected ? 2.5 : 0
        ring.layer.borderColor  = UIColor(hexString: "#6c5fcd").cgColor
        ring.clipsToBounds = false

        let avatarBtn = UIButton(type: .custom)
        avatarBtn.layer.cornerRadius = 30 * Constraint.yCoeff
        avatarBtn.clipsToBounds = true
        avatarBtn.backgroundColor = UIColor(hexString: "#c5d8dc")
        avatarBtn.setImage(UIImage(systemName: "person.fill"), for: .normal)
        avatarBtn.tintColor = .white
        avatarBtn.tag = index
        avatarBtn.addTarget(self, action: #selector(switcherTapped(_:)), for: .touchUpInside)

        if let photo = profile.photo {
            avatarBtn.setBackgroundImage(photo, for: .normal)
            avatarBtn.setImage(nil, for: .normal)
            avatarBtn.contentHorizontalAlignment = .fill
            avatarBtn.contentVerticalAlignment   = .fill
        }

        let nameL = UILabel()
        nameL.text = profile.name.isEmpty ? "Baby" : profile.name
        nameL.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: isSelected ? .semibold : .regular)
        nameL.textColor = isSelected ? UIColor(hexString: "#6c5fcd") : UIColor(hexString: "#888888")
        nameL.textAlignment = .center

        ring.addSubview(avatarBtn)
        container.addSubview(ring)
        container.addSubview(nameL)

        let itemWidth = 72 * Constraint.xCoeff
        container.snp.makeConstraints { $0.width.equalTo(itemWidth) }

        avatarBtn.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(60 * Constraint.yCoeff) }
        ring.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(64 * Constraint.yCoeff)
        }
        nameL.snp.makeConstraints {
            $0.top.equalTo(ring.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        return container
    }

    private func makeAddNewItem() -> UIView {
        let container = UIView()

        let circle = UIView()
        circle.layer.cornerRadius = 30 * Constraint.yCoeff
        circle.layer.borderWidth  = 1.5
        circle.layer.borderColor  = UIColor(hexString: "#cccccc").cgColor
        circle.backgroundColor    = .clear

        // Dashed border via CAShapeLayer
        let dash = CAShapeLayer()
        dash.strokeColor   = UIColor(hexString: "#bbbbbb").cgColor
        dash.fillColor     = UIColor.clear.cgColor
        dash.lineWidth     = 1.5
        dash.lineDashPattern = [6, 4]
        circle.layer.borderWidth = 0  // use dash layer instead
        circle.layer.addSublayer(dash)

        let plusLabel = UILabel()
        plusLabel.text = "+"
        plusLabel.font = .systemFont(ofSize: 24 * Constraint.yCoeff, weight: .light)
        plusLabel.textColor = UIColor(hexString: "#bbbbbb")
        plusLabel.textAlignment = .center

        let addLabel = UILabel()
        addLabel.text = "Add New"
        addLabel.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        addLabel.textColor = UIColor(hexString: "#888888")
        addLabel.textAlignment = .center

        let tapBtn = UIButton(type: .system)
        tapBtn.addTarget(self, action: #selector(addNewProfile), for: .touchUpInside)

        circle.addSubview(plusLabel)
        container.addSubview(circle)
        container.addSubview(addLabel)
        container.addSubview(tapBtn)

        let itemWidth = 72 * Constraint.xCoeff
        container.snp.makeConstraints { $0.width.equalTo(itemWidth) }

        plusLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        circle.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(60 * Constraint.yCoeff)
        }
        addLabel.snp.makeConstraints {
            $0.top.equalTo(circle.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        tapBtn.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Draw dashed circle after layout
        DispatchQueue.main.async {
            let radius = 30 * Constraint.yCoeff
            let size   = 60 * Constraint.yCoeff
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: radius)
            dash.path   = path.cgPath
            dash.frame  = CGRect(x: 0, y: 0, width: size, height: size)
        }

        return container
    }

    // MARK: - Form

    private func fillForm(from profile: BabyProfile?) {
        guard let profile else { return }
        if let photo = profile.photo {
            profilePhotoButton.setBackgroundImage(photo, for: .normal)
            profilePhotoButton.setImage(nil, for: .normal)
            profilePhotoButton.contentHorizontalAlignment = .fill
            profilePhotoButton.contentVerticalAlignment   = .fill
        } else {
            profilePhotoButton.setBackgroundImage(nil, for: .normal)
            profilePhotoButton.setImage(UIImage(systemName: "person.fill"), for: .normal)
        }
        nameTextField.text = profile.name.isEmpty ? nil : profile.name
        if let bday = profile.birthday {
            let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
            birthdayTextField.text = df.string(from: bday)
            datePicker.date = bday
        } else {
            birthdayTextField.text = nil
        }
        selectedGender = Gender(rawValue: profile.gender) ?? .other
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(pageTitleLabel)
        view.addSubview(switcherScrollView)
        switcherScrollView.addSubview(switcherStack)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(profileCard)
        profileCard.addSubview(profilePhotoButton)
        profileCard.addSubview(cameraButton)
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
        contentView.addSubview(deleteChildButton)
        contentView.addSubview(deleteAccountButton)
        contentView.addSubview(legalLinksView)
    }

    private func setupConstraints() {
        let hPad = 16 * Constraint.xCoeff

        pageTitleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16 * Constraint.yCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }

        switcherScrollView.snp.makeConstraints {
            $0.top.equalTo(pageTitleLabel.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(100 * Constraint.yCoeff)
        }
        switcherStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(hPad)
            $0.trailing.lessThanOrEqualToSuperview().inset(hPad)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(switcherScrollView.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Profile card
        profileCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        profilePhotoButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(90 * Constraint.yCoeff)
        }
        cameraButton.snp.makeConstraints {
            $0.trailing.equalTo(profilePhotoButton.snp.trailing).offset(4 * Constraint.xCoeff)
            $0.bottom.equalTo(profilePhotoButton.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(profilePhotoButton.snp.bottom).offset(22 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(48 * Constraint.yCoeff)
        }
        birthdayLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        birthdayTextField.snp.makeConstraints {
            $0.top.equalTo(birthdayLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(48 * Constraint.yCoeff)
        }
        genderLabel.snp.makeConstraints {
            $0.top.equalTo(birthdayTextField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        genderStack.snp.makeConstraints {
            $0.top.equalTo(genderLabel.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(44 * Constraint.yCoeff)
        }
        saveProfileButton.snp.makeConstraints {
            $0.top.equalTo(genderStack.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(54 * Constraint.yCoeff)
        }
        profileSavedLabel.snp.makeConstraints {
            $0.top.equalTo(saveProfileButton.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16 * Constraint.yCoeff)
        }

        // Preferences
        prefSectionLabel.snp.makeConstraints {
            $0.top.equalTo(profileCard.snp.bottom).offset(28 * Constraint.yCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        notificationsRow.snp.makeConstraints {
            $0.top.equalTo(prefSectionLabel.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        exportRow.snp.makeConstraints {
            $0.top.equalTo(notificationsRow.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        darkModeRow.snp.makeConstraints {
            $0.top.equalTo(exportRow.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(64 * Constraint.yCoeff)
        }
        deleteChildButton.snp.makeConstraints {
            $0.top.equalTo(darkModeRow.snp.bottom).offset(32 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        deleteAccountButton.snp.makeConstraints {
            $0.top.equalTo(deleteChildButton.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        legalLinksView.snp.makeConstraints {
            $0.top.equalTo(deleteAccountButton.snp.bottom).offset(24 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(36 * Constraint.yCoeff)
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
        boyButton.setSelected(selectedGender == .boy,    selectedColor: purple)
        girlButton.setSelected(selectedGender == .girl,  selectedColor: purple)
        otherButton.setSelected(selectedGender == .other, selectedColor: purple)
    }

    // MARK: - Actions

    @objc private func switcherTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        BabyProfileStore.setSelectedIndex(selectedIndex)
        rebuildSwitcher()
        fillForm(from: currentProfile())
    }

    @objc private func addNewProfile() {
        var profiles = BabyProfileStore.loadProfiles()
        profiles.append(BabyProfile())
        BabyProfileStore.saveProfiles(profiles)
        self.profiles = profiles
        selectedIndex = profiles.count - 1
        BabyProfileStore.setSelectedIndex(selectedIndex)
        rebuildSwitcher()
        fillForm(from: currentProfile())
    }

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
            pop.sourceView = cameraButton
            pop.sourceRect = cameraButton.bounds
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
        var profiles = BabyProfileStore.loadProfiles()
        guard selectedIndex < profiles.count else { return }
        let name = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        profiles[selectedIndex].name   = name
        profiles[selectedIndex].gender = selectedGender.rawValue
        if let birthday = profileBirthdayFromPicker() {
            profiles[selectedIndex].birthday = birthday
        }
        BabyProfileStore.saveProfiles(profiles)
        self.profiles = profiles
        view.endEditing(true)
        rebuildSwitcher()
        showSaved()
        pushProfileToBackend(profiles[selectedIndex])
    }

    private func pushProfileToBackend(_ profile: BabyProfile) {
        guard let profileId = AuthStore.profileId else {
            // No profile on server yet — create one
            APIClient.createProfile(
                name: profile.name.isEmpty ? "My Baby" : profile.name,
                birthday: profile.birthdayTimestamp,
                gender: profile.gender,
                photoBase64: profile.photoData?.base64EncodedString()
            ) { result in
                if case .success(let p) = result { AuthStore.profileId = p.id }
            }
            return
        }
        APIClient.updateProfile(
            id: profileId,
            name: profile.name,
            birthday: profile.birthdayTimestamp,
            gender: profile.gender,
            photoBase64: nil
        ) { _ in }
    }

    private func profileBirthdayFromPicker() -> Date? {
        guard let text = birthdayTextField.text, !text.isEmpty else { return nil }
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        return df.date(from: text)
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

    @objc private func deleteChildTapped() {
        let name = profiles[safe: selectedIndex]?.name
        let displayName = (name?.isEmpty == false) ? name! : "this child"
        let alert = UIAlertController(
            title: "Delete Child Profile",
            message: "Are you sure you want to delete the profile for \(displayName)? All data for this child will be removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteChild()
        })
        present(alert, animated: true)
    }

    private func performDeleteChild() {
        guard profiles.count > 0 else { return }

        profiles.remove(at: selectedIndex)

        // If we deleted the last profile, create a blank one so app always has at least one
        if profiles.isEmpty {
            profiles.append(BabyProfile())
        }

        // Move to the previous profile, or stay at 0
        selectedIndex = max(0, selectedIndex - 1)

        BabyProfileStore.saveProfiles(profiles)
        BabyProfileStore.setSelectedIndex(selectedIndex)

        rebuildSwitcher()
        fillForm(from: currentProfile())
    }

    @objc private func termsTapped() {
        guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func privacyTapped() {
        guard let url = URL(string: "https://www.privacypolicies.com/live/placeholder") else { return }
        UIApplication.shared.open(url)
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
        birthdayTextField.resignFirstResponder()
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        let df = DateFormatter(); df.dateFormat = "dd.MM.yyyy"
        birthdayTextField.text = df.string(from: sender.date)
    }

    // MARK: - Helpers

    private func makeLegalLinksView() -> UIView {
        let container = UIView()

        let termsBtn = UIButton(type: .system)
        termsBtn.setTitle("Terms of Use", for: .normal)
        termsBtn.setTitleColor(UIColor(hexString: "#aaaaaa"), for: .normal)
        termsBtn.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        termsBtn.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        let dotLabel = UILabel()
        dotLabel.text = "•"
        dotLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        dotLabel.textColor = UIColor(hexString: "#aaaaaa")

        let privacyBtn = UIButton(type: .system)
        privacyBtn.setTitle("Privacy Policy", for: .normal)
        privacyBtn.setTitleColor(UIColor(hexString: "#aaaaaa"), for: .normal)
        privacyBtn.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        privacyBtn.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        container.addSubview(termsBtn)
        container.addSubview(dotLabel)
        container.addSubview(privacyBtn)

        termsBtn.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }
        dotLabel.snp.makeConstraints {
            $0.leading.equalTo(termsBtn.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        privacyBtn.snp.makeConstraints {
            $0.leading.equalTo(dotLabel.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.top.bottom.trailing.equalToSuperview()
        }

        return container
    }

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 8
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
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        l.textColor = .label
        return l
    }

    private func makeTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = .fieldBackground
        tf.layer.cornerRadius = 12 * Constraint.yCoeff
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
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
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8 * Constraint.xCoeff)
            $0.height.equalTo(14 * Constraint.yCoeff)
        }
        titleL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12 * Constraint.yCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }
        subL.snp.makeConstraints {
            $0.top.equalTo(titleL.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.leading.equalTo(titleL)
        }
        return card
    }

    // Dark Mode row: same layout but with a UISwitch instead of a chevron
    private func makeDarkModeRow() -> UIView {
        let card = makeCard()

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(white: 0.94, alpha: 1)
        iconBg.layer.cornerRadius = 10
        card.addSubview(iconBg)

        let iconImg = UIImageView(image: UIImage(systemName: "moon.fill"))
        iconImg.tintColor = UIColor(hexString: "#C6B4FE")
        iconImg.contentMode = .scaleAspectFit
        iconBg.addSubview(iconImg)

        let titleL = UILabel()
        titleL.text = "Dark Mode"
        titleL.font = .systemFont(ofSize: 15, weight: .semibold)
        titleL.textColor = .label
        card.addSubview(titleL)

        let subL = UILabel()
        subL.text = ThemeManager.shared.isDarkMode ? "On" : "Off"
        subL.font = .systemFont(ofSize: 12)
        subL.textColor = .secondaryLabel
        card.addSubview(subL)

        let toggle = UISwitch()
        toggle.isOn = ThemeManager.shared.isDarkMode
        toggle.onTintColor = UIColor(hexString: "#C6B4FE")
        toggle.addAction(UIAction { [weak subL] _ in
            let isOn = toggle.isOn
            ThemeManager.shared.isDarkMode = isOn
            subL?.text = isOn ? "On" : "Off"
        }, for: .valueChanged)
        card.addSubview(toggle)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(38 * Constraint.yCoeff)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        toggle.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        titleL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12 * Constraint.yCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-8)
        }
        subL.snp.makeConstraints {
            $0.top.equalTo(titleL.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.leading.equalTo(titleL)
            $0.bottom.equalToSuperview().inset(12 * Constraint.yCoeff)
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

        var profiles = BabyProfileStore.loadProfiles()
        guard selectedIndex < profiles.count else { return }
        let photoData = image.jpegData(compressionQuality: 0.85)
        profiles[selectedIndex].photoData = photoData
        BabyProfileStore.saveProfiles(profiles)
        self.profiles = profiles

        profilePhotoButton.setBackgroundImage(image, for: .normal)
        profilePhotoButton.setImage(nil, for: .normal)
        profilePhotoButton.contentHorizontalAlignment = .fill
        profilePhotoButton.contentVerticalAlignment   = .fill
        rebuildSwitcher()

        if let profileId = AuthStore.profileId, let data = photoData {
            APIClient.updateProfile(
                id: profileId, name: nil, birthday: nil, gender: nil,
                photoBase64: data.base64EncodedString()
            ) { _ in }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

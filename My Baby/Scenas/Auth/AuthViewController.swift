import UIKit
import SnapKit

final class AuthViewController: UIViewController {

    // MARK: - State

    private var isLoginMode = true

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.alwaysBounceVertical = true
        v.keyboardDismissMode = .onDrag
        return v
    }()
    private lazy var contentView = UIView()

    private lazy var logoLabel: UILabel = {
        let v = UILabel()
        v.text = "👶"
        v.font = .systemFont(ofSize: 64)
        v.textAlignment = .center
        return v
    }()
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.text = "Welcome to BabyTime"
        v.font = .systemFont(ofSize: 26, weight: .bold)
        v.textColor = UIColor(hexString: "#222222")
        v.textAlignment = .center
        return v
    }()
    private lazy var subtitleLabel: UILabel = {
        let v = UILabel()
        v.text = "Sign in to sync your baby's data"
        v.font = .systemFont(ofSize: 15)
        v.textColor = UIColor(hexString: "#888888")
        v.textAlignment = .center
        return v
    }()
    private lazy var nameField: UITextField = makeField(placeholder: "Your name", keyboard: .default)
    private lazy var emailField: UITextField = makeField(placeholder: "Email address", keyboard: .emailAddress)
    private lazy var passwordField: UITextField = {
        let f = makeField(placeholder: "Password", keyboard: .default)
        f.isSecureTextEntry = true
        return f
    }()

    private lazy var actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(hexString: "#4b3ba0")
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.title = "Sign In"
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr; a.font = .systemFont(ofSize: 17, weight: .semibold); return a
        }
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        return b
    }()

    private lazy var switchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Don't have an account? Register", for: .normal)
        b.setTitleColor(UIColor(hexString: "#4b3ba0"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.addTarget(self, action: #selector(switchMode), for: .touchUpInside)
        return b
    }()

    private lazy var skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue without account", for: .normal)
        b.setTitleColor(UIColor(hexString: "#aaaaaa"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13)
        b.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        return b
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = .white
        v.hidesWhenStopped = true
        return v
    }()

    private lazy var errorLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 13)
        v.textColor = UIColor(hexString: "#e05050")
        v.textAlignment = .center
        v.numberOfLines = 0
        v.isHidden = true
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#f7f5f0")
        setupUI()
        updateMode()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        [logoLabel, titleLabel, subtitleLabel, nameField,
         emailField, passwordField, errorLabel, actionButton,
         switchButton, skipButton].forEach { contentView.addSubview($0) }

        actionButton.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { $0.center.equalToSuperview() }

        let pad: CGFloat = 28

        logoLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(60)
            $0.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        nameField.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(52)
        }
        emailField.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(52)
        }
        passwordField.snp.makeConstraints {
            $0.top.equalTo(emailField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(52)
        }
        errorLabel.snp.makeConstraints {
            $0.top.equalTo(passwordField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        actionButton.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(54)
        }
        switchButton.snp.makeConstraints {
            $0.top.equalTo(actionButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        skipButton.snp.makeConstraints {
            $0.top.equalTo(switchButton.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    private func makeField(placeholder: String, keyboard: UIKeyboardType) -> UITextField {
        let f = UITextField()
        f.placeholder = placeholder
        f.keyboardType = keyboard
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.backgroundColor = .white
        f.layer.cornerRadius = 12
        f.layer.borderWidth = 1
        f.layer.borderColor = UIColor(hexString: "#e0ddd8").cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        f.leftViewMode = .always
        f.font = .systemFont(ofSize: 16)
        return f
    }

    private func updateMode() {
        if isLoginMode {
            nameField.isHidden = true
            actionButton.configuration?.title = "Sign In"
            switchButton.setTitle("Don't have an account? Register", for: .normal)
        } else {
            nameField.isHidden = false
            actionButton.configuration?.title = "Create Account"
            switchButton.setTitle("Already have an account? Sign In", for: .normal)
        }
        errorLabel.isHidden = true
    }

    // MARK: - Actions

    @objc private func switchMode() {
        isLoginMode.toggle()
        updateMode()
    }

    @objc private func skipTapped() {
        showMainApp()
    }

    @objc private func actionTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !email.isEmpty, !password.isEmpty else {
            showError("Please enter email and password")
            return
        }
        if !isLoginMode && name.isEmpty {
            showError("Please enter your name")
            return
        }

        setLoading(true)

        if isLoginMode {
            APIClient.login(email: email, password: password) { [weak self] result in
                self?.handleAuthResult(result)
            }
        } else {
            APIClient.register(email: email, password: password, name: name) { [weak self] result in
                self?.handleAuthResult(result)
            }
        }
    }

    private func handleAuthResult(_ result: Result<TokenResponse, Error>) {
        switch result {
        case .success(let token):
            AuthStore.token = token.access_token
            AuthStore.userId = token.user_id
            fetchAndSaveProfile()
        case .failure(let error):
            setLoading(false)
            showError(error.localizedDescription)
        }
    }

    private func fetchAndSaveProfile() {
        APIClient.getProfiles { [weak self] result in
            switch result {
            case .success(let profiles):
                if let first = profiles.first {
                    AuthStore.profileId = first.id
                    self?.applyRemoteProfile(first)
                } else {
                    // New user — create profile from local data
                    let local = BabyProfileStore.currentProfile()
                    APIClient.createProfile(
                        name: local?.name.isEmpty == false ? local!.name : "My Baby",
                        birthday: local?.birthdayTimestamp,
                        gender: local?.gender ?? "Other",
                        photoBase64: local?.photoData?.base64EncodedString()
                    ) { result in
                        if case .success(let p) = result {
                            AuthStore.profileId = p.id
                        }
                    }
                }
            case .failure:
                break
            }
            self?.setLoading(false)
            self?.showMainApp()
        }
    }

    private func applyRemoteProfile(_ profile: BabyProfileResponse) {
        var profiles = BabyProfileStore.loadProfiles()
        guard !profiles.isEmpty else { return }
        profiles[0].name = profile.name
        profiles[0].birthdayTimestamp = profile.birthday_timestamp
        profiles[0].gender = profile.gender
        if let b64 = profile.photo_base64, let data = Data(base64Encoded: b64) {
            profiles[0].photoData = data
        }
        BabyProfileStore.saveProfiles(profiles)
    }

    private func showMainApp() {
        guard let window = view.window else { return }
        let root = MainTabBarController()
        UIView.transition(with: window, duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { window.rootViewController = root })
    }

    private func setLoading(_ loading: Bool) {
        actionButton.configuration?.title = loading ? "" : (isLoginMode ? "Sign In" : "Create Account")
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        actionButton.isEnabled = !loading
    }

    private func showError(_ msg: String) {
        errorLabel.text = msg
        errorLabel.isHidden = false
    }
}

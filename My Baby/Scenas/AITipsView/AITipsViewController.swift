import UIKit
import SnapKit

final class AITipsViewController: UIViewController {

    // MARK: - State

    private var babyName: String { BabyProfileStore.loadName() ?? "Baby" }

    private var babyAgeWeeks: Int {
        guard let bday = BabyProfileStore.loadBirthday() else { return 0 }
        return Int(Date().timeIntervalSince(bday) / (7 * 24 * 3600))
    }

    private var lastFeedText: String {
        let entries = FeedingLogStore.loadEntries()
        guard let last = entries.first else { return "No data yet" }
        let type = last.typeRaw.capitalized
        let time = last.timeText
        return "\(time) (\(type))"
    }

    private var lastSleepText: String {
        let sessions = SleepSessionStore.load()
        guard let last = sessions.first else { return "No data yet" }
        let mins = Int(last.duration / 60)
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
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
        b.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
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
        b.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Scroll

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()

    private lazy var contentView = UIView()

    // MARK: - Greeting

    private lazy var greetingCard: UIView = makeCard()

    private lazy var greetingLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    private lazy var greetingSubLabel: UILabel = {
        let l = UILabel()
        l.text = "You're doing great. Here's a look at how today is going."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    // MARK: - AI Insight card

    private lazy var insightCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#6c5fcd")
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private lazy var insightBadgeLabel: UILabel = {
        let l = UILabel()
        l.text = "AI Insight"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor(hexString: "#6c5fcd")
        l.backgroundColor = .white
        l.layer.cornerRadius = 10
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private lazy var insightSparkLabel: UILabel = {
        let l = UILabel()
        l.text = "✦"
        l.font = .systemFont(ofSize: 22)
        l.textColor = .white
        return l
    }()

    private lazy var insightFeedLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white
        l.numberOfLines = 0
        return l
    }()

    private lazy var insightSleepLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white
        l.numberOfLines = 0
        return l
    }()

    private lazy var insightQuoteLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.italicSystemFont(ofSize: 13)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Trends

    private lazy var trendsTitleLabel: UILabel = makeSectionTitle("TRENDS")

    private lazy var sleepCard: UIView = makeCard()
    private lazy var feedingCard: UIView = makeCard()
    private lazy var warningCard: UIView = {
        let v = makeCard()
        v.backgroundColor = UIColor(hexString: "#fff3e0")
        return v
    }()

    // MARK: - Ask question button

    private lazy var askButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .systemBackground
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor(hexString: "#6c5fcd").withAlphaComponent(0.3).cgColor
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(askTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Configuration

    private lazy var configTitleLabel: UILabel = makeSectionTitle("CONFIGURATION")

    private lazy var configCard: UIView = makeCard()

    private lazy var tempValueLabel: UILabel = makeConfigValue("0.4 (Consistent)")
    private lazy var visibilityValueLabel: UILabel = makeConfigValue("Admins Only")

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save Settings", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#222222")
        b.layer.cornerRadius = 14
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    private lazy var saveStatusLabel: UILabel = {
        let l = UILabel()
        l.text = "⊙ Settings saved successfully"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshContent()
    }

    // MARK: - Content refresh

    private func refreshContent() {
        let name = babyName
        greetingLabel.text = "Hello, \(name)'s\nparent"

        let feedRow = attributedIconRow(icon: "🍽", text: "Last feed: \(lastFeedText)")
        insightFeedLabel.attributedText = feedRow

        let sleepRow = attributedIconRow(icon: "🌙", text: "Last sleep: \(lastSleepText)")
        insightSleepLabel.attributedText = sleepRow

        let weeks = babyAgeWeeks
        insightQuoteLabel.text = "\"This is a healthy rhythm for a \(weeks)-week-old.\""

        if let photo = BabyProfileStore.loadPhoto() {
            avatarButton.setBackgroundImage(photo, for: .normal)
            avatarButton.setImage(nil, for: .normal)
            avatarButton.contentHorizontalAlignment = .fill
            avatarButton.contentVerticalAlignment = .fill
        }

        // Trend labels
        updateSleepCard(name: name)
        updateAskButton(name: name)
    }

    private func attributedIconRow(icon: String, text: String) -> NSAttributedString {
        let s = NSMutableAttributedString(string: icon + "  " + text)
        return s
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(avatarButton)
        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(gearButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Greeting
        contentView.addSubview(greetingCard)
        greetingCard.addSubview(greetingLabel)
        greetingCard.addSubview(greetingSubLabel)

        // AI Insight
        contentView.addSubview(insightCard)
        insightCard.addSubview(insightBadgeLabel)
        insightCard.addSubview(insightSparkLabel)
        insightCard.addSubview(insightFeedLabel)
        insightCard.addSubview(insightSleepLabel)
        insightCard.addSubview(insightQuoteLabel)

        // Trends
        contentView.addSubview(trendsTitleLabel)
        contentView.addSubview(sleepCard)
        contentView.addSubview(feedingCard)
        contentView.addSubview(warningCard)

        // Ask button
        contentView.addSubview(askButton)

        // Config
        contentView.addSubview(configTitleLabel)
        contentView.addSubview(configCard)
        contentView.addSubview(saveButton)
        contentView.addSubview(saveStatusLabel)

        buildSleepCard()
        buildFeedingCard()
        buildWarningCard()
        buildAskButton()
        buildConfigCard()
    }

    private func buildSleepCard() {
        let iconBg = makeIconCircle(color: UIColor(hexString: "#ede9fb"), icon: "moon.fill", iconColor: UIColor(hexString: "#6c5fcd"))
        let titleL = makeCardTitle("Sleep is stabilizing")
        let subL = makeCardSub("")
        subL.tag = 101

        sleepCard.addSubview(iconBg)
        sleepCard.addSubview(titleL)
        sleepCard.addSubview(subL)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        titleL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        subL.snp.makeConstraints {
            $0.top.equalTo(titleL.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(titleL)
            $0.trailing.equalTo(titleL)
            $0.bottom.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
    }

    private func updateSleepCard(name: String) {
        if let l = sleepCard.viewWithTag(101) as? UILabel {
            let sessions = SleepSessionStore.load()
            if let last = sessions.first {
                let mins = Int(last.duration / 60)
                let h = mins / 60
                let m = mins % 60
                let dur = h > 0 ? "\(h)h \(m > 0 ? "\(m)m" : "")" : "\(m)m"
                l.text = "\(name) had a long stretch of \(dur) last night."
            } else {
                l.text = "No sleep data yet."
            }
        }
    }

    private func buildFeedingCard() {
        let iconBg = makeIconCircle(color: UIColor(hexString: "#e8f5ec"), icon: "drop.fill", iconColor: UIColor(hexString: "#4aad6f"))
        let titleL = makeCardTitle("Feeding frequency")
        let subL = makeCardSub("Consistent with yesterday's rhythm.")

        feedingCard.addSubview(iconBg)
        feedingCard.addSubview(titleL)
        feedingCard.addSubview(subL)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        titleL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        subL.snp.makeConstraints {
            $0.top.equalTo(titleL.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(titleL)
            $0.trailing.equalTo(titleL)
            $0.bottom.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
    }

    private func buildWarningCard() {
        let iconView = UIImageView(image: UIImage(systemName: "info.circle"))
        iconView.tintColor = UIColor(hexString: "#e07a2f")
        iconView.contentMode = .scaleAspectFit

        let textL = UILabel()
        textL.text = "Notice a change in patterns? While every baby is different, if you have specific medical concerns, please consult your pediatrician."
        textL.font = .systemFont(ofSize: 13)
        textL.textColor = UIColor(hexString: "#7a4a10")
        textL.numberOfLines = 0

        warningCard.addSubview(iconView)
        warningCard.addSubview(textL)

        iconView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        textL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(iconView.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
    }

    private func buildAskButton() {
        let iconView = UIImageView(image: UIImage(systemName: "message.fill"))
        iconView.tintColor = UIColor(hexString: "#6c5fcd")
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.tag = 200
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(hexString: "#6c5fcd")
        label.numberOfLines = 0
        label.textAlignment = .center

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(hexString: "#6c5fcd")
        chevron.contentMode = .scaleAspectFit

        askButton.addSubview(iconView)
        askButton.addSubview(label)
        askButton.addSubview(chevron)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(22 * Constraint.yCoeff)
        }
        label.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(iconView.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.trailing.equalTo(chevron.snp.leading).offset(-8 * Constraint.xCoeff)
        }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(10 * Constraint.xCoeff)
            $0.height.equalTo(16 * Constraint.yCoeff)
        }
    }

    private func updateAskButton(name: String) {
        if let l = askButton.viewWithTag(200) as? UILabel {
            l.text = "Ask a question about \(name)'s day"
        }
    }

    private func buildConfigCard() {
        let tempTitle = makeConfigKey("AI Model Temperature")
        let visTitle = makeConfigKey("Prompt Visibility")
        let sep = makeSeparator()

        configCard.addSubview(tempTitle)
        configCard.addSubview(tempValueLabel)
        configCard.addSubview(sep)
        configCard.addSubview(visTitle)
        configCard.addSubview(visibilityValueLabel)

        tempTitle.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.bottom.equalTo(sep.snp.top).offset(-14 * Constraint.xCoeff)
        }
        tempValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(tempTitle)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        sep.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(0.5)
            $0.bottom.equalTo(visTitle.snp.top).offset(-14 * Constraint.xCoeff)
        }
        visTitle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        visibilityValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(visTitle)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
    }

    // MARK: - Constraints

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

        // Greeting card
        greetingCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        greetingLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        greetingSubLabel.snp.makeConstraints {
            $0.top.equalTo(greetingLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(16 * Constraint.xCoeff)
        }

        // AI Insight card
        insightCard.snp.makeConstraints {
            $0.top.equalTo(greetingCard.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        insightBadgeLabel.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.height.equalTo(22 * Constraint.yCoeff)
            $0.width.equalTo(80 * Constraint.xCoeff)
        }
        insightSparkLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        insightFeedLabel.snp.makeConstraints {
            $0.top.equalTo(insightSparkLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        insightSleepLabel.snp.makeConstraints {
            $0.top.equalTo(insightFeedLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        insightQuoteLabel.snp.makeConstraints {
            $0.top.equalTo(insightSleepLabel.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(16 * Constraint.xCoeff)
        }

        // Trends
        trendsTitleLabel.snp.makeConstraints {
            $0.top.equalTo(insightCard.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        sleepCard.snp.makeConstraints {
            $0.top.equalTo(trendsTitleLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        feedingCard.snp.makeConstraints {
            $0.top.equalTo(sleepCard.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        warningCard.snp.makeConstraints {
            $0.top.equalTo(feedingCard.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }

        // Ask button
        askButton.snp.makeConstraints {
            $0.top.equalTo(warningCard.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(60 * Constraint.yCoeff)
        }

        // Config
        configTitleLabel.snp.makeConstraints {
            $0.top.equalTo(askButton.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        configCard.snp.makeConstraints {
            $0.top.equalTo(configTitleLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(configCard.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        saveStatusLabel.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(32 * Constraint.xCoeff)
        }
    }

    // MARK: - Actions

    @objc private func settingsTapped() {
        tabBarController?.selectedIndex = 4
    }

    @objc private func askTapped() {
        // Placeholder for AI chat
    }

    @objc private func saveTapped() {
        saveStatusLabel.isHidden = false
        saveStatusLabel.alpha = 0
        UIView.animate(withDuration: 0.3) { self.saveStatusLabel.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.3) { self.saveStatusLabel.alpha = 0 } completion: { _ in
                self.saveStatusLabel.isHidden = true
            }
        }
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 14
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
        l.letterSpacing(1.2)
        return l
    }

    private func makeIconCircle(color: UIColor, icon: String, iconColor: UIColor) -> UIView {
        let bg = UIView()
        bg.backgroundColor = color
        bg.layer.cornerRadius = 22 * Constraint.yCoeff
        bg.clipsToBounds = true

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = iconColor
        img.contentMode = .scaleAspectFit
        bg.addSubview(img)
        img.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        return bg
    }

    private func makeCardTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }

    private func makeCardSub(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }

    private func makeConfigKey(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 14)
        l.textColor = .label
        return l
    }

    private func makeConfigValue(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return v
    }
}

private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }
        let attr = NSAttributedString(string: text, attributes: [.kern: spacing])
        attributedText = attr
    }
}

import UIKit
import SnapKit

class MainViewController: UIViewController {

    var minute = 0

    private lazy var babyButton: UIButton = {
        let view = UIButton(type: .system)
        view.backgroundColor = .feedingViewColor.withAlphaComponent(0.8)
        let image = UIImage(systemName: "person")
        view.setImage(image, for: .normal)
        view.tintColor = .white
        view.makeRoundCorners(33)
        view.clipsToBounds = true
        view.addTarget(self, action: #selector(pressBabyButton), for: .touchUpInside)
        return view
    }()

    private lazy var yourBabyLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Your Baby"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .title1)
        view.textColor = .black
        return view
    }()

    private lazy var babyInfoLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Set up baby profile in Setting"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.textColor = .gray
        return view
    }()

    private lazy var feedingCountView: StatsCardView = {
        let view = StatsCardView()
        view.backgroundColor = .feedingViewColor
        view.iconImageView.image = UIImage(systemName: "fork.knife")
        view.titleLabel.text = "Feeding"
        view.countLabel.text = "0"
        return view
    }()

    private lazy var sleepCountView: StatsCardView = {
        let view = StatsCardView()
        view.backgroundColor = .sleepViewColor
        view.iconImageView.image = UIImage(systemName: "moon")
        view.titleLabel.text = "Sleep"
        view.countLabel.text = "\(minute)m"
        return view
    }()

    private lazy var diaperCountView: StatsCardView = {
        let view = StatsCardView()
        view.backgroundColor = .diaperViewColor
        view.iconImageView.image = UIImage(systemName: "figure.child.circle")
        view.titleLabel.text = "Diapers"
        view.countLabel.text = "0"
        return view
    }()

    private lazy var quickAddLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Quick Add"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .title2)
        view.textColor = .black
        return view
    }()

    private lazy var feedingActionCardButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = .feedingViewColor
        view.titleLabel.text = "Feeding"
        view.iconImageView.image = UIImage(systemName: "fork.knife")
        let tap = UITapGestureRecognizer(target: self, action: #selector(feedingActionCardButtonPressed))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var sleepActionCardButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = .sleepViewColor
        view.titleLabel.text = "Sleep"
        view.iconImageView.image = UIImage(systemName: "moon")
        let tap = UITapGestureRecognizer(target: self, action: #selector(sleepActionCardButtonPressed))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var diaperActionCardButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = .diaperViewColor
        view.titleLabel.text = "Diapers"
        view.iconImageView.image = UIImage(systemName: "figure.child.circle")
        let tap = UITapGestureRecognizer(target: self, action: #selector(diaperActionCardButtonPressed))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var growthActionCardButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = .growthViewColor
        view.titleLabel.text = "Growth"
        view.iconImageView.image = UIImage(systemName: "ruler")
        let tap = UITapGestureRecognizer(target: self, action: #selector(growthActionCardButtonPressed))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var feedingView: FeedingView = {
        let view = FeedingView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.feedingView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.feedingView.isHidden = true
            }
        }
        return view
    }()

    private lazy var daiperView: DaiperView = {
        let view = DaiperView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.daiperView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.daiperView.isHidden = true
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .viewsBackGourdColor

        setupUI()
        setupConstraints()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBabyProfile()
    }

    private func applyBabyProfile() {
        let name = BabyProfileStore.loadName()
        let birthday = BabyProfileStore.loadBirthday()
        let photo = BabyProfileStore.loadPhoto()

        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            yourBabyLabel.text = name
        } else {
            yourBabyLabel.text = "Your Baby"
        }

        if let birthday {
            babyInfoLabel.text = ageText(from: birthday)
        } else {
            babyInfoLabel.text = "Set up baby profile in Setting"
        }

        if let photo {
            babyButton.setBackgroundImage(photo, for: .normal)
            babyButton.setImage(nil, for: .normal)
            babyButton.backgroundColor = .clear
            babyButton.imageView?.contentMode = .scaleAspectFill
            babyButton.contentHorizontalAlignment = .fill
            babyButton.contentVerticalAlignment = .fill
            babyButton.clipsToBounds = true
        } else {
            babyButton.setBackgroundImage(nil, for: .normal)
            babyButton.setImage(UIImage(systemName: "person"), for: .normal)
            babyButton.tintColor = .white
            babyButton.backgroundColor = .feedingViewColor.withAlphaComponent(0.8)
            babyButton.contentHorizontalAlignment = .center
            babyButton.contentVerticalAlignment = .center
        }
    }

    private func ageText(from birthday: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let start = cal.startOfDay(for: birthday)
        let end = cal.startOfDay(for: now)
        guard end >= start else { return "" }

        let comps = cal.dateComponents([.year, .month, .day], from: start, to: end)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)

        if years == 0 && months == 0 {
            return "\(days) days"
        }

        if years == 0 {
            return "\(months) months \(days) days"
        }

        let weeks = days / 7
        return "\(years) years \(months) months \(weeks) weeks"
    }

    private func setupUI() {
        view.addSubview(babyButton)
        view.addSubview(yourBabyLabel)
        view.addSubview(babyInfoLabel)
        view.addSubview(feedingCountView)
        view.addSubview(sleepCountView)
        view.addSubview(diaperCountView)
        view.addSubview(quickAddLabel)
        view.addSubview(feedingActionCardButton)
        view.addSubview(sleepActionCardButton)
        view.addSubview(diaperActionCardButton)
        view.addSubview(growthActionCardButton)
        view.addSubview(feedingView)
        view.addSubview(daiperView)
    }

    private func setupConstraints() {
        babyButton.snp.remakeConstraints { (make) in
            make.top.equalTo(view.snp.top).offset(60 * Constraint.xCoeff)
            make.leading.equalTo(view.snp.leading).offset(20 * Constraint.yCoeff)
            make.width.equalTo(66 * Constraint.yCoeff)
            make.height.equalTo(66 * Constraint.xCoeff)
        }

        yourBabyLabel.snp.remakeConstraints { (make) in
            make.bottom.equalTo(babyButton.snp.centerY).offset(-2 * Constraint.xCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        babyInfoLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(babyButton.snp.centerY).offset(2 * Constraint.xCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        feedingCountView.snp.remakeConstraints { (make) in
            make.top.equalTo(babyButton.snp.bottom).offset(40 * Constraint.xCoeff)
            make.leading.equalTo(view.snp.leading).offset(10 * Constraint.yCoeff)
            make.height.equalTo(80 * Constraint.xCoeff)
            make.width.equalTo(120 * Constraint.yCoeff)
        }

        sleepCountView.snp.remakeConstraints { make in
            make.top.equalTo(feedingCountView.snp.top)
            make.centerX.equalTo(view.snp.centerX)
            make.height.equalTo(80 * Constraint.xCoeff)
            make.width.equalTo(120 * Constraint.yCoeff)
        }

        diaperCountView.snp.remakeConstraints { make in
            make.top.equalTo(feedingCountView.snp.top)
            make.trailing.equalTo(view.snp.trailing).offset(-10 * Constraint.yCoeff)
            make.height.equalTo(80 * Constraint.xCoeff)
            make.width.equalTo(120 * Constraint.yCoeff)
        }

        quickAddLabel.snp.remakeConstraints { make in
            make.top.equalTo(feedingCountView.snp.bottom).offset(30 * Constraint.xCoeff)
            make.leading.equalTo(view.snp.leading).offset(10 * Constraint.yCoeff)
        }

        feedingActionCardButton.snp.remakeConstraints { make in
            make.top.equalTo(quickAddLabel.snp.bottom).offset(30 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
        }

        sleepActionCardButton.snp.remakeConstraints { make in
            make.top.equalTo(feedingActionCardButton.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
        }

        diaperActionCardButton.snp.remakeConstraints { make in
            make.top.equalTo(sleepActionCardButton.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
        }

        growthActionCardButton.snp.remakeConstraints { make in
            make.top.equalTo(diaperActionCardButton.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
        }

        feedingView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        daiperView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Prepare diaper view off-screen for slide-in animation
        daiperView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    }

    /// Switch to a tab by index. Order: 0 = Home, 1 = Feeding, 2 = Sleep, 3 = Diaper, 4 = Settings.
    private func switchToTab(index: Int) {
        guard let tabBar = tabBarController, index >= 0, index < (tabBar.viewControllers?.count ?? 0) else { return }
        tabBar.selectedIndex = index
        if let nav = tabBar.viewControllers?[index] as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }

    @objc private func pressBabyButton() {
        switchToTab(index: 4) // Settings
    }

    @objc private func feedingActionCardButtonPressed() {
        switchToTab(index: 1) // Feeding
    }

    @objc private func sleepActionCardButtonPressed() {
        switchToTab(index: 2) // Sleep
    }

    @objc private func diaperActionCardButtonPressed() {
        switchToTab(index: 3) // Diaper
    }

    @objc private func growthActionCardButtonPressed() {
        switchToTab(index: 4) // Settings
    }
}

import UIKit
import SnapKit

class MainViewController: UIViewController {

    var minute = 10

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
            make.width.height.equalTo(66 * Constraint.xCoeff)
        }

        yourBabyLabel.snp.remakeConstraints { (make) in
            make.bottom.equalTo(babyButton.snp.centerY).offset(-2 * Constraint.yCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        babyInfoLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(babyButton.snp.centerY).offset(2 * Constraint.yCoeff)
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

    @objc private func pressBabyButton() {
        guard let tabBar = self.tabBarController else { return }
        // Find the index of the tab that hosts SleepViewController (directly or inside a UINavigationController)
        if let viewControllers = tabBar.viewControllers {
            if let index = viewControllers.firstIndex(where: { vc in
                if let nav = vc as? UINavigationController {
                    return nav.viewControllers.first is SettingsViewController
                } else {
                    return vc is SettingsViewController
                }
            }) {
                tabBar.selectedIndex = index
                // If the selected VC is a nav controller, pop to root to reveal SleepViewController
                if let nav = tabBar.viewControllers?[index] as? UINavigationController {
                    nav.popToRootViewController(animated: false)
                }
            }
        }
    }

    @objc private func feedingActionCardButtonPressed() {
        feedingView.isHidden = false
        // Reset starting position off-screen
        feedingView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) {
            self.feedingView.transform = .identity
        }
    }

    @objc private func diaperActionCardButtonPressed() {
        daiperView.isHidden = false
        // Reset starting position off-screen
        daiperView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) {
            self.daiperView.transform = .identity
        }
    }

    @objc private func sleepActionCardButtonPressed() {
        guard let tabBar = self.tabBarController else { return }
        // Find the index of the tab that hosts SleepViewController (directly or inside a UINavigationController)
        if let viewControllers = tabBar.viewControllers {
            if let index = viewControllers.firstIndex(where: { vc in
                if let nav = vc as? UINavigationController {
                    return nav.viewControllers.first is SleepViewController
                } else {
                    return vc is SleepViewController
                }
            }) {
                tabBar.selectedIndex = index
                // If the selected VC is a nav controller, pop to root to reveal SleepViewController
                if let nav = tabBar.viewControllers?[index] as? UINavigationController {
                    nav.popToRootViewController(animated: false)
                }
            }
        }
    }

    @objc private func growthActionCardButtonPressed() {
        guard let tabBar = self.tabBarController else { return }
        // Find the index of the tab that hosts SleepViewController (directly or inside a UINavigationController)
        if let viewControllers = tabBar.viewControllers {
            if let index = viewControllers.firstIndex(where: { vc in
                if let nav = vc as? UINavigationController {
                    return nav.viewControllers.first is SettingsViewController
                } else {
                    return vc is SettingsViewController
                }
            }) {
                tabBar.selectedIndex = index
                // If the selected VC is a nav controller, pop to root to reveal SleepViewController
                if let nav = tabBar.viewControllers?[index] as? UINavigationController {
                    nav.popToRootViewController(animated: false)
                }
            }
        }
    }
}

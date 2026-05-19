//
//  WelcomeViewController.swift
//  My Baby
//

import UIKit
import SnapKit

final class WelcomeViewController: UIViewController {

    // MARK: - Background blobs

    private let blobTopRight: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#d8cce8").withAlphaComponent(0.5)
        return v
    }()

    private let blobMiddleLeft: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f5d8dc").withAlphaComponent(0.5)
        return v
    }()

    // MARK: - Icon

    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e0d5f0")
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.text = "👶"
        l.font = .systemFont(ofSize: 28 * Constraint.yCoeff)
        return l
    }()

    // MARK: - Title / subtitle

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome to BabyTime"
        l.font = .systemFont(ofSize: 28 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your companion in every little moment."
        l.font = .systemFont(ofSize: 16 * Constraint.yCoeff)
        l.textColor = UIColor(hexString: "#888888")
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Illustration

    private let illustrationCircle: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowRadius = 16
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        return v
    }()

    private let teddyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "teddyBear")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Buttons

    private let appleButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(hexString: "#1a1a1a")
        b.setTitle("Continue with Apple", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.setImage(UIImage(systemName: "apple.logo"), for: .normal)
        b.tintColor = .white
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        return b
    }()

    private let googleButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .white
        b.setTitle("Continue with Google", for: .normal)
        b.setTitleColor(UIColor(hexString: "#1a1a1a"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor(hexString: "#e0e0e0").cgColor
        return b
    }()

    private let googleIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "globe")
        iv.tintColor = UIColor(hexString: "#4285F4")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emailButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(hexString: "#6a5acd")
        b.setTitle("Sign up with Email", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .semibold)
        b.setImage(UIImage(systemName: "envelope"), for: .normal)
        b.tintColor = .white
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        return b
    }()

    private let termsLabel: UILabel = {
        let l = UILabel()
        let base = "By continuing, you agree to our Terms of Use and Privacy Policy."
        let attr = NSMutableAttributedString(
            string: base,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12 * Constraint.yCoeff),
                .foregroundColor: UIColor(hexString: "#888888")
            ])
        for word in ["Terms of Use", "Privacy Policy"] {
            if let r = base.range(of: word) {
                attr.addAttribute(.foregroundColor,
                    value: UIColor(hexString: "#6a5acd"),
                    range: NSRange(r, in: base))
            }
        }
        l.attributedText = attr
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#fdf8f5")
        setupHierarchy()
        setupConstraints()
        appleButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        emailButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blobTopRight.layer.cornerRadius = blobTopRight.bounds.width / 2
        blobMiddleLeft.layer.cornerRadius = blobMiddleLeft.bounds.width / 2
        iconContainer.layer.cornerRadius = iconContainer.bounds.width / 2
        illustrationCircle.layer.cornerRadius = illustrationCircle.bounds.width / 2
    }

    @objc private func handleContinue() {
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
        guard let window = view.window else { return }
        let tabBar = MainTabBarController()
        window.rootViewController = tabBar
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }

    // MARK: - Layout

    private func setupHierarchy() {
        [blobTopRight, blobMiddleLeft,
         iconContainer, titleLabel, subtitleLabel,
         illustrationCircle,
         appleButton, googleButton, emailButton, termsLabel
        ].forEach { view.addSubview($0) }

        iconContainer.addSubview(iconLabel)
        illustrationCircle.addSubview(teddyImageView)
        googleButton.addSubview(googleIconView)
    }

    private func setupConstraints() {
        let hPad = 24 * Constraint.xCoeff
        let btnH = 56 * Constraint.yCoeff

        // Decorative blobs
        blobTopRight.snp.makeConstraints {
            $0.width.height.equalTo(280 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().offset(100 * Constraint.xCoeff)
            $0.top.equalToSuperview().offset(-80 * Constraint.yCoeff)
        }
        blobMiddleLeft.snp.makeConstraints {
            $0.width.height.equalTo(240 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(-80 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }

        // Icon circle
        iconContainer.snp.makeConstraints {
            $0.width.height.equalTo(64 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40 * Constraint.yCoeff)
        }
        iconLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        // Title
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconContainer.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(32 * Constraint.xCoeff)
        }

        // Subtitle
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(48 * Constraint.xCoeff)
        }

        // Illustration — floats between subtitle and buttons
        illustrationCircle.snp.makeConstraints {
            $0.width.height.equalTo(220 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.top.greaterThanOrEqualTo(subtitleLabel.snp.bottom).offset(24 * Constraint.yCoeff)
            $0.bottom.equalTo(appleButton.snp.top).offset(-32 * Constraint.yCoeff)
        }
        teddyImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12 * Constraint.yCoeff)
        }

        // Buttons — anchored from bottom up
        termsLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(32 * Constraint.xCoeff)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12 * Constraint.yCoeff)
        }
        emailButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(btnH)
            $0.bottom.equalTo(termsLabel.snp.top).offset(-14 * Constraint.yCoeff)
        }
        googleButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(btnH)
            $0.bottom.equalTo(emailButton.snp.top).offset(-12 * Constraint.yCoeff)
        }
        googleIconView.snp.makeConstraints {
            $0.width.height.equalTo(22 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(googleButton.titleLabel!.snp.leading).offset(-10 * Constraint.xCoeff)
        }
        appleButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(btnH)
            $0.bottom.equalTo(googleButton.snp.top).offset(-12 * Constraint.yCoeff)
        }
    }
}

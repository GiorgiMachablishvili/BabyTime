

import UIKit
import SnapKit

final class ActionCardButton: UIView {

    // MARK: - Callback

    var onTap: (() -> Void)?

    // MARK: - UI

    lazy var iconImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.tintColor = .buttonTitleColor
        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .buttonTitleColor
        view.textAlignment = .center
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraint()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 20
        clipsToBounds = true

        addSubview(iconImageView)
        addSubview(titleLabel)
    }

    private func setupConstraint() {
        iconImageView.snp.makeConstraints {
//            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10 * Constraint.xCoeff)
            $0.leading.equalTo(snp.leading).offset(20 * Constraint.yCoeff)
            $0.width.equalTo(28 * Constraint.yCoeff)
            $0.height.equalTo(28 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.equalTo(snp.leading).offset(20 * Constraint.yCoeff)
//            $0.centerX.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Public API

    func configure(
        backgroundColor: UIColor,
        icon: UIImage?,
        title: String,
        textColor: UIColor = .black,
        iconColor: UIColor = .black
    ) {
        self.backgroundColor = backgroundColor
        iconImageView.image = icon
        iconImageView.tintColor = iconColor
        titleLabel.text = title
        titleLabel.textColor = textColor
    }
}

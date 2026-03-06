

import UIKit
import SnapKit

final class EmptyStateView: UIView {

    private lazy var iconCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        view.clipsToBounds = true
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UIColor.systemOrange.withAlphaComponent(0.65)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .systemFont(ofSize: 26, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.75)
        view.numberOfLines = 0
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .systemFont(ofSize: 18, weight: .regular)
        view.textColor = UIColor.secondaryLabel
        view.numberOfLines = 0
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconCircleView.layer.cornerRadius = iconCircleView.bounds.height / 2
    }

    private func setupUI() {
        addSubview(iconCircleView)
        iconCircleView.addSubview(iconImageView)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    private func setupConstraints() {
        iconCircleView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.equalTo(90 * Constraint.yCoeff)
            $0.height.equalTo(90 * Constraint.xCoeff)
        }

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(40 * Constraint.yCoeff)
            $0.height.equalTo(40 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircleView.snp.bottom).offset(18 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.yCoeff)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(24 * Constraint.yCoeff)
            $0.bottom.equalToSuperview()
        }
    }

    // MARK: - Public API

    func configure(icon: UIImage?, iconTint: UIColor, circleColor: UIColor, title: String, subtitle: String) {
        iconImageView.image = icon
        iconImageView.tintColor = iconTint
        iconCircleView.backgroundColor = circleColor
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}


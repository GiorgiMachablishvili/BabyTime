


import UIKit
import SnapKit

final class SettingsRowCell: UICollectionViewCell {

    static let reuseId = "SettingsRowCell"

    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        return view
    }()

    private lazy var iconCircle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 33
        view.clipsToBounds = true
        return view
    }()

    private lazy var iconImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UIColor.label.withAlphaComponent(0.35)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 18, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.75)
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.textColor = UIColor.secondaryLabel
        return view
    }()

    private lazy var chevronImage: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "chevron.right"))
        view.tintColor = UIColor.label.withAlphaComponent(0.25)
        view.contentMode = .scaleAspectFit
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

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(container)

        container.addSubview(iconCircle)
        iconCircle.addSubview(iconImage)

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(chevronImage)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(66 * Constraint.yCoeff)
            $0.height.equalTo(66 * Constraint.xCoeff)
        }

        iconImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(60 * Constraint.yCoeff)
            $0.height.equalTo(60 * Constraint.xCoeff)
        }

        chevronImage.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(16 * Constraint.yCoeff)
            $0.height.equalTo(16 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(chevronImage.snp.leading).offset(-10 * Constraint.yCoeff)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(chevronImage.snp.leading).offset(-10 * Constraint.yCoeff)
        }
    }

    func configure(icon: UIImage?, title: String, subtitle: String?) {
        iconImage.image = icon
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle == nil)
    }
}




import UIKit
import SnapKit

final class SettingsRowCell: UICollectionViewCell {

    static let reuseId = "SettingsRowCell"

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 22
        v.clipsToBounds = true
        return v
    }()

    private let iconCircle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray6
        v.layer.cornerRadius = 18
        v.clipsToBounds = true
        return v
    }()

    private let iconImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.label.withAlphaComponent(0.35)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = UIColor.label.withAlphaComponent(0.75)
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor.secondaryLabel
        return l
    }()

    private let chevronImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = UIColor.label.withAlphaComponent(0.25)
        iv.contentMode = .scaleAspectFit
        return iv
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
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        iconImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(20)
        }

        chevronImage.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalTo(iconCircle.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(chevronImage.snp.leading).offset(-10)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(chevronImage.snp.leading).offset(-10)
        }
    }

    func configure(icon: UIImage?, title: String, subtitle: String?) {
        iconImage.image = icon
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle == nil)
    }
}

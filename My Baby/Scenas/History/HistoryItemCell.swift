import UIKit
import SnapKit

final class HistoryItemCell: UICollectionViewCell {
    static let reuseId = "HistoryItemCell"

    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray6
        v.layer.cornerRadius = 16
        return v
    }()

    private let iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.tintColor = UIColor.label.withAlphaComponent(0.9)
        return v
    }()

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16, weight: .semibold)
        v.textColor = UIColor.label.withAlphaComponent(0.9)
        v.numberOfLines = 1
        return v
    }()

    private let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 13, weight: .regular)
        v.textColor = UIColor.secondaryLabel
        v.numberOfLines = 1
        return v
    }()

    private let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 13, weight: .semibold)
        v.textColor = UIColor.secondaryLabel
        v.textAlignment = .right
        v.setContentHuggingPriority(.required, for: .horizontal)
        return v
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(separator)
    }

    private func setupConstraints() {
        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(40 * Constraint.yCoeff)
            $0.height.equalTo(40 * Constraint.xCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(20 * Constraint.yCoeff)
            $0.height.equalTo(20 * Constraint.xCoeff)
        }

        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14 * Constraint.yCoeff)
            $0.centerY.equalToSuperview().offset(-10 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12 * Constraint.xCoeff)
            $0.leading.equalTo(iconContainer.snp.trailing).offset(10 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-10 * Constraint.yCoeff)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-14 * Constraint.yCoeff)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12 * Constraint.xCoeff)
        }

        separator.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func configure(title: String, subtitle: String?, timeText: String, type: HistoryType) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle == nil || subtitle?.isEmpty == true)
        timeLabel.text = timeText

        let (icon, tint, bg): (String, UIColor, UIColor) = {
            switch type {
            case .feeding: return ("fork.knife", .white, .feedingViewColor)
            case .sleep: return ("moon", .white, .sleepViewColor)
            case .diaper: return ("figure.child.circle", .white, .diaperViewColor)
            case .doctorVisit: return ("stethoscope", .white, .growthViewColor)
            case .vaccination: return ("syringe", .white, .systemTeal)
            }
        }()

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = tint
        iconContainer.backgroundColor = bg.withAlphaComponent(0.95)
    }
}


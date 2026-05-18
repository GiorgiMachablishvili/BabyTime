import UIKit
import SnapKit

final class FeedingViewCell: UICollectionViewCell {
    static let reuseId = "FeedingViewCell"

    var onMenuTap: (() -> Void)?

    // MARK: - Time column

    private let timeHourLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222")
        l.textAlignment = .right
        return l
    }()

    private let timeAmPmLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888")
        l.textAlignment = .right
        return l
    }()

    // MARK: - Card

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let accentStrip: UIView = {
        let v = UIView()
        return v
    }()

    private let typeBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 9 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private let typeBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .semibold)
        return l
    }()

    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#666666")
        return l
    }()

    private let checkmark: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = UIColor(hexString: "#5aac7c")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var menuButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        b.tintColor = UIColor(hexString: "#aaaaaa")
        b.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        contentView.addSubview(timeHourLabel)
        contentView.addSubview(timeAmPmLabel)
        contentView.addSubview(card)
        card.addSubview(accentStrip)
        card.addSubview(typeBadge)
        typeBadge.addSubview(typeBadgeLabel)
        card.addSubview(amountLabel)
        card.addSubview(checkmark)
        card.addSubview(menuButton)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMenuTap = nil
        amountLabel.text = nil
    }

    // MARK: - Layout

    private func setupConstraints() {
        let timeW: CGFloat = 44 * Constraint.xCoeff
        let stripW: CGFloat = 5 * Constraint.xCoeff

        timeHourLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.width.equalTo(timeW)
            $0.bottom.equalTo(contentView.snp.centerY).offset(-1)
        }
        timeAmPmLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.width.equalTo(timeW)
            $0.top.equalTo(contentView.snp.centerY).offset(1)
        }

        card.snp.makeConstraints {
            $0.leading.equalTo(timeHourLabel.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.trailing.top.bottom.equalToSuperview()
        }

        accentStrip.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(stripW)
        }

        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }

        checkmark.snp.makeConstraints {
            $0.trailing.equalTo(menuButton.snp.leading).offset(-6 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }

        typeBadge.snp.makeConstraints {
            $0.leading.equalTo(accentStrip.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.centerY.equalToSuperview().offset(-10 * Constraint.yCoeff)
        }
        typeBadgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
        }

        amountLabel.snp.makeConstraints {
            $0.leading.equalTo(typeBadge.snp.leading)
            $0.top.equalTo(typeBadge.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(checkmark.snp.leading).offset(-8 * Constraint.xCoeff)
        }
    }

    // MARK: - Configure

    func configure(entry: FeedingLogEntry) {
        let date = Date(timeIntervalSince1970: entry.savedAtEpochSeconds ?? 0)
        let tf = DateFormatter()
        tf.dateFormat = "h:mm"
        timeHourLabel.text = tf.string(from: date)
        tf.dateFormat = "a"
        timeAmPmLabel.text = tf.string(from: date)

        switch entry.typeRaw {
        case "breast":
            accentStrip.backgroundColor = UIColor.systemPink
            typeBadge.backgroundColor = UIColor.systemPink.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = UIColor.systemPink
            typeBadgeLabel.text = "Breast"
        case "bottle":
            accentStrip.backgroundColor = UIColor(hexString: "#9b7fd4")
            typeBadge.backgroundColor = UIColor(hexString: "#9b7fd4").withAlphaComponent(0.12)
            typeBadgeLabel.textColor = UIColor(hexString: "#9b7fd4")
            typeBadgeLabel.text = "Bottle"
        case "formula":
            accentStrip.backgroundColor = UIColor.systemOrange
            typeBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
            typeBadgeLabel.textColor = UIColor.systemOrange
            typeBadgeLabel.text = "Formula"
        default:
            accentStrip.backgroundColor = UIColor(hexString: "#5aac7c")
            typeBadge.backgroundColor = UIColor(hexString: "#5aac7c").withAlphaComponent(0.12)
            typeBadgeLabel.textColor = UIColor(hexString: "#5aac7c")
            typeBadgeLabel.text = "Solids"
        }

        if let vol = entry.volumeText, !vol.isEmpty {
            amountLabel.text = vol
            amountLabel.isHidden = false
        } else if let notes = entry.notesText, !notes.isEmpty {
            amountLabel.text = notes
            amountLabel.isHidden = false
        } else {
            amountLabel.isHidden = true
        }
    }

    @objc private func menuTapped() { onMenuTap?() }

    // MARK: - ViewModel (kept for FeedingLogStore compatibility)

    struct ViewModel {
        enum FeedingType {
            case breast, bottle, formula, solid
        }
        let type: FeedingType
        let volumeText: String?
        let notesText: String?
        let timeText: String
        let dateText: String
    }
}

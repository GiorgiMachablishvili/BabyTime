import UIKit
import SnapKit

final class DiaperLogCell: UICollectionViewCell {
    static let reuseId = "DiaperLogCell"

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
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    private let accentStrip: UIView = {
        let v = UIView()
        return v
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10 * Constraint.yCoeff
        return v
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .semibold)
        return l
    }()

    private let noteLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#444444")
        l.numberOfLines = 2
        return l
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

        // Time column
        contentView.addSubview(timeHourLabel)
        contentView.addSubview(timeAmPmLabel)

        // Card
        contentView.addSubview(card)
        card.addSubview(accentStrip)
        card.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        card.addSubview(noteLabel)
        card.addSubview(menuButton)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMenuTap = nil
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
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        accentStrip.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(stripW)
        }

        badgeView.snp.makeConstraints {
            $0.leading.equalTo(accentStrip.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.top.equalToSuperview().offset(14 * Constraint.yCoeff)
        }
        badgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
        }

        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.top.equalToSuperview().offset(12 * Constraint.yCoeff)
            $0.width.height.equalTo(28 * Constraint.yCoeff)
        }

        noteLabel.snp.makeConstraints {
            $0.leading.equalTo(badgeView.snp.leading)
            $0.trailing.equalTo(menuButton.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.top.equalTo(badgeView.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.bottom.lessThanOrEqualToSuperview().inset(12 * Constraint.yCoeff)
        }
    }

    // MARK: - Configure

    func configure(item: DiaperLogItem) {
        // Time
        let tf = DateFormatter()
        tf.dateFormat = "h:mm"
        timeHourLabel.text = tf.string(from: item.date)
        tf.dateFormat = "a"
        timeAmPmLabel.text = tf.string(from: item.date)

        // Accent strip
        accentStrip.backgroundColor = item.type.accentColor

        // Badge
        badgeView.backgroundColor = item.type.lightBackground
        badgeLabel.text = item.type.badgeTitle
        badgeLabel.textColor = item.type.accentColor

        // Note
        let note = item.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        noteLabel.text = note.isEmpty ? item.type.subtitleFallback : note
    }

    // MARK: - Actions

    @objc private func menuTapped() {
        onMenuTap?()
    }
}

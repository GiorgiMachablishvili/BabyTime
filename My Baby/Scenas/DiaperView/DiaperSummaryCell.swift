import UIKit
import SnapKit

final class DiaperSummaryCell: UICollectionViewCell {
    static let reuseId = "DiaperSummaryCell"

    private let wetPill  = DiaperPillView(type: .wet)
    private let dirtyPill = DiaperPillView(type: .dirty)
    private let mixedPill = DiaperPillView(type: .mixed)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [wetPill, dirtyPill, mixedPill])
        stack.axis = .horizontal
        stack.spacing = 12 * Constraint.xCoeff
        stack.distribution = .fillEqually

        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(wetCount: Int, dirtyCount: Int, mixedCount: Int) {
        wetPill.setCount(wetCount)
        dirtyPill.setCount(dirtyCount)
        mixedPill.setCount(mixedCount)
    }
}

// MARK: - DiaperPillView

private final class DiaperPillView: UIView {
    private let type: DiaperType

    private lazy var iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = type.accentColor
        iv.image = UIImage(systemName: type.sfSymbol)
        return iv
    }()

    private lazy var countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 32 * Constraint.yCoeff, weight: .bold)
        l.textColor = type.accentColor
        l.textAlignment = .center
        return l
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = type.badgeTitle
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        l.textColor = type.accentColor
        l.textAlignment = .center
        return l
    }()

    init(type: DiaperType) {
        self.type = type
        super.init(frame: .zero)
        backgroundColor = type.lightBackground
        layer.cornerRadius = 20 * Constraint.yCoeff

        let stack = UIStackView(arrangedSubviews: [iconView, countLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4 * Constraint.yCoeff
        stack.alignment = .center

        addSubview(stack)
        iconView.snp.makeConstraints { $0.width.height.equalTo(22 * Constraint.yCoeff) }
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setCount(_ count: Int) {
        countLabel.text = "\(count)"
    }
}

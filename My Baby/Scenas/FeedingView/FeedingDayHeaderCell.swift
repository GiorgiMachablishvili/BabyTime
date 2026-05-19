import UIKit
import SnapKit

final class FeedingDayHeaderCell: UICollectionViewCell {
    static let reuseId = "FeedingDayHeaderCell"

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 18, weight: .semibold)
        v.textColor = UIColor.label.withAlphaComponent(0.88)
        v.numberOfLines = 1
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.top.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().offset(-4 * Constraint.xCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) {
        titleLabel.text = title
    }
}


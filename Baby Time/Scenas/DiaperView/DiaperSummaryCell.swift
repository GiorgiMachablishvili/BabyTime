import UIKit
import SnapKit

final class DiaperSummaryCell: UICollectionViewCell {
    static let reuseId = "DiaperSummaryCell"

    private let card = UIView()
    private let titleLabel = UILabel()

    private let wetLabel = UILabel()
    private let mixedLabel = UILabel()
    private let dirtyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.backgroundColor = .white
        card.layer.cornerRadius = 16

        titleLabel.text = "Today's Summary"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        [wetLabel, mixedLabel, dirtyLabel].forEach {
            $0.font = .systemFont(ofSize: 22, weight: .semibold)
        }

        let row = UIStackView(arrangedSubviews: [wetLabel, mixedLabel, dirtyLabel])
        row.axis = .horizontal
        row.spacing = 22
        row.alignment = .center

        card.addSubview(titleLabel)
        card.addSubview(row)

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
        }

        row.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.bottom.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Wet should include `.wet` + `.mixed`
    /// Dirty should include `.dirty` + `.mixed`
    /// Mixed should include only `.mixed`
    func configure(wetCount: Int, mixedCount: Int, dirtyCount: Int) {
        wetLabel.text = "💧  \(wetCount)"
        mixedLabel.text = "💧💩  \(mixedCount)"
        dirtyLabel.text = "💩  \(dirtyCount)"
    }
}

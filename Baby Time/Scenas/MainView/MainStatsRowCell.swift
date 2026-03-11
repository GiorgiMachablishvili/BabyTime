import UIKit
import SnapKit

final class MainStatsRowCell: UICollectionViewCell {

    static let reuseId = "MainStatsRowCell"

    private lazy var feedingCard: StatsCardView = {
        let view = StatsCardView()
        view.configure(
            backgroundColor: .feedingViewColor,
            icon: UIImage(systemName: "fork.knife"),
            title: "Feeding",
            count: 0,
            contentLeadingInset: 20
        )
        return view
    }()

    private lazy var sleepCard: StatsCardView = {
        let view = StatsCardView()
        view.configure(
            backgroundColor: .sleepViewColor,
            icon: UIImage(systemName: "moon"),
            title: "Sleep",
            count: 0
        )
        return view
    }()

    private lazy var diaperCard: StatsCardView = {
        let view = StatsCardView()
        view.configure(
            backgroundColor: .diaperViewColor,
            icon: UIImage(systemName: "figure.child.circle"),
            title: "Diapers",
            count: 0
        )
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        contentView.addSubview(feedingCard)
        contentView.addSubview(sleepCard)
        contentView.addSubview(diaperCard)
    }

    private func setupConstraints() {
        let gap: CGFloat = 6 * Constraint.yCoeff
        feedingCard.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(contentView.snp.width).offset(-(gap * 2)).dividedBy(3)
        }
        sleepCard.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(feedingCard.snp.trailing).offset(gap)
            make.width.equalTo(feedingCard)
        }
        diaperCard.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(sleepCard.snp.trailing).offset(gap)
            make.width.equalTo(feedingCard)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(feedingCount: Int, sleepMinutes: Int, diaperCount: Int) {
        feedingCard.configure(
            backgroundColor: .feedingViewColor,
            icon: UIImage(systemName: "fork.knife"),
            title: "Feeding",
            count: feedingCount,
            contentLeadingInset: 20
        )
        sleepCard.configure(
            backgroundColor: .sleepViewColor,
            icon: UIImage(systemName: "moon"),
            title: "Sleep",
            count: sleepMinutes
        )
        sleepCard.countLabel.text = "\(sleepMinutes)m"
        diaperCard.configure(
            backgroundColor: .diaperViewColor,
            icon: UIImage(systemName: "figure.child.circle"),
            title: "Diapers",
            count: diaperCount
        )
    }
}

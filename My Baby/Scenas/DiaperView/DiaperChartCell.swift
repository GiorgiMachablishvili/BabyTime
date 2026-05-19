import UIKit
import SnapKit

final class DiaperChartCell: UICollectionViewCell {
    static let reuseId = "DiaperChartCell"

    private let card = UIView()
    private let chartView = DiaperBarChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.backgroundColor = .white
        card.layer.cornerRadius = 20 * Constraint.yCoeff
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 2)

        contentView.addSubview(card)
        card.addSubview(chartView)

        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        chartView.snp.makeConstraints { $0.edges.equalToSuperview().inset(16 * Constraint.yCoeff) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(days: [DayCount]) {
        chartView.configure(days: days)
    }
}

// MARK: - DiaperBarChartView

private final class DiaperBarChartView: UIView {

    private var days: [DayCount] = []
    private var barViews: [UIView] = []
    private var labelViews: [UILabel] = []

    func configure(days: [DayCount]) {
        self.days = days
        barViews.forEach { $0.removeFromSuperview() }
        labelViews.forEach { $0.removeFromSuperview() }
        barViews = []
        labelViews = []
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !days.isEmpty, barViews.isEmpty else { return }
        buildChart()
    }

    private func buildChart() {
        let count = days.count
        guard count > 0, bounds.width > 0 else { return }

        let maxCount = max(days.max(by: { $0.count < $1.count })?.count ?? 1, 1)
        let labelH: CGFloat = 20 * Constraint.yCoeff
        let chartH = bounds.height - labelH - 8 * Constraint.yCoeff
        let slotW = bounds.width / CGFloat(count)
        let barW = min(slotW * 0.5, 20 * Constraint.xCoeff)

        for (i, day) in days.enumerated() {
            let x = slotW * CGFloat(i) + (slotW - barW) / 2

            // Label
            let label = UILabel()
            label.text = day.symbol
            label.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: day.isToday ? .bold : .regular)
            label.textColor = day.isToday ? UIColor(hexString: "#5aac7c") : UIColor(hexString: "#888888")
            label.textAlignment = .center
            label.frame = CGRect(x: x, y: bounds.height - labelH, width: barW, height: labelH)
            addSubview(label)
            labelViews.append(label)

            // Bar background (track)
            let trackH = chartH * 0.85
            let trackY = (chartH - trackH) / 2
            let track = UIView()
            track.backgroundColor = UIColor(hexString: "#f0f0f0")
            track.layer.cornerRadius = barW / 2
            track.frame = CGRect(x: x, y: trackY, width: barW, height: trackH)
            addSubview(track)
            barViews.append(track)

            // Filled bar
            guard day.count > 0 else { continue }
            let fillH = max(trackH * CGFloat(day.count) / CGFloat(maxCount), 8 * Constraint.yCoeff)
            let fill = UIView()
            fill.backgroundColor = day.isToday ? UIColor(hexString: "#5aac7c") : UIColor(hexString: "#a8dbbe")
            fill.layer.cornerRadius = barW / 2
            fill.frame = CGRect(x: x, y: trackY + trackH - fillH, width: barW, height: fillH)
            addSubview(fill)
            barViews.append(fill)
        }
    }
}

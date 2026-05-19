import UIKit

final class GrowthChartView: UIView {

    var points: [(ageMonths: Double, value: Double)] = [] {
        didSet { setNeedsDisplay() }
    }
    var unit: String = "kg"

    private let accent = UIColor(hexString: "#6557e8")
    private let gridColor = UIColor(white: 0.92, alpha: 1)
    private let labelFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    private let labelColor = UIColor.secondaryLabel

    private let padLeft: CGFloat = 36
    private let padRight: CGFloat = 12
    private let padTop: CGFloat = 12
    private let padBottom: CGFloat = 28

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard !points.isEmpty else {
            drawEmptyState(in: rect)
            return
        }

        let chartRect = CGRect(
            x: padLeft, y: padTop,
            width: rect.width - padLeft - padRight,
            height: rect.height - padTop - padBottom
        )

        let minX = points.map { $0.ageMonths }.min()!
        let maxX = max(points.map { $0.ageMonths }.max()!, minX + 1)
        let rawMinY = points.map { $0.value }.min()!
        let rawMaxY = points.map { $0.value }.max()!
        let pad = (rawMaxY - rawMinY) * 0.2
        let minY = max(0, rawMinY - pad)
        let maxY = rawMaxY + pad

        drawGrid(in: chartRect, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        drawLine(in: chartRect, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        drawXLabels(in: chartRect, minX: minX, maxX: maxX)
    }

    private func drawGrid(in rect: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.setLineWidth(0.5)

        let steps = 4
        for i in 0...steps {
            let y = rect.maxY - CGFloat(i) / CGFloat(steps) * rect.height
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
            ctx.strokePath()

            let val = minY + (maxY - minY) * Double(i) / Double(steps)
            let label = unit == "kg" ? String(format: "%.1f", val) : String(format: "%.0f", val)
            let attrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]
            let size = label.size(withAttributes: attrs)
            label.draw(at: CGPoint(x: rect.minX - size.width - 4, y: y - size.height / 2), withAttributes: attrs)
        }
    }

    private func drawLine(in rect: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) {
        guard points.count >= 1 else { return }
        let ctx = UIGraphicsGetCurrentContext()!

        func pt(_ p: (ageMonths: Double, value: Double)) -> CGPoint {
            let x = rect.minX + CGFloat((p.ageMonths - minX) / (maxX - minX)) * rect.width
            let y = rect.maxY - CGFloat((p.value - minY) / (maxY - minY)) * rect.height
            return CGPoint(x: x, y: y)
        }

        let sorted = points.sorted { $0.ageMonths < $1.ageMonths }

        if sorted.count > 1 {
            // Filled gradient under line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: pt(sorted.first!).x, y: rect.maxY))
            for p in sorted { path.addLine(to: pt(p)) }
            path.addLine(to: CGPoint(x: pt(sorted.last!).x, y: rect.maxY))
            path.close()
            accent.withAlphaComponent(0.08).setFill()
            path.fill()

            // Line
            let linePath = UIBezierPath()
            linePath.move(to: pt(sorted.first!))
            for p in sorted.dropFirst() { linePath.addLine(to: pt(p)) }
            ctx.setStrokeColor(accent.cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            linePath.stroke()
        }

        // Dots
        for p in sorted.dropLast() {
            let c = pt(p)
            ctx.setFillColor(accent.withAlphaComponent(0.4).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6))
        }

        // Last dot (filled + white ring)
        let last = pt(sorted.last!)
        ctx.setFillColor(UIColor.systemBackground.cgColor)
        ctx.fillEllipse(in: CGRect(x: last.x - 6, y: last.y - 6, width: 12, height: 12))
        ctx.setFillColor(accent.cgColor)
        ctx.fillEllipse(in: CGRect(x: last.x - 4, y: last.y - 4, width: 8, height: 8))
    }

    private func drawXLabels(in rect: CGRect, minX: Double, maxX: Double) {
        let attrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]
        let totalMonths = Int(ceil(maxX))
        let step = totalMonths <= 6 ? 1 : (totalMonths <= 12 ? 2 : 3)

        var month = Int(minX)
        while Double(month) <= maxX {
            let x = rect.minX + CGFloat((Double(month) - minX) / (maxX - minX)) * rect.width
            let label = month == 0 ? "Birth" : "\(month)m"
            let size = label.size(withAttributes: attrs)
            label.draw(at: CGPoint(x: x - size.width / 2, y: rect.maxY + 6), withAttributes: attrs)
            month += step
        }
    }

    private func drawEmptyState(in rect: CGRect) {
        let text = "No data yet"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2), withAttributes: attrs)
    }
}

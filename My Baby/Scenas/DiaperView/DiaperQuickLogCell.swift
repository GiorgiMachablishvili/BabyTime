import UIKit
import SnapKit

final class DiaperQuickLogCell: UICollectionViewCell {
    static let reuseId = "DiaperQuickLogCell"

    var onQuickLog: ((DiaperType) -> Void)?

    private lazy var wetButton  = makeButton(type: .wet)
    private lazy var dirtyButton = makeButton(type: .dirty)
    private lazy var mixedButton = makeButton(type: .mixed)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [wetButton, dirtyButton, mixedButton])
        stack.axis = .horizontal
        stack.spacing = 12 * Constraint.xCoeff
        stack.distribution = .fillEqually

        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeButton(type: DiaperType) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16 * Constraint.yCoeff
        container.layer.borderWidth = 1.5
        container.layer.borderColor = UIColor(hexString: "#e8e8e8").cgColor

        let icon = UIImageView(image: UIImage(systemName: type.sfSymbol))
        icon.tintColor = type.accentColor
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = type.badgeTitle
        label.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        label.textColor = UIColor(hexString: "#444444")
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 6 * Constraint.yCoeff
        stack.alignment = .center

        container.addSubview(stack)
        icon.snp.makeConstraints { $0.width.height.equalTo(22 * Constraint.yCoeff) }
        stack.snp.makeConstraints { $0.center.equalToSuperview() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(buttonTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.tag = [DiaperType.wet, .dirty, .mixed].firstIndex(of: type) ?? 0

        return container
    }

    @objc private func buttonTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let types: [DiaperType] = [.wet, .dirty, .mixed]
        guard tag < types.count else { return }
        UIView.animate(withDuration: 0.1, animations: {
            gesture.view?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                gesture.view?.transform = .identity
            }
        }
        onQuickLog?(types[tag])
    }
}

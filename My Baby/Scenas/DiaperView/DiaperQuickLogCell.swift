import UIKit
import SnapKit

final class DiaperQuickLogCell: UICollectionViewCell {
    static let reuseId = "DiaperQuickLogCell"

    var onQuickLog: ((DiaperType) -> Void)?

    private lazy var wetButton   = makeButton(type: .wet)
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
        container.layer.cornerRadius = 18 * Constraint.yCoeff
        container.layer.shadowColor  = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius  = 6
        container.layer.shadowOffset  = CGSize(width: 0, height: 2)
        // Shadow needs masksToBounds = false; clip via sublayer if needed
        container.clipsToBounds = false

        // Icon
        let icon = UIImageView(image: UIImage(systemName: type.sfSymbol))
        icon.tintColor = type.accentColor
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false

        // "+" badge — top-right of the icon
        let badge = UIView()
        badge.backgroundColor = type.accentColor
        badge.layer.cornerRadius = 9 * Constraint.yCoeff
        badge.isUserInteractionEnabled = false

        let plusLbl = UILabel()
        plusLbl.text = "+"
        plusLbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        plusLbl.textColor = .white
        plusLbl.textAlignment = .center
        plusLbl.isUserInteractionEnabled = false
        badge.addSubview(plusLbl)
        plusLbl.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Rounded clip view so corner radius applies without losing shadow on container
        let clipView = UIView()
        clipView.backgroundColor = .white
        clipView.layer.cornerRadius = 18 * Constraint.yCoeff
        clipView.clipsToBounds = true
        container.addSubview(clipView)
        clipView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Label
        let label = UILabel()
        label.text = type.badgeTitle
        label.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        label.textColor = UIColor(hexString: "#444444")
        label.textAlignment = .center
        label.isUserInteractionEnabled = false

        clipView.addSubview(icon)
        container.addSubview(badge)   // added to container (above clipView) so shadow doesn't clip it
        clipView.addSubview(label)

        icon.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-12 * Constraint.yCoeff)
            $0.width.height.equalTo(30 * Constraint.yCoeff)
        }
        badge.snp.makeConstraints {
            $0.width.height.equalTo(18 * Constraint.yCoeff)
            $0.leading.equalTo(icon.snp.trailing).offset(-6 * Constraint.xCoeff)
            $0.top.equalTo(icon).offset(-6 * Constraint.yCoeff)
        }
        label.snp.makeConstraints {
            $0.top.equalTo(icon.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(4 * Constraint.xCoeff)
            $0.bottom.lessThanOrEqualToSuperview().inset(12 * Constraint.yCoeff)
        }

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

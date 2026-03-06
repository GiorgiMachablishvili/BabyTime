
import UIKit
import SnapKit

final class DiaperLogCell: UICollectionViewCell {
    static let reuseId = "DiaperLogCell"

    var onDelete: (() -> Void)?

    private let deleteStripWidth: CGFloat = 80

    private lazy var deleteStripView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.isHidden = true
        view.makeRoundCorners(16)
        return view
    }()

    private lazy var deleteLabel: UILabel = {
        let view = UILabel()
        view.text = "Delete"
        view.font = .systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .white
        view.textAlignment = .center
        return view
    }()

    private lazy var cardWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private let card = UIView()
    private let iconContainer = UIView()
    private let iconLabel = UILabel()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let timeLabel = UILabel()
    private let dateLabel = UILabel()

    private let textStack = UIStackView()
    private let rightStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true

        contentView.addSubview(deleteStripView)
        deleteStripView.addSubview(deleteLabel)
        contentView.addSubview(cardWrapperView)
        cardWrapperView.addSubview(card)

        card.backgroundColor = .white
        card.layer.cornerRadius = 16

        iconContainer.layer.cornerRadius = 16
        iconLabel.font = .systemFont(ofSize: 22)
        iconLabel.textAlignment = .center

        iconContainer.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        timeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        timeLabel.textAlignment = .right

        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .right

        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing
        rightStack.addArrangedSubview(timeLabel)
        rightStack.addArrangedSubview(dateLabel)

        card.addSubview(iconContainer)
        card.addSubview(textStack)
        card.addSubview(rightStack)

        deleteStripView.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.width.equalTo(deleteStripWidth)
        }
        deleteLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        cardWrapperView.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(56 * Constraint.yCoeff)
            $0.height.equalTo(56 * Constraint.xCoeff)
        }

        rightStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
        }

        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(14 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(rightStack.snp.leading).offset(-12 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
        }

        setupSwipeGesture()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetSwipe(animated: false)
        onDelete = nil
    }

    private func setupSwipeGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        cardWrapperView.addGestureRecognizer(pan)
        cardWrapperView.isUserInteractionEnabled = true
        let tapDelete = UITapGestureRecognizer(target: self, action: #selector(deleteTapped))
        deleteStripView.addGestureRecognizer(tapDelete)
        deleteStripView.isUserInteractionEnabled = true
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let deltaX = gesture.translation(in: cardWrapperView).x
        let currentX = cardWrapperView.transform.tx
        switch gesture.state {
        case .changed:
            let newX = max(-deleteStripWidth, min(0, currentX + deltaX))
            cardWrapperView.transform = CGAffineTransform(translationX: newX, y: 0)
            gesture.setTranslation(.zero, in: cardWrapperView)
            deleteStripView.isHidden = (newX >= 0)
        case .ended, .cancelled:
            let finalX = max(-deleteStripWidth, min(0, currentX + deltaX))
            cardWrapperView.transform = CGAffineTransform(translationX: finalX, y: 0)
            gesture.setTranslation(.zero, in: cardWrapperView)
            if finalX < -deleteStripWidth / 2 {
                revealDelete(animated: true)
                deleteStripView.isHidden = false
            } else {
                resetSwipe(animated: true)
                deleteStripView.isHidden = true
            }
        default:
            break
        }
    }

    @objc private func deleteTapped() { onDelete?() }

    private func revealDelete(animated: Bool) {
        let work = { self.cardWrapperView.transform = CGAffineTransform(translationX: -self.deleteStripWidth, y: 0) }
        if animated { UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: work) } else { work() }
    }

    private func resetSwipe(animated: Bool) {
        let work = {
            self.cardWrapperView.transform = .identity
            self.deleteStripView.isHidden = true
        }
        if animated { UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: work) } else { work() }
    }

    func configure(item: DiaperLogItem) {
        iconContainer.backgroundColor = item.type.iconBackground
        iconLabel.text = item.type.iconText
        titleLabel.text = item.type.title

        let note = (item.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        subtitleLabel.text = note.isEmpty ? item.type.subtitleFallback : note

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        timeLabel.text = timeFormatter.string(from: item.date)
        dateLabel.text = dateFormatter.string(from: item.date)
    }
}

extension DiaperLogCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: cardWrapperView)
        return abs(v.x) > abs(v.y)
    }
}

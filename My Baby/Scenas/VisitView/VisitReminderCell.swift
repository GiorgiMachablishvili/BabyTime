import UIKit
import SnapKit

final class VisitReminderCell: UICollectionViewCell {

    static let reuseId = "VisitReminderCell"
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    private let deleteStripWidth: CGFloat = 80

    private lazy var deleteStripView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.isHidden = true
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
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

    private lazy var card: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private lazy var dateLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 17, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var noteLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.textColor = .secondaryLabel
        view.numberOfLines = 2
        return view
    }()

    private lazy var daysLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12, weight: .medium)
        view.textColor = .tertiaryLabel
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(deleteStripView)
        deleteStripView.addSubview(deleteLabel)
        contentView.addSubview(cardWrapperView)
        cardWrapperView.addSubview(card)
        card.addSubview(dateLabel)
        card.addSubview(noteLabel)
        card.addSubview(daysLabel)

        deleteStripView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(deleteStripWidth)
        }
        deleteLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        cardWrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        dateLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(14 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-14 * Constraint.yCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(dateLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-14 * Constraint.yCoeff)
        }
        daysLabel.snp.makeConstraints {
            $0.top.equalTo(noteLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(dateLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-14 * Constraint.xCoeff)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        card.addGestureRecognizer(tap)
        setupSwipeGesture()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                    self.cardWrapperView.transform = CGAffineTransform(translationX: -self.deleteStripWidth, y: 0)
                }
                deleteStripView.isHidden = false
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                    self.cardWrapperView.transform = .identity
                    self.deleteStripView.isHidden = true
                }
            }
        default:
            break
        }
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    @objc private func tapped() {
        onTap?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardWrapperView.transform = .identity
        deleteStripView.isHidden = true
        onDelete = nil
    }

    func configure(visit: VisitReminder, accentColor: UIColor) {
        if let time = visit.timeString {
            dateLabel.text = "\(visit.shortDateString) at \(time)"
        } else {
            dateLabel.text = visit.dateString
        }
        noteLabel.text = visit.note.isEmpty ? "No note" : visit.note
        if visit.notifyDaysBefore.isEmpty {
            daysLabel.text = ""
            daysLabel.isHidden = true
        } else {
            daysLabel.isHidden = false
            let days = visit.notifyDaysBefore.sorted()
            daysLabel.text = "Notify \(days.map { "\($0)d" }.joined(separator: ", ")) before"
        }
    }
}

extension VisitReminderCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: cardWrapperView)
        return abs(v.x) > abs(v.y)
    }
}

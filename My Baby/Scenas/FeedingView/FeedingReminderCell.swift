import UIKit
import SnapKit

final class FeedingReminderCell: UICollectionViewCell {

    static let reuseId = "FeedingReminderCell"

    /// Called when user taps the circle to mark as fed (move to history).
    var onCircleTap: (() -> Void)?
    var onTap: (() -> Void)?

    private lazy var card: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private lazy var circleButton: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .clear
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.feedingViewColor.cgColor
        view.clipsToBounds = true
        return view
    }()

    private lazy var circleFilled: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private lazy var typeLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var timeLabel: UILabel = {
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(card)
        card.addSubview(circleButton)
        circleButton.addSubview(circleFilled)
        card.addSubview(typeLabel)
        card.addSubview(timeLabel)
        card.addSubview(noteLabel)

        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        circleButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(36 * Constraint.yCoeff)
            $0.height.equalTo(36 * Constraint.xCoeff)
        }
        circleFilled.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(24 * Constraint.yCoeff)
            $0.height.equalTo(24 * Constraint.xCoeff)
        }
        typeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(circleButton.snp.trailing).offset(14 * Constraint.yCoeff)
        }
        timeLabel.snp.makeConstraints {
            $0.centerY.equalTo(typeLabel)
            $0.leading.equalTo(typeLabel.snp.trailing).offset(8 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-14 * Constraint.yCoeff)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalTo(typeLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(typeLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-14 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().offset(-14 * Constraint.xCoeff)
        }

        circleButton.addTarget(self, action: #selector(circleTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func circleTapped() {
        circleFilled.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.circleFilled.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.circleFilled.transform = .identity
            }) { _ in
                self.onCircleTap?()
            }
        }
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: card)
        if circleButton.frame.contains(loc) { return }
        onTap?()
    }

    func configure(reminder: FeedingReminder) {
        switch reminder.feedingType {
        case .breast: typeLabel.text = "Breast"
        case .bottle: typeLabel.text = "Bottle"
        case .formula: typeLabel.text = "Formula"
        case .solid: typeLabel.text = "Solid"
        }
        let isToday = Calendar.current.isDateInToday(reminder.date)
        timeLabel.text = isToday ? reminder.timeString : "\(reminder.dateString), \(reminder.timeString)"
        noteLabel.text = reminder.note.isEmpty ? "No note" : reminder.note
        circleFilled.isHidden = true
    }
}

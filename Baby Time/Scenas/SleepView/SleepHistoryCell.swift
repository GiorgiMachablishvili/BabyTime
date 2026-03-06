import UIKit
import SnapKit

final class SleepHistoryCell: UICollectionViewCell {

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

    private lazy var contentCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        return view
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        return view
    }()

    private lazy var iconBox: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.25)
        view.layer.cornerRadius = 14
        return view
    }()

    private lazy var iconImage: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UIImage(systemName: "moon")
        view.tintColor = .white
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Sleep"
        view.font = .systemFont(ofSize: 20, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 16)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 18, weight: .semibold)
        view.textAlignment = .right
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()

    private lazy var dateLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 15)
        view.textAlignment = .right
        view.textColor = .secondaryLabel
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true

        setupUI()
        setupConstraints()
        setupSwipeGesture()
        configureViews()
        setContentVisibility(isEmpty: true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetSwipe(animated: false)
        onDelete = nil
    }

    private func setupUI() {
        contentView.addSubview(deleteStripView)
        deleteStripView.addSubview(deleteLabel)
        contentView.addSubview(cardWrapperView)
        cardWrapperView.addSubview(contentCard)
        contentCard.addSubview(emptyStateView)
        contentCard.addSubview(iconBox)
        iconBox.addSubview(iconImage)
        contentCard.addSubview(titleLabel)
        contentCard.addSubview(subtitleLabel)
        contentCard.addSubview(timeLabel)
        contentCard.addSubview(dateLabel)
    }

    private func setupConstraints() {
        deleteStripView.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.width.equalTo(deleteStripWidth)
        }
        deleteLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        cardWrapperView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentCard.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyStateView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180 * Constraint.xCoeff)
        }

        iconBox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(18 * Constraint.yCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(60 * Constraint.yCoeff)
            $0.height.equalTo(60 * Constraint.xCoeff)
        }

        iconImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(26 * Constraint.yCoeff)
            $0.height.equalTo(26 * Constraint.xCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18 * Constraint.xCoeff)
            $0.leading.equalTo(iconBox.snp.trailing).offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12 * Constraint.yCoeff)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalToSuperview().offset(-18 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12 * Constraint.yCoeff)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18 * Constraint.xCoeff)
            $0.trailing.equalToSuperview().offset(-18 * Constraint.yCoeff)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.trailing.equalTo(timeLabel)
        }
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

    private func configureViews() {
        emptyStateView.configure(
            icon: UIImage(systemName: "fork.knife"),
            iconTint: .sleepViewColor.withAlphaComponent(0.95),
            circleColor: .sleepViewColor.withAlphaComponent(0.40),
            title: "No feedings yet",
            subtitle: "Tap the + button to log a feeding"
        )
    }

    private func setContentVisibility(isEmpty: Bool) {
        emptyStateView.isHidden = !isEmpty
        iconBox.isHidden = isEmpty
        iconImage.isHidden = isEmpty
        titleLabel.isHidden = isEmpty
        subtitleLabel.isHidden = isEmpty
        timeLabel.isHidden = isEmpty
        dateLabel.isHidden = isEmpty
    }

    func configure(statusText: String, timeText: String, dateText: String) {
        subtitleLabel.text = statusText
        timeLabel.text = timeText
        dateLabel.text = dateText
        setContentVisibility(isEmpty: false)
    }

    func configureEmpty() {
        setContentVisibility(isEmpty: true)
    }
}

extension SleepHistoryCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: cardWrapperView)
        return abs(v.x) > abs(v.y)
    }
}

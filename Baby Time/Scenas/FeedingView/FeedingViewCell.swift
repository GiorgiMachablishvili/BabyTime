import UIKit
import SnapKit

class FeedingViewCell: UICollectionViewCell {

    /// Callback when user taps Delete after swiping. View controller should remove the item.
    var onDelete: (() -> Void)?

    private let deleteStripWidth: CGFloat = 80

    // MARK: - Swipe / Delete strip (hidden until swipe; full cell height)
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

    // MARK: - Subviews
    private lazy var backgroundCard: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.makeRoundCorners(16)
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var iconContainer: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.feedingViewColor.withAlphaComponent(0.9)
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.tintColor = .white
        view.image = UIImage(systemName: "leaf")
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 16, weight: .semibold)
        view.textColor = .label
        view.text = "Solid Food"
        return view
    }()

//    private lazy var subtitleLabel: UILabel = {
//        let view = UILabel(frame: .zero)
//        view.font = .systemFont(ofSize: 14, weight: .regular)
//        view.textColor = UIColor.brown.withAlphaComponent(0.8)
//        view.text = "90 ml • apple"
//        view.numberOfLines = 1
//        view.lineBreakMode = .byTruncatingTail
//        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
//        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        return view
//    }()

    private lazy var amountFeedLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.textColor = UIColor.brown.withAlphaComponent(0.8)
        view.text = "90 ml"
        view.numberOfLines = 1
        view.lineBreakMode = .byTruncatingTail
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }()

    private lazy var noteInfoLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.textColor = UIColor.brown.withAlphaComponent(0.8)
        view.text = "apple"
        view.numberOfLines = 1
        view.lineBreakMode = .byTruncatingTail
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 15, weight: .semibold)
        view.textColor = UIColor.brown.withAlphaComponent(0.9)
        view.textAlignment = .right
        view.text = "11:28 AM"
        return view
    }()


    private lazy var dateLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 13, weight: .regular)
        view.textColor = UIColor.brown.withAlphaComponent(0.7)
        view.textAlignment = .right
        view.text = "Dec 26"
        return view
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        setupUI()
        setupConstraints()
        setupSwipeGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        amountFeedLabel.text = nil
        noteInfoLabel.text = nil
        timeLabel.text = nil
        dateLabel.text = nil
        iconView.image = nil
        iconContainer.backgroundColor = UIColor.feedingViewColor.withAlphaComponent(0.9)
        resetSwipe(animated: false)
        onDelete = nil
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(deleteStripView)
        deleteStripView.addSubview(deleteLabel)
        contentView.addSubview(cardWrapperView)
        cardWrapperView.addSubview(backgroundCard)
        backgroundCard.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        backgroundCard.addSubview(titleLabel)
//        backgroundCard.addSubview(subtitleLabel)
        backgroundCard.addSubview(amountFeedLabel)
        backgroundCard.addSubview(noteInfoLabel)
        backgroundCard.addSubview(timeLabel)
        backgroundCard.addSubview(dateLabel)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupConstraints() {
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
        backgroundCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        // Right-side time/date stack
        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().inset(16)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(2)
            make.trailing.equalTo(timeLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }

        // Title and subtitle in the middle, constrained between icon and time
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12)
        }

//        subtitleLabel.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(4)
//            make.leading.equalTo(titleLabel)
//            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12)
//            make.bottom.lessThanOrEqualToSuperview().inset(12)
//        }

        amountFeedLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }

        noteInfoLabel.snp.remakeConstraints { make in
            make.top.equalTo(amountFeedLabel.snp.top)
            make.leading.equalTo(amountFeedLabel.snp.trailing).offset(4)
            make.bottom.equalTo(amountFeedLabel)
        }
    }

    // MARK: - Swipe to delete
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

    @objc private func deleteTapped() {
        onDelete?()
    }

    private func revealDelete(animated: Bool) {
        let work = {
            self.cardWrapperView.transform = CGAffineTransform(translationX: -self.deleteStripWidth, y: 0)
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: work)
        } else {
            work()
        }
    }

    private func resetSwipe(animated: Bool) {
        let work = {
            self.cardWrapperView.transform = .identity
            self.deleteStripView.isHidden = true
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: work)
        } else {
            work()
        }
    }

    // MARK: - Public API
    struct ViewModel {
        enum FeedingType {
            case breast, bottle, formula, solid
        }
        let type: FeedingType
        let volumeText: String?   // e.g. "90 ml" for bottle/formula/solid
        let notesText: String?    // e.g. "apple"
        let timeText: String      // e.g. "11:28 AM"
        let dateText: String      // e.g. "Dec 26"
    }

    func configure(with vm: ViewModel) {
        switch vm.type {
        case .breast:
            titleLabel.text = "Breast"
            iconView.image = UIImage(systemName: "figure.seated.side.right.child.lap")
            iconContainer.backgroundColor = UIColor.systemPink.withAlphaComponent(0.9)
        case .bottle:
            titleLabel.text = "Bottle"
            iconView.image = UIImage(systemName: "waterbottle")
            iconContainer.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.9)
        case .formula:
            titleLabel.text = "Formula"
            iconView.image = UIImage(systemName: "flask")
            iconContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
        case .solid:
            titleLabel.text = "Solid Food"
            iconView.image = UIImage(systemName: "carrot")
            iconContainer.backgroundColor = UIColor.feedingViewColor.withAlphaComponent(0.9)
        }

        if let vol = vm.volumeText, !vol.isEmpty, let notes = vm.notesText, !notes.isEmpty {
            amountFeedLabel.text = vol
            amountFeedLabel.isHidden = false
            noteInfoLabel.text = " • \(notes)"
            noteInfoLabel.isHidden = false
        } else if let vol = vm.volumeText, !vol.isEmpty {
            amountFeedLabel.text = vol
            amountFeedLabel.isHidden = false
            noteInfoLabel.isHidden = true
        } else if let notes = vm.notesText, !notes.isEmpty {
            amountFeedLabel.isHidden = true
            noteInfoLabel.text = notes
            noteInfoLabel.isHidden = false
        } else {
            amountFeedLabel.isHidden = (vm.type == .breast)
            amountFeedLabel.text = vm.volumeText
            noteInfoLabel.isHidden = true
        }

        timeLabel.text = vm.timeText
        dateLabel.text = vm.dateText
    }
}

extension FeedingViewCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let v = pan.velocity(in: cardWrapperView)
        return abs(v.x) > abs(v.y)
    }
}

import UIKit
import SnapKit

class FeedingView: UIView {

    var onTapCloseButton: (() -> Void)?
    var onTapSave: ((FeedingTypeView.FeedingType, String?, String?, String, String) -> Void)? // (type, volumeText, notesText, timeText, dateText)
    private var feedingViewHeightConstraint: SnapKit.Constraint? = nil
    private var notesTopToTimeConstraint: SnapKit.Constraint? = nil
    private var notesTopToVolumeConstraint: SnapKit.Constraint? = nil
    
    private var currentFeedingType: FeedingTypeView.FeedingType = .breast

    private lazy var blurEffectView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .gray.withAlphaComponent(0.9)
        return view
    }()

    private lazy var feedingView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .onDrag
        view.alwaysBounceVertical = true
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var addFeedingTitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Add Feeding"
        view.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var closeFeedingViewButton: UIButton = {
        let view = UIButton(frame: .zero)
        let image = UIImage(systemName: "xmark.circle")!
        view.setImage(image, for: .normal)
        view.tintColor = .label
        view.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return view
    }()

    private lazy var feedingTypeView: FeedingTypeView = {
        let view = FeedingTypeView()
        return view
    }()

    private lazy var selectedTypeBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 22 * Constraint.yCoeff
        v.clipsToBounds = true
        v.isHidden = true
        return v
    }()

    private lazy var selectedTypeBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private lazy var timeButtonView: TimeButtonView = {
        let view = TimeButtonView()
        return view
    }()

    private lazy var volumeButtonView: VolumeButtonView = {
        let v = VolumeButtonView()
        v.isHidden = true
        return v
    }()

    private lazy var notesOptionalView: NotesOptionalView = {
        let view = NotesOptionalView()
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.makeRoundCorners(12)
        view.setTitle("Save", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        view.setTitleColor(.labelWhiteColor, for: .normal)
        view.backgroundColor = .pressButtonColor
        view.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupUI()
        setupConstraint()
        setupKeyboardObservers()
        feedingTypeView.onTypeChanged = { [weak self] type in
            guard let self = self else { return }
            self.currentFeedingType = type
            switch type {
            case .breast:
                self.timeButtonView.isHidden = false
                self.volumeButtonView.isHidden = true
                self.feedingViewHeightConstraint?.update(offset: 600 * Constraint.xCoeff)
                self.notesTopToVolumeConstraint?.deactivate()
                self.notesTopToTimeConstraint?.activate()
            case .bottle, .formula, .solid:
                self.timeButtonView.isHidden = true
                self.volumeButtonView.isHidden = false
                self.feedingViewHeightConstraint?.update(offset: 600 * Constraint.xCoeff)
                self.notesTopToTimeConstraint?.deactivate()
                self.notesTopToVolumeConstraint?.activate()
            }
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        addSubview(blurEffectView)
        addSubview(feedingView)
        feedingView.addSubview(addFeedingTitleLabel)
        feedingView.addSubview(closeFeedingViewButton)
        feedingView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(feedingTypeView)
        contentView.addSubview(selectedTypeBadge)
        selectedTypeBadge.addSubview(selectedTypeBadgeLabel)
        contentView.addSubview(timeButtonView)
        contentView.addSubview(volumeButtonView)
        contentView.addSubview(notesOptionalView)
        contentView.addSubview(saveButton)
    }

    private func setupConstraint() {
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        feedingView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            self.feedingViewHeightConstraint = make.height.equalTo(600 * Constraint.xCoeff).constraint
        }

        addFeedingTitleLabel.snp.remakeConstraints { make in
            make.top.leading.equalTo(feedingView).inset(10 * Constraint.xCoeff)
        }

        closeFeedingViewButton.snp.remakeConstraints { make in
            make.top.equalTo(feedingView.snp.top).offset(10 * Constraint.xCoeff)
            make.trailing.equalTo(feedingView.snp.trailing).offset(-10 * Constraint.yCoeff)
            make.height.width.equalTo(44 * Constraint.xCoeff)
        }

        scrollView.snp.remakeConstraints { make in
            make.top.equalTo(addFeedingTitleLabel.snp.bottom).offset(8 * Constraint.xCoeff)
            make.leading.trailing.bottom.equalTo(feedingView)
        }

        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        feedingTypeView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(12 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100 * Constraint.xCoeff)
        }

        selectedTypeBadge.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(28 * Constraint.xCoeff)
            make.centerX.equalToSuperview()
            make.height.equalTo(44 * Constraint.yCoeff)
        }
        selectedTypeBadgeLabel.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
        }

        timeButtonView.snp.remakeConstraints { make in
            make.top.equalTo(feedingTypeView.snp.bottom).offset(20 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }

        volumeButtonView.snp.remakeConstraints { make in
            make.top.equalTo(feedingTypeView.snp.bottom).offset(20 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }

        notesOptionalView.snp.remakeConstraints { make in
            self.notesTopToTimeConstraint = make.top.equalTo(timeButtonView.snp.bottom).offset(20 * Constraint.xCoeff).constraint
            self.notesTopToVolumeConstraint = make.top.equalTo(volumeButtonView.snp.bottom).offset(20 * Constraint.xCoeff).constraint
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }
        notesTopToVolumeConstraint?.deactivate()

        saveButton.snp.remakeConstraints { make in
            make.top.equalTo(notesOptionalView.snp.bottom).offset(20 * Constraint.yCoeff)
            make.leading.trailing.equalToSuperview().inset(30 * Constraint.yCoeff)
            make.height.equalTo(50 * Constraint.xCoeff)
            make.bottom.equalTo(contentView).offset(-24 * Constraint.xCoeff)
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = frame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let notesFrame = self.notesOptionalView.convert(self.notesOptionalView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(notesFrame.insetBy(dx: 0, dy: -80), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.layoutIfNeeded()
        }
    }

    private func currentTimeText() -> String {
        // If TimeButtonView exposes a selected time string, use it; otherwise fallback to now
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private func currentDateText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func currentVolumeText() -> String? {
        if currentFeedingType == .breast {
            return timeButtonView.selectedDurationText
        }
        return volumeButtonView.selectedVolumeText
    }

    private func currentNotesText() -> String? {
        let s = notesOptionalView.notesText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }

    @objc private func saveButtonTapped() {
        let type = currentFeedingType
        let volume = currentVolumeText()
        let notes = currentNotesText()
        let time = currentTimeText()
        let date = currentDateText()
        onTapSave?(type, volume, notes, time, date)
        // Optionally close
        self.onTapCloseButton?()
    }

    @objc private func closeButtonTapped() {
        self.onTapCloseButton?()
    }

    func configure(initialType: FeedingTypeView.FeedingType, showTypePicker: Bool = true) {
        timeButtonView.reset()
        volumeButtonView.reset()
        notesOptionalView.reset()
        currentFeedingType = initialType

        feedingTypeView.isHidden = !showTypePicker
        feedingTypeView.setSelectedType(initialType)

        selectedTypeBadge.isHidden = showTypePicker
        if !showTypePicker {
            switch initialType {
            case .breast:
                selectedTypeBadgeLabel.text = "Start Breast"
                selectedTypeBadge.backgroundColor = UIColor(hexString: "#e07a5f")
            case .bottle:
                selectedTypeBadgeLabel.text = "Bottle"
                selectedTypeBadge.backgroundColor = UIColor(hexString: "#9b7fd4")
            case .formula:
                selectedTypeBadgeLabel.text = "Formula"
                selectedTypeBadge.backgroundColor = UIColor(hexString: "#4a9fc4")
            case .solid:
                selectedTypeBadgeLabel.text = "Solid"
                selectedTypeBadge.backgroundColor = UIColor(hexString: "#5aac7c")
            }
        }

        // Re-anchor input views depending on whether the type picker is visible
        let topAnchor = showTypePicker ? feedingTypeView.snp.bottom : selectedTypeBadge.snp.bottom

        timeButtonView.snp.remakeConstraints { make in
            make.top.equalTo(topAnchor).offset(20 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }
        volumeButtonView.snp.remakeConstraints { make in
            make.top.equalTo(topAnchor).offset(20 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }
        notesOptionalView.snp.remakeConstraints { make in
            self.notesTopToTimeConstraint   = make.top.equalTo(timeButtonView.snp.bottom).offset(20 * Constraint.xCoeff).constraint
            self.notesTopToVolumeConstraint = make.top.equalTo(volumeButtonView.snp.bottom).offset(20 * Constraint.xCoeff).constraint
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(140 * Constraint.xCoeff)
        }

        let sheetHeight: CGFloat = showTypePicker ? 600 : 470

        switch initialType {
        case .breast:
            timeButtonView.isHidden = false
            volumeButtonView.isHidden = true
            feedingViewHeightConstraint?.update(offset: sheetHeight * Constraint.xCoeff)
            notesTopToVolumeConstraint?.deactivate()
            notesTopToTimeConstraint?.activate()
        case .bottle, .formula, .solid:
            timeButtonView.isHidden = true
            volumeButtonView.isHidden = false
            feedingViewHeightConstraint?.update(offset: sheetHeight * Constraint.xCoeff)
            notesTopToTimeConstraint?.deactivate()
            notesTopToVolumeConstraint?.activate()
        }
        layoutIfNeeded()
    }
}

import UIKit
import SnapKit

// MARK: - FeedingView (slide-up sheet)

class FeedingView: UIView {

    // MARK: - Callbacks (same signature as before so FeedingViewController needs no changes)
    var onTapCloseButton: (() -> Void)?
    var onTapSave: ((FeedingTypeView.FeedingType, String?, String?, String, String) -> Void)?

    // MARK: - Internal state
    private var currentFeedingType: FeedingTypeView.FeedingType = .breast
    private var selectedSide: BreastSide = .left

    // Timer state
    private var elapsedSeconds: Int = 0
    private var timerIsRunning = false
    private var countTimer: Timer?

    // MARK: - Sub-views: sheet container
    private lazy var handleBar: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private lazy var dimView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    private lazy var sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .cardBackground
        v.layer.cornerRadius = 0
        v.layer.masksToBounds = false
        return v
    }()

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.keyboardDismissMode = .onDrag
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()

    private lazy var contentView = UIView()

    // MARK: - Header row
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        l.text = "Breast Feeding"
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        b.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        b.tintColor = .secondaryLabel
        b.backgroundColor = UIColor.systemGray5
        b.layer.cornerRadius = 15
        b.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Breast side selector
    private lazy var sideContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .fieldBackground
        v.layer.cornerRadius = 14
        return v
    }()

    private lazy var leftButton: UIButton = makeSideButton(title: "👶 Left", side: .left)
    private lazy var rightButton: UIButton = makeSideButton(title: "Right 👶", side: .right)

    private func makeSideButton(title: String, side: BreastSide) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.layer.cornerRadius = 10
        b.tag = side == .left ? 0 : 1
        b.addTarget(self, action: #selector(sideTapped(_:)), for: .touchUpInside)
        return b
    }

    // MARK: - Timer display
    private lazy var timerCircle: UIView = {
        let v = UIView()
        v.backgroundColor = .viewsBackGourdColor
        v.layer.cornerRadius = 80 * Constraint.xCoeff
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor.brandPrimary.cgColor
        return v
    }()

    private lazy var timerLabel: UILabel = {
        let l = UILabel()
        l.text = "00:00"
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 44 * Constraint.xCoeff, weight: .thin)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private lazy var sideIndicatorLabel: UILabel = {
        let l = UILabel()
        l.text = "Left breast"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .brandPrimary
        l.textAlignment = .center
        return l
    }()

    // MARK: - Timer controls
    private lazy var startPauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = .brandPrimary
        b.layer.cornerRadius = 28 * Constraint.xCoeff
        b.tintColor = .white
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        b.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
        b.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        return b
    }()

    private lazy var resetButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemGray5
        b.layer.cornerRadius = 22 * Constraint.xCoeff
        b.tintColor = .secondaryLabel
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        b.setImage(UIImage(systemName: "arrow.counterclockwise", withConfiguration: cfg), for: .normal)
        b.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        return b
    }()

    // Duration label shown below controls
    private lazy var durationHintLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap ▶ to start the timer"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        return l
    }()

    // MARK: - Volume section (bottle / formula / solid)
    private lazy var volumeView: VolumeButtonView = {
        let v = VolumeButtonView()
        v.isHidden = true
        return v
    }()

    // MARK: - Notes
    private lazy var notesCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .fieldBackground
        v.layer.cornerRadius = 14
        return v
    }()

    private lazy var notesLabel: UILabel = {
        let l = UILabel()
        l.text = "Notes"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var notesTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = .label
        tv.isScrollEnabled = false
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = self
        return tv
    }()

    private lazy var notesPlaceholder: UILabel = {
        let l = UILabel()
        l.text = "Add a note…"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .tertiaryLabel
        return l
    }()

    // MARK: - Save button
    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(hexString: "#7B5FE6")
        b.layer.cornerRadius = 16
        b.setTitle("Save Session", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
        setupConstraints()
        setupKeyboardObservers()
        updateSideSelection(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(dimView)
        addSubview(sheetView)
        sheetView.addSubview(handleBar)
        sheetView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Header
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)

        // Breast UI
        contentView.addSubview(sideContainer)
        sideContainer.addSubview(leftButton)
        sideContainer.addSubview(rightButton)

        contentView.addSubview(timerCircle)
        timerCircle.addSubview(timerLabel)
        timerCircle.addSubview(sideIndicatorLabel)

        contentView.addSubview(startPauseButton)
        contentView.addSubview(resetButton)
        contentView.addSubview(durationHintLabel)

        // Volume UI (other feeding types)
        contentView.addSubview(volumeView)

        // Notes
        contentView.addSubview(notesCardView)
        notesCardView.addSubview(notesLabel)
        notesCardView.addSubview(notesTextView)
        notesTextView.addSubview(notesPlaceholder)

        contentView.addSubview(saveButton)
    }

    private func setupConstraints() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        sheetView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        handleBar.snp.makeConstraints {
            $0.top.equalTo(sheetView.safeAreaLayoutGuide).offset(10 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(sheetView.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Header
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(24 * Constraint.xCoeff)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.width.height.equalTo(30)
        }

        // Side selector
        sideContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.height.equalTo(48 * Constraint.xCoeff)
        }

        leftButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalToSuperview().inset(4)
            $0.trailing.equalTo(sideContainer.snp.centerX).offset(-2)
        }

        rightButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.trailing.equalToSuperview().inset(4)
            $0.leading.equalTo(sideContainer.snp.centerX).offset(2)
        }

        // Timer circle
        let circleSize: CGFloat = 160 * Constraint.xCoeff
        timerCircle.snp.makeConstraints {
            $0.top.equalTo(sideContainer.snp.bottom).offset(28 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(circleSize)
        }
        timerCircle.layer.cornerRadius = circleSize / 2

        timerLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-8 * Constraint.xCoeff)
        }

        sideIndicatorLabel.snp.makeConstraints {
            $0.top.equalTo(timerLabel.snp.bottom).offset(2 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
        }

        // Controls
        startPauseButton.snp.makeConstraints {
            $0.top.equalTo(timerCircle.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(56 * Constraint.xCoeff)
        }

        resetButton.snp.makeConstraints {
            $0.centerY.equalTo(startPauseButton)
            $0.leading.equalTo(startPauseButton.snp.trailing).offset(20 * Constraint.xCoeff)
            $0.width.height.equalTo(44 * Constraint.xCoeff)
        }

        durationHintLabel.snp.makeConstraints {
            $0.top.equalTo(startPauseButton.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
        }

        // Volume (hidden for breast)
        volumeView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.height.equalTo(150 * Constraint.xCoeff)
        }

        // Notes card
        notesCardView.snp.makeConstraints {
            $0.top.equalTo(durationHintLabel.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
        }
        notesLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
        }
        notesTextView.snp.makeConstraints {
            $0.top.equalTo(notesLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview().inset(14)
            $0.height.greaterThanOrEqualTo(60)
        }
        notesPlaceholder.snp.makeConstraints {
            $0.top.leading.equalTo(notesTextView)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(notesCardView.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.height.equalTo(54 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(32 * Constraint.xCoeff)
        }
    }

    // MARK: - Public configure

    func configure(initialType: FeedingTypeView.FeedingType, showTypePicker: Bool = true) {
        currentFeedingType = initialType

        // Stop and reset any running timer
        stopTimer()
        resetTimerState()

        switch initialType {
        case .breast:
            titleLabel.text = "Breast Feeding"
            sideContainer.isHidden = false
            timerCircle.isHidden = false
            startPauseButton.isHidden = false
            resetButton.isHidden = false
            durationHintLabel.isHidden = false
            volumeView.isHidden = true
            saveButton.setTitle("Save Session", for: .normal)
            // notes anchor to hint label (breast layout)
            notesCardView.snp.remakeConstraints {
                $0.top.equalTo(durationHintLabel.snp.bottom).offset(20 * Constraint.xCoeff)
                $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            }
        case .bottle, .formula, .solid:
            let typeName: String
            switch initialType {
            case .bottle: typeName = "Bottle Feeding"
            case .formula: typeName = "Formula Feeding"
            case .solid: typeName = "Solid Food"
            default: typeName = "Feeding"
            }
            titleLabel.text = typeName
            sideContainer.isHidden = true
            timerCircle.isHidden = true
            startPauseButton.isHidden = true
            resetButton.isHidden = true
            durationHintLabel.isHidden = true
            volumeView.isHidden = false
            volumeView.reset()
            saveButton.setTitle("Save", for: .normal)
            // notes anchor to volumeView
            notesCardView.snp.remakeConstraints {
                $0.top.equalTo(self.volumeView.snp.bottom).offset(16 * Constraint.xCoeff)
                $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
            }
        }

        notesTextView.text = ""
        notesPlaceholder.isHidden = false
        layoutIfNeeded()
    }

    // MARK: - Side selection

    private enum BreastSide { case left, right }

    @objc private func sideTapped(_ sender: UIButton) {
        selectedSide = sender.tag == 0 ? .left : .right
        updateSideSelection(animated: true)
    }

    private func updateSideSelection(animated: Bool) {
        let accent = UIColor.brandPrimary
        let leftSelected = selectedSide == .left

        let applyChanges = {
            self.leftButton.backgroundColor = leftSelected ? accent : .clear
            self.leftButton.setTitleColor(leftSelected ? .white : .secondaryLabel, for: .normal)
            self.rightButton.backgroundColor = leftSelected ? .clear : accent
            self.rightButton.setTitleColor(leftSelected ? .secondaryLabel : .white, for: .normal)
            self.sideIndicatorLabel.text = leftSelected ? "Left breast" : "Right breast"
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: applyChanges)
        } else {
            applyChanges()
        }
    }

    // MARK: - Timer logic

    @objc private func startPauseTapped() {
        if timerIsRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    @objc private func resetTapped() {
        stopTimer()
        resetTimerState()
    }

    private func startTimer() {
        timerIsRunning = true
        countTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
            self?.updateTimerLabel()
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        startPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: cfg), for: .normal)
        startPauseButton.backgroundColor = UIColor(hexString: "#E07A5F")
        durationHintLabel.text = "Tap ⏸ to pause"
    }

    private func pauseTimer() {
        timerIsRunning = false
        countTimer?.invalidate()
        countTimer = nil
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        startPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
        startPauseButton.backgroundColor = .brandPrimary
        durationHintLabel.text = "Tap ▶ to resume"
    }

    private func stopTimer() {
        timerIsRunning = false
        countTimer?.invalidate()
        countTimer = nil
    }

    private func resetTimerState() {
        elapsedSeconds = 0
        timerLabel.text = "00:00"
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        startPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
        startPauseButton.backgroundColor = .brandPrimary
        durationHintLabel.text = "Tap ▶ to start the timer"
    }

    private func updateTimerLabel() {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Save / Close

    @objc private func saveButtonTapped() {
        let type = currentFeedingType
        let volumeText: String?
        if type == .breast {
            let mins = elapsedSeconds / 60
            let secs = elapsedSeconds % 60
            let side = selectedSide == .left ? "L" : "R"
            volumeText = elapsedSeconds > 0 ? "\(side) \(String(format: "%02d:%02d", mins, secs))" : nil
        } else {
            volumeText = volumeView.selectedVolumeText
        }
        let notesText: String? = {
            let t = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeText = formatter.string(from: Date())
        formatter.dateFormat = "MMM d"
        let dateText = formatter.string(from: Date())

        onTapSave?(type, volumeText, notesText, timeText, dateText)
        stopTimer()
        onTapCloseButton?()
    }

    @objc private func closeButtonTapped() {
        stopTimer()
        onTapCloseButton?()
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height
        scrollView.verticalScrollIndicatorInsets.bottom = frame.height
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let r = self.notesTextView.convert(self.notesTextView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(r.insetBy(dx: 0, dy: -40), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UITextViewDelegate

extension FeedingView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholder.isHidden = !textView.text.isEmpty
    }
}

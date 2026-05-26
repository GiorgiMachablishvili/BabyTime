import UIKit
import SnapKit

// MARK: - FeedingSessionViewController
// Unified full-screen log view for Breast, Bottle, Formula, and Solid feeding.

final class FeedingSessionViewController: UIViewController {

    // MARK: - Config per type
    private struct TypeConfig {
        let title: String
        let sectionLabel: String
        let accentColor: UIColor
        let pillTitles: [[String]]      // rows of pill labels
        let defaultPill: String         // which pill is pre-selected
        let customAlertTitle: String
        let customAlertMessage: String
        let customAlertPlaceholder: String
        let customSuffix: String        // appended to the custom value
    }

    private static func config(for type: FeedingTypeView.FeedingType) -> TypeConfig {
        switch type {
        case .breast:
            return TypeConfig(
                title: "Start Breast",
                sectionLabel: "Duration (minutes)",
                accentColor: UIColor(hexString: "#E8613A"),
                pillTitles: [["5 min", "10 min", "15 min"],
                             ["20 min", "Other"]],
                defaultPill: "10 min",
                customAlertTitle: "Custom duration",
                customAlertMessage: "Enter minutes",
                customAlertPlaceholder: "e.g. 25",
                customSuffix: " min"
            )
        case .bottle:
            return TypeConfig(
                title: "Bottle",
                sectionLabel: "Volume (ml)",
                accentColor: UIColor(hexString: "#9b7fd4"),
                pillTitles: [["30 ml", "60 ml", "90 ml", "120 ml"],
                             ["150 ml", "180 ml", "210 ml", "Other"]],
                defaultPill: "60 ml",
                customAlertTitle: "Custom volume",
                customAlertMessage: "Enter amount in ml",
                customAlertPlaceholder: "e.g. 135",
                customSuffix: " ml"
            )
        case .formula:
            return TypeConfig(
                title: "Formula",
                sectionLabel: "Volume (ml)",
                accentColor: UIColor(hexString: "#4a9fc4"),
                pillTitles: [["30 ml", "60 ml", "90 ml", "120 ml"],
                             ["150 ml", "180 ml", "210 ml", "Other"]],
                defaultPill: "60 ml",
                customAlertTitle: "Custom volume",
                customAlertMessage: "Enter amount in ml",
                customAlertPlaceholder: "e.g. 135",
                customSuffix: " ml"
            )
        case .solid:
            return TypeConfig(
                title: "Solid Food",
                sectionLabel: "Volume (ml)",
                accentColor: UIColor(hexString: "#5aac7c"),
                pillTitles: [["30 ml", "60 ml", "90 ml", "120 ml"],
                             ["150 ml", "180 ml", "210 ml", "Other"]],
                defaultPill: "60 ml",
                customAlertTitle: "Custom volume",
                customAlertMessage: "Enter amount in ml",
                customAlertPlaceholder: "e.g. 135",
                customSuffix: " ml"
            )
        }
    }

    // MARK: - Properties
    var feedingType: FeedingTypeView.FeedingType = .breast
    var onSave: ((String?, String?) -> Void)?

    private var cfg: TypeConfig { Self.config(for: feedingType) }
    private var selectedPill: PillButton?
    private var allPills: [PillButton] = []
    private var otherPill: PillButton?

    // MARK: - Views

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        let sym = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: sym), for: .normal)
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var navTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .onDrag
        return s
    }()
    private lazy var contentView = UIView()

    // Hero image
    private lazy var heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18
        if let img = UIImage(named: "teddyBear") {
            iv.image = img
        } else {
            iv.backgroundColor = UIColor(hexString: "#E8DFF5")
            let icon = UIImageView(image: UIImage(systemName: "figure.and.child.holdinghands"))
            icon.tintColor = UIColor.brandPrimary.withAlphaComponent(0.35)
            icon.contentMode = .scaleAspectFit
            iv.addSubview(icon)
            icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(60) }
        }
        return iv
    }()

    // Section label (Duration / Volume)
    private lazy var sectionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }()

    // Pill rows (built dynamically in configure())
    private lazy var pillRow1 = makeRowStack()
    private lazy var pillRow2 = makeRowStack()

    // Notes
    private lazy var notesLabel: UILabel = {
        let l = UILabel()
        l.text = "Notes"
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private lazy var notesTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .fieldBackground
        tv.layer.cornerRadius = 14
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = .label
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        tv.isScrollEnabled = false
        tv.delegate = self
        return tv
    }()

    private lazy var notesPlaceholder: UILabel = {
        let l = UILabel()
        l.text = "Add any details..."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .tertiaryLabel
        l.numberOfLines = 0
        return l
    }()

    // Last session card
    private lazy var lastSessionCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#FBE8D8")
        v.layer.cornerRadius = 14
        return v
    }()

    private lazy var lastSessionIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "info.circle"))
        iv.tintColor = UIColor(hexString: "#C87941")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var lastSessionLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        return l
    }()

    // Save button
    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 20
        b.tintColor = .white
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Save"
        cfg.image = UIImage(systemName: "square.and.arrow.down",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        cfg.imagePadding = 8
        cfg.baseForegroundColor = .white
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var a = a; a.font = UIFont.systemFont(ofSize: 17, weight: .semibold); return a
        }
        b.configuration = cfg
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Helpers

    private func makeRowStack() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        s.distribution = .fill
        return s
    }

    private func makePill(_ title: String, accent: UIColor) -> PillButton {
        let b = PillButton(accentColor: accent)
        b.setTitle(title, for: .normal)
        b.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
        return b
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()
        applyTypeConfig()
        setupKeyboard()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(navTitleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(heroImageView)
        contentView.addSubview(sectionLabel)
        contentView.addSubview(pillRow1)
        contentView.addSubview(pillRow2)
        contentView.addSubview(notesLabel)
        contentView.addSubview(notesTextView)
        notesTextView.addSubview(notesPlaceholder)
        contentView.addSubview(lastSessionCard)
        lastSessionCard.addSubview(lastSessionIcon)
        lastSessionCard.addSubview(lastSessionLabel)

        view.addSubview(saveButton)
    }

    private func setupConstraints() {
        let hPad: CGFloat = 20 * Constraint.xCoeff

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
            $0.width.height.equalTo(36)
        }
        navTitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }
        scrollView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(saveButton.snp.top).offset(-12 * Constraint.xCoeff)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        heroImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(160 * Constraint.xCoeff)
        }
        sectionLabel.snp.makeConstraints {
            $0.top.equalTo(heroImageView.snp.bottom).offset(22 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        pillRow1.snp.makeConstraints {
            $0.top.equalTo(sectionLabel.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
            $0.trailing.lessThanOrEqualToSuperview().inset(hPad)
        }
        pillRow2.snp.makeConstraints {
            $0.top.equalTo(pillRow1.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
            $0.trailing.lessThanOrEqualToSuperview().inset(hPad)
        }
        notesLabel.snp.makeConstraints {
            $0.top.equalTo(pillRow2.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        notesTextView.snp.makeConstraints {
            $0.top.equalTo(notesLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.greaterThanOrEqualTo(110 * Constraint.xCoeff)
        }
        notesPlaceholder.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }
        lastSessionCard.snp.makeConstraints {
            $0.top.equalTo(notesTextView.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.bottom.equalToSuperview().inset(24 * Constraint.xCoeff)
        }
        lastSessionIcon.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
            $0.width.height.equalTo(20)
        }
        lastSessionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14)
            $0.leading.equalTo(lastSessionIcon.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(14)
            $0.bottom.equalToSuperview().inset(14)
        }
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16 * Constraint.xCoeff)
            $0.height.equalTo(56 * Constraint.xCoeff)
        }
    }

    // MARK: - Apply type configuration

    private func applyTypeConfig() {
        let c = cfg

        // Nav
        navTitleLabel.text = c.title
        navTitleLabel.textColor = c.accentColor
        backButton.tintColor = c.accentColor

        // Section label
        sectionLabel.text = c.sectionLabel

        // Save button color
        saveButton.backgroundColor = c.accentColor

        // Hero image tint (for placeholder case)
        heroImageView.tintColor = c.accentColor.withAlphaComponent(0.35)

        // Build pills
        allPills.removeAll()
        otherPill = nil
        pillRow1.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pillRow2.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows = [pillRow1, pillRow2]
        for (rowIndex, titles) in c.pillTitles.enumerated() {
            guard rowIndex < rows.count else { break }
            let row = rows[rowIndex]
            for title in titles {
                let pill = makePill(title, accent: c.accentColor)
                if title == "Other" { otherPill = pill }
                allPills.append(pill)
                row.addArrangedSubview(pill)
            }
            // Add flexible spacer at end of each row so pills stay left-aligned
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)
        }

        // Pre-select default
        if let defaultPill = allPills.first(where: { $0.title(for: .normal) == c.defaultPill }) {
            selectPill(defaultPill)
        } else if let first = allPills.first(where: { $0 !== otherPill }) {
            selectPill(first)
        }

        // Last session text
        let sessionTitle = NSMutableAttributedString(
            string: "Last session: 3 hours ago\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor(hexString: "#8A5230")
            ]
        )
        let sessionBody = NSAttributedString(
            string: "Previous duration was 12 minutes on the left side.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor(hexString: "#8A5230")
            ]
        )
        sessionTitle.append(sessionBody)
        lastSessionLabel.attributedText = sessionTitle
    }

    // MARK: - Pill actions

    @objc private func pillTapped(_ sender: PillButton) {
        if sender === otherPill {
            presentCustomInput()
        } else {
            selectPill(sender)
        }
    }

    private func selectPill(_ pill: PillButton) {
        selectedPill?.setSelected(false)
        pill.setSelected(true)
        selectedPill = pill
    }

    private func presentCustomInput() {
        let c = cfg
        let alert = UIAlertController(title: c.customAlertTitle,
                                      message: c.customAlertMessage,
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = c.customAlertPlaceholder
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self,
                  let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  let value = Int(text), value > 0 else { return }
            let label = "\(value)\(c.customSuffix)"
            self.otherPill?.setTitle(label, for: .normal)
            if let pill = self.otherPill { self.selectPill(pill) }
        })
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func backTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let value = selectedPill?.title(for: .normal)
        let notes: String? = {
            let t = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }()
        onSave?(value, notes)
        dismiss(animated: true)
    }

    // MARK: - Keyboard

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(kwShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kwHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kwShow(_ n: Notification) {
        guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = f.height
        scrollView.verticalScrollIndicatorInsets.bottom = f.height
    }
    @objc private func kwHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

// MARK: - UITextViewDelegate
extension FeedingSessionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholder.isHidden = !textView.text.isEmpty
    }
}

// MARK: - PillButton

final class PillButton: UIButton {

    private let accentColor: UIColor

    init(accentColor: UIColor = .brandPrimary) {
        self.accentColor = accentColor
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = 18 * Constraint.xCoeff
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        setSelected(false)
    }

    func setSelected(_ on: Bool) {
        backgroundColor = on ? accentColor : UIColor.systemBackground
        setTitleColor(on ? .white : .secondaryLabel, for: .normal)
        layer.borderWidth = on ? 0 : 1
        layer.borderColor = UIColor.systemGray4.cgColor
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width, height: 38 * Constraint.xCoeff)
    }
}

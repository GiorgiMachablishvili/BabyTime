import UIKit
import SnapKit

// MARK: - MemoryViewController

final class MemoryViewController: UIViewController {

    // MARK: - State
    private var memories: [BabyMemory] = []
    private var formCategory: BabyMemory.Category = .memories
    private var formCategoryButtons: [UIButton] = []
    private let placeholderText = "Baby took five steps towards the teddy bear today!"

    // MARK: - Top Bar
    private let topBar = HistoryTopBar()

    // MARK: - Scroll
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .onDrag
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    private lazy var contentView = UIView()

    // MARK: - Section title
    private lazy var historyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "History"
        l.font = .systemFont(ofSize: 28 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        return l
    }()

    // MARK: - Form card
    private lazy var formCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowRadius  = 10
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        return v
    }()

    // Card header: ✦ Add Baby Memory
    private lazy var cardHeaderRow: UIView = {
        let v = UIView()
        let sparkle = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkle.tintColor = UIColor(hexString: "#8b6dc4")
        sparkle.contentMode = .scaleAspectFit

        let lbl = UILabel()
        lbl.text = "Add Baby Memory"
        lbl.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        lbl.textColor = UIColor(hexString: "#1a1a1a")

        v.addSubview(sparkle)
        v.addSubview(lbl)

        sparkle.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        lbl.snp.makeConstraints {
            $0.leading.equalTo(sparkle.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        return v
    }()

    // Title field
    private lazy var titleFieldLabel = makeFieldLabel("Title")
    private lazy var titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "First Step"
        tf.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tf.backgroundColor = UIColor(hexString: "#f5f5f5")
        tf.layer.cornerRadius = 10 * Constraint.yCoeff
        tf.clipsToBounds = true
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftView = pad; tf.leftViewMode = .always
        return tf
    }()

    // Date field
    private lazy var dateFieldLabel = makeFieldLabel("Date")
    private lazy var datePickerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f5f5f5")
        v.layer.cornerRadius = 10 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()
    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = UIColor(hexString: "#8b6dc4")
        return dp
    }()

    // Memory text area
    private lazy var memoryFieldLabel = makeFieldLabel("Write your memory...")
    private lazy var memoryTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tv.backgroundColor = UIColor(hexString: "#f5f5f5")
        tv.layer.cornerRadius = 10 * Constraint.yCoeff
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.text = placeholderText
        tv.textColor = .placeholderText
        tv.delegate = self
        return tv
    }()

    // Category pills
    private lazy var categoryFieldLabel = makeFieldLabel("Category")
    private lazy var formCatRow1 = makeHStack()
    private lazy var formCatRow2 = makeHStack()
    private lazy var formCatContainer: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [formCatRow1, formCatRow2])
        sv.axis = .vertical; sv.spacing = 8 * Constraint.yCoeff; sv.alignment = .leading
        return sv
    }()

    // Save button
    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        b.setTitle("  Save Memory", for: .normal)
        b.tintColor = .white; b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#3d2b7a")
        b.layer.cornerRadius = 14 * Constraint.yCoeff; b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - View All Memories card
    private lazy var viewAllCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0f0f0")
        v.layer.cornerRadius = 20 * Constraint.yCoeff

        // Left icon
        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(hexString: "#ede9f8")
        iconBg.layer.cornerRadius = 18 * Constraint.yCoeff

        let icon = UIImageView(image: UIImage(systemName: "book.fill"))
        icon.tintColor = UIColor(hexString: "#8b6dc4")
        icon.contentMode = .scaleAspectFit

        // Labels
        let titleLbl = UILabel()
        titleLbl.text = "View All Memories"
        titleLbl.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        titleLbl.textColor = UIColor(hexString: "#1a1a1a")

        let subtitleLbl = UILabel()
        subtitleLbl.text = "Browse your complete history"
        subtitleLbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        subtitleLbl.textColor = UIColor(hexString: "#888888")

        // Chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(hexString: "#aaaaaa")
        chevron.contentMode = .scaleAspectFit

        v.addSubview(iconBg); iconBg.addSubview(icon)
        v.addSubview(titleLbl); v.addSubview(subtitleLbl); v.addSubview(chevron)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(10 * Constraint.xCoeff)
        }
        titleLbl.snp.makeConstraints {
            $0.leading.equalTo(iconBg.snp.trailing).offset(12 * Constraint.xCoeff)
            $0.bottom.equalTo(v.snp.centerY).offset(-1)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }
        subtitleLbl.snp.makeConstraints {
            $0.leading.equalTo(titleLbl)
            $0.top.equalTo(v.snp.centerY).offset(1)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewAllTapped))
        v.addGestureRecognizer(tap)
        v.isUserInteractionEnabled = true
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        buildFormCategories()
        setupUI()
        setupConstraints()
        topBar.onBackTap = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        memories = BabyMemoryStore.load()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let pushed = (navigationController?.viewControllers.count ?? 0) > 1
        topBar.setBackVisible(pushed)
        let name = BabyProfileStore.loadName() ?? "Baby"
        topBar.configure(name: name, birthday: BabyProfileStore.loadBirthday(), photo: BabyProfileStore.loadPhoto())
        memories = BabyMemoryStore.load()
    }

    // MARK: - Build helpers

    private func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeHStack() -> UIStackView {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8 * Constraint.xCoeff; sv.alignment = .center
        return sv
    }

    private func makePillButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.layer.borderWidth = 1.5; b.clipsToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        return b
    }

    private func buildFormCategories() {
        let cats = BabyMemory.Category.allCases
        for (i, cat) in cats.enumerated() {
            let b = makePillButton(title: cat.title)
            b.tag = i
            b.addTarget(self, action: #selector(formCatTapped(_:)), for: .touchUpInside)
            formCategoryButtons.append(b)
            if i < 3 { formCatRow1.addArrangedSubview(b) }
            else { formCatRow2.addArrangedSubview(b) }
        }
        refreshFormCategoryButtons()
    }

    private func refreshFormCategoryButtons() {
        let accent = UIColor(hexString: "#8b6dc4")
        for (i, b) in formCategoryButtons.enumerated() {
            let selected = BabyMemory.Category.allCases[i] == formCategory
            b.backgroundColor = selected ? accent : .clear
            b.setTitleColor(selected ? .white : accent, for: .normal)
            b.layer.borderColor = accent.cgColor
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(topBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(historyTitleLabel)
        contentView.addSubview(formCard)

        formCard.addSubview(cardHeaderRow)
        formCard.addSubview(titleFieldLabel)
        formCard.addSubview(titleField)
        formCard.addSubview(dateFieldLabel)
        formCard.addSubview(datePickerContainer)
        datePickerContainer.addSubview(datePicker)
        formCard.addSubview(memoryFieldLabel)
        formCard.addSubview(memoryTextView)
        formCard.addSubview(categoryFieldLabel)
        formCard.addSubview(formCatContainer)
        formCard.addSubview(saveButton)

        contentView.addSubview(viewAllCard)
    }

    private func setupConstraints() {
        let hInset = 16 * Constraint.xCoeff

        topBar.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(100 * Constraint.yCoeff)
        }
        scrollView.snp.makeConstraints {
            $0.top.equalTo(topBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Section title
        historyTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
        }

        // Form card
        formCard.snp.makeConstraints {
            $0.top.equalTo(historyTitleLabel.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
        }

        cardHeaderRow.snp.makeConstraints {
            $0.top.equalToSuperview().inset(18 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
            $0.height.equalTo(24 * Constraint.yCoeff)
        }
        titleFieldLabel.snp.makeConstraints {
            $0.top.equalTo(cardHeaderRow.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        titleField.snp.makeConstraints {
            $0.top.equalTo(titleFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(44 * Constraint.yCoeff)
        }
        dateFieldLabel.snp.makeConstraints {
            $0.top.equalTo(titleField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        datePickerContainer.snp.makeConstraints {
            $0.top.equalTo(dateFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(44 * Constraint.yCoeff)
        }
        datePicker.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        memoryFieldLabel.snp.makeConstraints {
            $0.top.equalTo(datePickerContainer.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        memoryTextView.snp.makeConstraints {
            $0.top.equalTo(memoryFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(110 * Constraint.yCoeff)
        }
        categoryFieldLabel.snp.makeConstraints {
            $0.top.equalTo(memoryTextView.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        formCatContainer.snp.makeConstraints {
            $0.top.equalTo(categoryFieldLabel.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(formCatContainer.snp.bottom).offset(18 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(50 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(18 * Constraint.yCoeff)
        }

        // View All card
        viewAllCard.snp.makeConstraints {
            $0.top.equalTo(formCard.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(70 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(32 * Constraint.yCoeff)
        }
    }

    // MARK: - Actions

    @objc private func formCatTapped(_ sender: UIButton) {
        formCategory = BabyMemory.Category.allCases[sender.tag]
        refreshFormCategoryButtons()
    }

    @objc private func saveTapped() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else {
            titleField.layer.borderColor = UIColor.systemRed.cgColor
            titleField.layer.borderWidth = 1.5
            return
        }
        titleField.layer.borderWidth = 0
        let text = memoryTextView.textColor == .placeholderText ? "" : (memoryTextView.text ?? "")
        let memory = BabyMemory(id: UUID(), title: title, date: datePicker.date, text: text, category: formCategory)
        memories.insert(memory, at: 0)
        BabyMemoryStore.save(memories)
        titleField.text = ""
        memoryTextView.text = placeholderText
        memoryTextView.textColor = .placeholderText
        view.endEditing(true)

        // Animate save confirmation
        UIView.animate(withDuration: 0.15, animations: {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15) { self.saveButton.transform = .identity }
        }
    }

    @objc private func viewAllTapped() {
        let vc = SavedMemoriesViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height + 20
        scrollView.verticalScrollIndicatorInsets.bottom = frame.height
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UITextViewDelegate

extension MemoryViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""; textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText; textView.textColor = .placeholderText
        }
    }
}

// MARK: - HistoryTopBar

final class HistoryTopBar: UIView {

    var onBackTap: (() -> Void)?

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.isHidden = true
        return b
    }()
    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 22 * Constraint.yCoeff; v.clipsToBounds = true
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.35)
        return v
    }()
    private let avatarImage: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv
    }()
    private let avatarInitial: UILabel = {
        let l = UILabel(); l.textAlignment = .center
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4"); return l
    }()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private let ageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        addSubview(backButton)
        addSubview(avatarView)
        avatarView.addSubview(avatarImage)
        avatarView.addSubview(avatarInitial)
        addSubview(nameLabel)
        addSubview(ageLabel)

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(9 * Constraint.yCoeff)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(9 * Constraint.yCoeff)
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        avatarImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarInitial.snp.makeConstraints { $0.center.equalToSuperview() }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.bottom.equalTo(avatarView.snp.centerY).offset(-1)
        }
        ageLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(avatarView.snp.centerY).offset(2)
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, birthday: Date?, photo: UIImage?) {
        nameLabel.text = name
        ageLabel.text = {
            guard let bd = birthday else { return "" }
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day],
                                           from: cal.startOfDay(for: bd),
                                           to: cal.startOfDay(for: Date()))
            let y = max(0, comps.year ?? 0); let m = max(0, comps.month ?? 0); let d = max(0, comps.day ?? 0)
            if y == 0 && m == 0 { return "\(d) days old" }
            if y == 0 { return "\(m) months \(d) days old" }
            return "\(y) years \(m) months \(d) days old"
        }()
        if let p = photo { avatarImage.image = p; avatarInitial.isHidden = true }
        else { avatarImage.image = nil; avatarInitial.text = String(name.prefix(1)).uppercased(); avatarInitial.isHidden = false }
    }

    func setBackVisible(_ visible: Bool) {
        backButton.isHidden = !visible
        avatarView.snp.updateConstraints {
            $0.leading.equalToSuperview().inset(visible ? 44 * Constraint.xCoeff : 20 * Constraint.xCoeff)
        }
        layoutIfNeeded()
    }

    @objc private func backTapped() { onBackTap?() }
}

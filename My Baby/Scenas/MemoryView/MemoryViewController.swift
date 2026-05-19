import UIKit
import SnapKit

// MARK: - MemoryViewController

final class MemoryViewController: UIViewController {

    // MARK: - State
    private var memories: [BabyMemory] = []
    private var selectedFilter: BabyMemory.Category? = nil
    private var formCategory: BabyMemory.Category = .memories
    private var expandedMemoryIDs: Set<UUID> = []
    private var memoryCards: [UUID: MemoryCardView] = [:]
    private let placeholderText = "Baby took five steps towards the teddy bear today!"

    // MARK: - Header
    private let topBar = HistoryTopBar()

    // MARK: - Scroll
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .onDrag
        return sv
    }()
    private lazy var contentView = UIView()

    // MARK: - Form card
    private lazy var formCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()

    private lazy var addMemoryLabel: UILabel = {
        let l = UILabel()
        l.text = "Add Baby Memory"
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        return l
    }()

    private lazy var titleFieldLabel = Self.makeFieldLabel("Title")
    private lazy var titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "First Step"
        tf.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tf.backgroundColor = UIColor(hexString: "#f5f5f5")
        tf.layer.cornerRadius = 8 * Constraint.yCoeff
        tf.clipsToBounds = true
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad; tf.leftViewMode = .always
        return tf
    }()

    private lazy var dateFieldLabel = Self.makeFieldLabel("Date")
    private lazy var datePickerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f5f5f5")
        v.layer.cornerRadius = 8 * Constraint.yCoeff
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

    private lazy var memoryFieldLabel = Self.makeFieldLabel("Write your memory...")
    private lazy var memoryTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15 * Constraint.yCoeff)
        tv.backgroundColor = UIColor(hexString: "#f5f5f5")
        tv.layer.cornerRadius = 8 * Constraint.yCoeff
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.text = placeholderText
        tv.textColor = .placeholderText
        tv.delegate = self
        return tv
    }()

    private lazy var categoryFieldLabel = Self.makeFieldLabel("Category")
    private var formCategoryButtons: [UIButton] = []
    private lazy var formCatRow1 = makeHStack()
    private lazy var formCatRow2 = makeHStack()
    private lazy var formCatContainer: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [formCatRow1, formCatRow2])
        sv.axis = .vertical; sv.spacing = 8 * Constraint.yCoeff; sv.alignment = .leading
        return sv
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("  Save Memory", for: .normal)
        b.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        b.tintColor = .white; b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        b.backgroundColor = UIColor(hexString: "#8b6dc4")
        b.layer.cornerRadius = 14 * Constraint.yCoeff; b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Saved Memories section
    private lazy var savedMemoriesLabel: UILabel = {
        let l = UILabel()
        l.text = "Saved Memories"
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        return l
    }()


    private lazy var filterScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        return sv
    }()
    private lazy var filterStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8 * Constraint.xCoeff; sv.alignment = .center
        return sv
    }()
    private var filterButtons: [UIButton] = []

    private lazy var memoriesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 12 * Constraint.yCoeff
        return sv
    }()

    private lazy var emptyView: UIView = {
        let v = UIView()
        let img = UIImageView(image: UIImage(named: "teddy") ?? UIImage(systemName: "photo.on.rectangle.angled"))
        img.tintColor = UIColor(hexString: "#cccccc")
        img.contentMode = .scaleAspectFit
        let lbl = UILabel()
        lbl.text = "Capture every little moment"
        lbl.font = .systemFont(ofSize: 14 * Constraint.yCoeff)
        lbl.textColor = .secondaryLabel; lbl.textAlignment = .center
        v.addSubview(img); v.addSubview(lbl)
        img.snp.makeConstraints {
            $0.centerX.equalToSuperview(); $0.top.equalToSuperview()
            $0.width.height.equalTo(60 * Constraint.yCoeff)
        }
        lbl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(img.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.bottom.equalToSuperview()
        }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        buildFormCategories()
        buildFilterButtons()
        setupUI()
        setupConstraints()
        topBar.onBackTap = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        loadMemories()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let pushed = (navigationController?.viewControllers.count ?? 0) > 1
        topBar.setBackVisible(pushed)
        let name = BabyProfileStore.loadName() ?? "Baby"
        topBar.configure(name: name, birthday: BabyProfileStore.loadBirthday(), photo: BabyProfileStore.loadPhoto())
    }

    // MARK: - Build helpers

    private static func makeFieldLabel(_ text: String) -> UILabel {
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

    private func buildFilterButtons() {
        let allBtn = makePillButton(title: "All")
        allBtn.tag = -1
        allBtn.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        filterButtons.append(allBtn)
        filterStack.addArrangedSubview(allBtn)

        for (i, cat) in BabyMemory.Category.allCases.enumerated() {
            let b = makePillButton(title: cat.title)
            b.tag = i
            b.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            filterButtons.append(b)
            filterStack.addArrangedSubview(b)
        }
        refreshFilterButtons()
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

    private func refreshFilterButtons() {
        let accent = UIColor(hexString: "#8b6dc4")
        for b in filterButtons {
            let selected: Bool
            if b.tag == -1 { selected = selectedFilter == nil }
            else { selected = selectedFilter == BabyMemory.Category.allCases[b.tag] }
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

        contentView.addSubview(formCard)
        formCard.addSubview(addMemoryLabel)
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

        contentView.addSubview(savedMemoriesLabel)
        contentView.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStack)
        contentView.addSubview(memoriesStack)
        contentView.addSubview(emptyView)
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

        // Form card
        formCard.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
        }
        addMemoryLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(18 * Constraint.yCoeff)
        }
        titleFieldLabel.snp.makeConstraints {
            $0.top.equalTo(addMemoryLabel.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        titleField.snp.makeConstraints {
            $0.top.equalTo(titleFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(42 * Constraint.yCoeff)
        }
        dateFieldLabel.snp.makeConstraints {
            $0.top.equalTo(titleField.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        datePickerContainer.snp.makeConstraints {
            $0.top.equalTo(dateFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(42 * Constraint.yCoeff)
        }
        datePicker.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
        memoryFieldLabel.snp.makeConstraints {
            $0.top.equalTo(datePickerContainer.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        memoryTextView.snp.makeConstraints {
            $0.top.equalTo(memoryFieldLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(100 * Constraint.yCoeff)
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

        // Memories section
        savedMemoriesLabel.snp.makeConstraints {
            $0.top.equalTo(formCard.snp.bottom).offset(24 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(hInset)
        }
        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(savedMemoriesLabel.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
            $0.height.equalTo(36 * Constraint.yCoeff)
        }
        filterStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(filterScrollView)
        }
        memoriesStack.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(hInset)
        }
        emptyView.snp.makeConstraints {
            $0.top.equalTo(memoriesStack.snp.bottom).offset(40 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(40 * Constraint.yCoeff)
        }
    }

    // MARK: - Data

    private func loadMemories() {
        memories = BabyMemoryStore.load()
        rebuildMemoriesList()
    }

    private func rebuildMemoriesList() {
        memoriesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        memoryCards = [:]
        let filtered = selectedFilter == nil ? memories : memories.filter { $0.category == selectedFilter }
        emptyView.isHidden = !filtered.isEmpty
        for memory in filtered {
            let card = MemoryCardView()
            card.configure(memory: memory, isExpanded: expandedMemoryIDs.contains(memory.id))
            card.onMenuTap = { [weak self] in self?.showMemoryOptions(memory) }
            card.onTap = { [weak self] in
                guard let self else { return }
                if self.expandedMemoryIDs.contains(memory.id) {
                    self.expandedMemoryIDs.remove(memory.id)
                } else {
                    self.expandedMemoryIDs.insert(memory.id)
                }
                self.memoryCards[memory.id]?.setExpanded(self.expandedMemoryIDs.contains(memory.id))
                UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            }
            memoryCards[memory.id] = card
            memoriesStack.addArrangedSubview(card)
        }
    }

    private func showMemoryOptions(_ memory: BabyMemory) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Edit Memory", style: .default) { [weak self] _ in
            self?.editMemory(memory)
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.memories.removeAll { $0.id == memory.id }
            BabyMemoryStore.save(self.memories)
            self.rebuildMemoriesList()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func editMemory(_ memory: BabyMemory) {
        let alert = UIAlertController(title: "Edit Memory", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = memory.title; tf.placeholder = "Title" }
        alert.addTextField { tf in tf.text = memory.text; tf.placeholder = "Note" }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }
            let title = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? memory.title
            let text = alert.textFields?[1].text ?? memory.text
            guard !title.isEmpty, let idx = self.memories.firstIndex(where: { $0.id == memory.id }) else { return }
            self.memories[idx].title = title
            self.memories[idx].text = text
            BabyMemoryStore.save(self.memories)
            self.rebuildMemoriesList()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func formCatTapped(_ sender: UIButton) {
        formCategory = BabyMemory.Category.allCases[sender.tag]
        refreshFormCategoryButtons()
    }

    @objc private func filterTapped(_ sender: UIButton) {
        selectedFilter = sender.tag == -1 ? nil : BabyMemory.Category.allCases[sender.tag]
        refreshFilterButtons()
        rebuildMemoriesList()
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
        rebuildMemoriesList()
    }
}

// MARK: - UITextViewDelegate

extension MemoryViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - HistoryTopBar

private final class HistoryTopBar: UIView {

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
            let y = max(0, comps.year ?? 0)
            let m = max(0, comps.month ?? 0)
            let d = max(0, comps.day ?? 0)
            if y == 0 && m == 0 { return "\(d) days old" }
            if y == 0 { return "\(m) months \(d) days old" }
            return "\(y) years \(m) months \(d) days old"
        }()
        if let p = photo {
            avatarImage.image = p; avatarInitial.isHidden = true
        } else {
            avatarImage.image = nil
            avatarInitial.text = String(name.prefix(1)).uppercased()
            avatarInitial.isHidden = false
        }
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

// MARK: - MemoryCardView

final class MemoryCardView: UIView {

    var onMenuTap: (() -> Void)?
    var onTap: (() -> Void)?

    private var isExpanded = false

    private let iconCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 22 * Constraint.yCoeff; v.clipsToBounds = true
        return v
    }()
    private let iconView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFit; iv.tintColor = .white; return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private let categoryTag: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .semibold)
        l.textColor = .white
        l.layer.cornerRadius = 8 * Constraint.yCoeff; l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999"); return l
    }()
    private lazy var menuButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        b.tintColor = UIColor(hexString: "#aaaaaa")
        b.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return b
    }()
    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff)
        l.textColor = UIColor(hexString: "#555555")
        l.numberOfLines = 2
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16 * Constraint.yCoeff; clipsToBounds = true

        // Transparent tap area behind all buttons so card tap doesn't block menu button
        let tapArea = UIView()
        tapArea.backgroundColor = .clear
        insertSubview(tapArea, at: 0)
        tapArea.snp.makeConstraints { $0.edges.equalToSuperview() }
        tapArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardTapped)))

        addSubview(iconCircle); iconCircle.addSubview(iconView)
        addSubview(menuButton)
        addSubview(titleLabel); addSubview(categoryTag); addSubview(dateLabel)
        addSubview(bodyLabel)

        iconCircle.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
            $0.width.height.equalTo(44 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20 * Constraint.yCoeff) }
        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(10 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(10 * Constraint.yCoeff)
            $0.width.height.equalTo(30 * Constraint.yCoeff)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircle)
            $0.leading.equalTo(iconCircle.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(menuButton.snp.leading).offset(-8 * Constraint.xCoeff)
        }
        categoryTag.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.height.equalTo(20 * Constraint.yCoeff)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(categoryTag.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.centerY.equalTo(categoryTag)
        }
        bodyLabel.snp.makeConstraints {
            $0.top.equalTo(iconCircle.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(memory: BabyMemory, isExpanded: Bool = false) {
        titleLabel.text = memory.title
        let df = DateFormatter(); df.dateFormat = "MMM d, yyyy"
        dateLabel.text = df.string(from: memory.date)
        bodyLabel.text = memory.text.isEmpty ? "" : memory.text

        let cat = memory.category
        iconCircle.backgroundColor = cat.color.withAlphaComponent(0.85)
        iconView.image = UIImage(systemName: cat.iconName)
        categoryTag.backgroundColor = cat.color
        categoryTag.text = "  \(cat.title)  "

        self.isExpanded = isExpanded
        bodyLabel.numberOfLines = isExpanded ? 0 : 2
    }

    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        bodyLabel.numberOfLines = expanded ? 0 : 2
        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc private func menuTapped() { onMenuTap?() }
    @objc private func cardTapped() { onTap?() }
}

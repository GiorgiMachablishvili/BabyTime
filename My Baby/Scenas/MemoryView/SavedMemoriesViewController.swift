import UIKit
import SnapKit

// MARK: - SavedMemoriesViewController

final class SavedMemoriesViewController: UIViewController {

    // MARK: - State
    private var allMemories: [BabyMemory] = []
    private var selectedFilter: BabyMemory.Category? = nil
    private var filterButtons: [UIButton] = []

    // MARK: - Nav bar
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#444444")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()
    private lazy var navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Saved Memories"
        l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        l.textAlignment = .center
        return l
    }()
    private lazy var avatarButton: UIButton = {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 18 * Constraint.yCoeff
        b.clipsToBounds = true
        b.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.4)
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        return b
    }()

    // MARK: - Filter scroll
    private lazy var filterScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        sv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return sv
    }()
    private lazy var filterStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8 * Constraint.xCoeff
        sv.alignment = .center
        return sv
    }()

    // MARK: - Collection view
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)
        cv.register(SavedMemoryCell.self, forCellWithReuseIdentifier: SavedMemoryCell.reuseId)
        return cv
    }()
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!

    // MARK: - Empty view
    private lazy var emptyView: UIView = {
        let v = UIView()
        let icon = UIImageView(image: UIImage(systemName: "book.closed.fill"))
        icon.tintColor = UIColor(hexString: "#dddddd")
        icon.contentMode = .scaleAspectFit
        let lbl = UILabel()
        lbl.text = "No memories yet"
        lbl.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .medium)
        lbl.textColor = UIColor(hexString: "#aaaaaa")
        lbl.textAlignment = .center
        let sub = UILabel()
        sub.text = "Add your first memory in History"
        sub.font = .systemFont(ofSize: 13 * Constraint.yCoeff)
        sub.textColor = UIColor(hexString: "#cccccc")
        sub.textAlignment = .center
        v.addSubview(icon); v.addSubview(lbl); v.addSubview(sub)
        icon.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalToSuperview(); $0.width.height.equalTo(64 * Constraint.yCoeff) }
        lbl.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(icon.snp.bottom).offset(14 * Constraint.yCoeff) }
        sub.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(lbl.snp.bottom).offset(6 * Constraint.yCoeff); $0.bottom.equalToSuperview() }
        v.isHidden = true
        return v
    }()

    // MARK: - FAB
    private lazy var fabButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(hexString: "#8b6dc4")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.2
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        buildFilterButtons()
        setupUI()
        setupConstraints()
        setupDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Configure avatar
        if let photo = BabyProfileStore.loadPhoto() {
            avatarButton.setImage(photo, for: .normal)
            avatarButton.contentMode = .scaleAspectFill
            avatarButton.imageView?.contentMode = .scaleAspectFill
        } else if let name = BabyProfileStore.loadName() {
            avatarButton.setTitle(String(name.prefix(1)).uppercased(), for: .normal)
            avatarButton.setImage(nil, for: .normal)
            avatarButton.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .bold)
            avatarButton.setTitleColor(UIColor(hexString: "#8b6dc4"), for: .normal)
        }
        loadAndApply()
    }

    // MARK: - Filter setup

    private func buildFilterButtons() {
        let allBtn = makePillButton(title: "All", tag: -1)
        filterButtons.append(allBtn)
        filterStack.addArrangedSubview(allBtn)

        for (i, cat) in BabyMemory.Category.allCases.enumerated() {
            let b = makePillButton(title: cat.title, tag: i)
            filterButtons.append(b)
            filterStack.addArrangedSubview(b)
        }
        refreshFilterButtons()
    }

    private func makePillButton(title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 16 * Constraint.yCoeff
        b.clipsToBounds = true
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        b.tag = tag
        b.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        return b
    }

    private func refreshFilterButtons() {
        let accent = UIColor(hexString: "#3d2b7a")
        for b in filterButtons {
            let selected: Bool
            if b.tag == -1 { selected = selectedFilter == nil }
            else { selected = selectedFilter == BabyMemory.Category.allCases[b.tag] }
            b.backgroundColor = selected ? accent : UIColor(hexString: "#eeeeee")
            b.setTitleColor(selected ? .white : UIColor(hexString: "#555555"), for: .normal)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(navTitleLabel)
        view.addSubview(avatarButton)
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStack)
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(fabButton)
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        navTitleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }
        avatarButton.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40 * Constraint.yCoeff)
        }
        filterStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(filterScrollView)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.center.equalTo(collectionView)
            $0.leading.trailing.equalToSuperview().inset(40 * Constraint.xCoeff)
        }
        fabButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20 * Constraint.yCoeff)
            $0.width.height.equalTo(56 * Constraint.yCoeff)
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)), subitems: [item])
            let sec = NSCollectionLayoutSection(group: group)
            sec.interGroupSpacing = 12 * Constraint.yCoeff
            sec.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            return sec
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) { [weak self] (cv: UICollectionView, indexPath: IndexPath, id: UUID) -> UICollectionViewCell in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: SavedMemoryCell.reuseId, for: indexPath) as! SavedMemoryCell
            guard let self, let memory = self.allMemories.first(where: { $0.id == id }) else { return cell }
            cell.configure(memory: memory)
            cell.onMenuTap = { [weak self] in self?.showOptions(for: memory) }
            return cell
        }
    }

    // MARK: - Data

    private func loadAndApply() {
        allMemories = BabyMemoryStore.load()
        applySnapshot()
    }

    private func applySnapshot() {
        let filtered = selectedFilter == nil ? allMemories : allMemories.filter { $0.category == selectedFilter }
        emptyView.isHidden = !filtered.isEmpty

        var snap = NSDiffableDataSourceSnapshot<Int, UUID>()
        snap.appendSections([0])
        snap.appendItems(filtered.map { $0.id })
        dataSource.apply(snap, animatingDifferences: true)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func filterTapped(_ sender: UIButton) {
        selectedFilter = sender.tag == -1 ? nil : BabyMemory.Category.allCases[sender.tag]
        refreshFilterButtons()
        applySnapshot()
    }

    @objc private func fabTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func showOptions(for memory: BabyMemory) {
        let alert = UIAlertController(title: memory.title, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            BabyMemoryStore.delete(id: memory.id)
            self.allMemories.removeAll { $0.id == memory.id }
            self.applySnapshot()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - SavedMemoryCell

private final class SavedMemoryCell: UICollectionViewCell {
    static let reuseId = "SavedMemoryCell"

    var onMenuTap: (() -> Void)?

    // Category badge (pill)
    private let categoryBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .semibold)
        l.layer.cornerRadius = 10 * Constraint.yCoeff
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    // Date label
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#999999")
        return l
    }()

    // Right icon circle
    private let iconCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // Title
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a")
        l.numberOfLines = 1
        return l
    }()

    // Body text
    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#666666")
        l.numberOfLines = 2
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.04
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)

        iconCircle.addSubview(iconView)
        contentView.addSubview(categoryBadge)
        contentView.addSubview(dateLabel)
        contentView.addSubview(iconCircle)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)

        iconCircle.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(18 * Constraint.yCoeff)
        }
        categoryBadge.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(categoryBadge.snp.trailing).offset(8 * Constraint.xCoeff)
            $0.centerY.equalTo(categoryBadge)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.top.equalTo(categoryBadge.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(iconCircle.snp.leading).offset(-8)
        }
        bodyLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(iconCircle.snp.leading).offset(-8)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(menuTapped))
        iconCircle.addGestureRecognizer(tap)
        iconCircle.isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMenuTap = nil
    }

    func configure(memory: BabyMemory) {
        let cat = memory.category
        let df = DateFormatter(); df.dateFormat = "MMM d, yyyy"
        dateLabel.text = df.string(from: memory.date)
        titleLabel.text = memory.title
        bodyLabel.text = memory.text.isEmpty ? " " : memory.text
        bodyLabel.isHidden = memory.text.isEmpty

        // Badge
        categoryBadge.text = "  \(cat.title)  "
        categoryBadge.textColor = cat.color
        categoryBadge.backgroundColor = cat.color.withAlphaComponent(0.12)

        // Icon circle
        iconCircle.backgroundColor = cat.color.withAlphaComponent(0.12)
        iconView.image = UIImage(systemName: cat.iconName)
        iconView.tintColor = cat.color
    }

    @objc private func menuTapped() { onMenuTap?() }
}

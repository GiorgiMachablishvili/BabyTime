import UIKit
import SnapKit

// MARK: - VaccinationViewController

final class VaccinationViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    // MARK: - Diffable types

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case main, footer
    }

    private nonisolated enum Item: Hashable, Sendable {
        case summary
        case tabs
        case groupHeader(String)
        case vaccine(UUID)
        case addButton
    }

    // MARK: - State

    private var vaccines: [Vaccine] = []
    private var showCompleted = false
    private var expandedIDs: Set<UUID> = []

    // MARK: - Views

    private let headerView = VaccineHeaderView()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.register(VaccineSummaryCell.self, forCellWithReuseIdentifier: VaccineSummaryCell.reuseId)
        cv.register(VaccineTabsCell.self, forCellWithReuseIdentifier: VaccineTabsCell.reuseId)
        cv.register(VaccineGroupHeaderCell.self, forCellWithReuseIdentifier: VaccineGroupHeaderCell.reuseId)
        cv.register(VaccineCardCell.self, forCellWithReuseIdentifier: VaccineCardCell.reuseId)
        cv.register(VaccineAddButtonCell.self, forCellWithReuseIdentifier: VaccineAddButtonCell.reuseId)
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupDataSource()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let isPushed = navigationController?.viewControllers.count ?? 0 > 1
        headerView.setBackVisible(isPushed)
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(collectionView)

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(110 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        headerView.onCalendarTap = { [weak self] in self?.presentCalendar() }
        headerView.onBackTap = { [weak self] in self?.navigationController?.popViewController(animated: true) }
    }

    private func presentCalendar() {
        if #available(iOS 16.0, *) {
            let vc = VaccinationCalendarViewController()
            vc.onWillDismiss = { [weak self] in self?.loadData() }
            let nav = UINavigationController(rootViewController: vc)
            nav.presentationController?.delegate = self
            present(nav, animated: true)
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            guard let self else { return UICollectionViewCell() }

            switch item {
            case .summary:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: VaccineSummaryCell.reuseId, for: indexPath) as! VaccineSummaryCell
                let total = self.vaccines.count
                let done = self.vaccines.filter { $0.status == .completed }.count
                let nextDue = self.vaccines.filter { $0.status == .dueSoon || $0.status == .overdue }
                    .compactMap { $0.dueDate }.min()
                cell.configure(done: done, total: total, nextDue: nextDue)
                return cell

            case .tabs:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: VaccineTabsCell.reuseId, for: indexPath) as! VaccineTabsCell
                cell.configure(showCompleted: self.showCompleted)
                cell.onToggle = { [weak self] completed in
                    self?.showCompleted = completed
                    self?.applySnapshot()
                }
                return cell

            case .groupHeader(let title):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: VaccineGroupHeaderCell.reuseId, for: indexPath) as! VaccineGroupHeaderCell
                cell.configure(title: title)
                return cell

            case .vaccine(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: VaccineCardCell.reuseId, for: indexPath) as! VaccineCardCell
                guard let vaccine = self.vaccines.first(where: { $0.id == id }) else { return cell }
                let expanded = self.expandedIDs.contains(id)
                cell.configure(vaccine: vaccine, expanded: expanded)
                cell.onChevronTap = { [weak self] in
                    guard let self else { return }
                    if self.expandedIDs.contains(id) { self.expandedIDs.remove(id) } else { self.expandedIDs.insert(id) }
                    var snap = self.dataSource.snapshot()
                    snap.reconfigureItems([Item.vaccine(id)])
                    self.dataSource.apply(snap, animatingDifferences: true)
                }
                cell.onActionTap = { [weak self] in self?.showVaccineOptions(vaccine: vaccine) }
                cell.onDelete = { [weak self] in self?.showVaccineOptions(vaccine: vaccine) }
                cell.onCardTap = { [weak self] in self?.showVaccineOptions(vaccine: vaccine) }
                return cell

            case .addButton:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: VaccineAddButtonCell.reuseId, for: indexPath) as! VaccineAddButtonCell
                cell.onTap = { [weak self] in self?.presentAddVaccine() }
                return cell
            }
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        var config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0

        return UICollectionViewCompositionalLayout(sectionProvider: { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)), subitems: [item])
            let sec = NSCollectionLayoutSection(group: group)
            sec.interGroupSpacing = 10 * Constraint.yCoeff
            sec.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
            return sec
        }, configuration: config)
    }

    // MARK: - Data

    private func loadData() {
        vaccines = VaccineStore.load()
        let name = BabyProfileStore.loadName() ?? "Baby"
        headerView.configure(name: name, birthday: BabyProfileStore.loadBirthday(), photo: BabyProfileStore.loadPhoto())
        applySnapshot()
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections([.main, .footer])

        snap.appendItems([Item.summary, Item.tabs], toSection: .main)

        if showCompleted {
            let completed = vaccines.filter { $0.status == .completed }
                .sorted { ($0.completedTimestamp ?? 0) > ($1.completedTimestamp ?? 0) }
            if !completed.isEmpty {
                snap.appendItems([Item.groupHeader("Completed")] + completed.map { Item.vaccine($0.id) }, toSection: .main)
            }
        } else {
            let active = vaccines.filter { $0.status != .completed }
            let urgent = active.filter { $0.status == .overdue || $0.status == .dueSoon }
                .sorted { ($0.dueDateTimestamp ?? 0) < ($1.dueDateTimestamp ?? 0) }
            let scheduled = active.filter { $0.status == .scheduled }
                .sorted { ($0.scheduledTimestamp ?? 0) < ($1.scheduledTimestamp ?? 0) }
            let upcoming = active.filter { $0.status == .upcoming }
                .sorted { ($0.dueDateTimestamp ?? 0) < ($1.dueDateTimestamp ?? 0) }

            if !urgent.isEmpty {
                snap.appendItems(urgent.map { Item.vaccine($0.id) }, toSection: .main)
            }
            if !scheduled.isEmpty {
                snap.appendItems([Item.groupHeader("Scheduled")] + scheduled.map { Item.vaccine($0.id) }, toSection: .main)
            }
            if !upcoming.isEmpty {
                snap.appendItems([Item.groupHeader("Later this year")] + upcoming.map { Item.vaccine($0.id) }, toSection: .main)
            }
        }

        snap.appendItems([Item.addButton], toSection: .footer)
        snap.reconfigureItems([Item.tabs])
        dataSource.apply(snap, animatingDifferences: true)
    }

    // MARK: - Actions

    private func showVaccineOptions(vaccine: Vaccine) {
        let alert = UIAlertController(title: vaccine.name, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Mark completed", style: .default) { [weak self] _ in
            var v = vaccine
            v.completedDate = Date()
            VaccineStore.upsert(v)
            self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "Edit details", style: .default) { [weak self] _ in
            self?.presentEditVaccine(vaccine)
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            VaccineStore.delete(id: vaccine.id)
            self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentEditVaccine(_ vaccine: Vaccine) {
        let alert = UIAlertController(title: "Edit Vaccine", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = vaccine.name; tf.placeholder = "Name (e.g. MMR)" }
        alert.addTextField { tf in tf.text = vaccine.fullName; tf.placeholder = "Full name" }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            var v = vaccine
            if let name = alert?.textFields?[0].text, !name.isEmpty { v.name = name }
            if let full = alert?.textFields?[1].text, !full.isEmpty { v.fullName = full }
            VaccineStore.upsert(v)
            self.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentAddVaccine() {
        let alert = UIAlertController(title: "Add Vaccine Record", message: "Enter vaccine name", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Vaccine name (e.g. MMR)" }
        alert.addTextField { tf in tf.placeholder = "Full name" }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let name = alert?.textFields?[0].text, !name.isEmpty,
                  let full = alert?.textFields?[1].text else { return }
            let v = Vaccine(name: name, fullName: full.isEmpty ? name : full, ageRange: "")
            VaccineStore.upsert(v)
            self.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

}

// MARK: - VaccineHeaderView

private final class VaccineHeaderView: UIView {

    private let avatarView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 22 * Constraint.yCoeff; v.clipsToBounds = true
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.3); return v
    }()
    private let avatarImageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv
    }()
    private let avatarInitialLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4"); l.textAlignment = .center; return l
    }()
    private let nameLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222"); return l
    }()
    private let ageLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()
    private let gearButton: UIButton = {
        let b = UIButton(type: .system); b.setImage(UIImage(systemName: "calendar"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4"); return b
    }()
    private let backButton: UIButton = {
        let b = UIButton(type: .system); b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555"); return b
    }()

    var onCalendarTap: (() -> Void)?
    var onBackTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        addSubview(backButton); addSubview(avatarView); avatarView.addSubview(avatarImageView); avatarView.addSubview(avatarInitialLabel)
        addSubview(nameLabel); addSubview(ageLabel); addSubview(gearButton)
        backButton.snp.makeConstraints { $0.leading.equalToSuperview().inset(8 * Constraint.xCoeff); $0.centerY.equalTo(avatarView); $0.width.height.equalTo(36 * Constraint.yCoeff) }
        avatarView.snp.makeConstraints { $0.leading.equalToSuperview().inset(20 * Constraint.xCoeff); $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff); $0.width.height.equalTo(44 * Constraint.yCoeff) }
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarInitialLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        nameLabel.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff); $0.bottom.equalTo(avatarView.snp.centerY).offset(-1) }
        ageLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(avatarView.snp.centerY).offset(2) }
        gearButton.snp.makeConstraints { $0.trailing.equalToSuperview().inset(20 * Constraint.xCoeff); $0.centerY.equalTo(avatarView); $0.width.height.equalTo(36 * Constraint.yCoeff) }
        gearButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isHidden = true
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func calendarTapped() { onCalendarTap?() }
    @objc private func backTapped() { onBackTap?() }

    func setBackVisible(_ visible: Bool) {
        backButton.isHidden = !visible
        avatarView.snp.updateConstraints {
            $0.leading.equalToSuperview().inset(visible ? 44 * Constraint.xCoeff : 20 * Constraint.xCoeff)
        }
    }

    func configure(name: String, birthday: Date?, photo: UIImage?) {
        nameLabel.text = name
        ageLabel.text = {
            guard let bd = birthday else { return "BabyTime" }
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day],
                                           from: cal.startOfDay(for: bd),
                                           to: cal.startOfDay(for: Date()))
            let y = max(0, comps.year ?? 0)
            let m = max(0, comps.month ?? 0)
            let d = max(0, comps.day ?? 0)
            if y == 0 && m == 0 { return "\(d) days" }
            if y == 0 { return "\(m) months \(d) days" }
            return "\(y) years \(m) months \(d) days"
        }()
        if let p = photo { avatarImageView.image = p; avatarInitialLabel.isHidden = true }
        else { avatarImageView.image = nil; avatarInitialLabel.text = String(name.prefix(1)).uppercased(); avatarInitialLabel.isHidden = false }
    }
}

// MARK: - VaccineSummaryCell

private final class VaccineSummaryCell: UICollectionViewCell {
    static let reuseId = "VaccineSummaryCell"

    private let ringView = VaccineRingView()

    private let doneLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 26 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222"); l.textAlignment = .center; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "Vaccinations"
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222"); return l
    }()
    private let nextDueLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 20 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(ringView)
        contentView.addSubview(doneLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(nextDueLabel)

        ringView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(80 * Constraint.yCoeff)
        }
        doneLabel.snp.makeConstraints { $0.center.equalTo(ringView) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(ringView.snp.trailing).offset(16 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(22 * Constraint.yCoeff)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        nextDueLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(6 * Constraint.yCoeff)
            $0.bottom.lessThanOrEqualToSuperview().inset(22 * Constraint.yCoeff)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(done: Int, total: Int, nextDue: Date?) {
        let ratio = total > 0 ? CGFloat(done) / CGFloat(total) : 0
        ringView.setProgress(ratio)
        doneLabel.text = "\(done)/\(total)"

        if let due = nextDue {
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: due)).day ?? 0
            if days < 0 {
                nextDueLabel.text = "Overdue by \(-days) day\(-days == 1 ? "" : "s")"
                nextDueLabel.textColor = UIColor(hexString: "#e74c3c")
            } else if days == 0 {
                nextDueLabel.text = "Due today"
                nextDueLabel.textColor = UIColor(hexString: "#e67e22")
            } else {
                nextDueLabel.text = "Next due in \(days) day\(days == 1 ? "" : "s")"
                nextDueLabel.textColor = UIColor(hexString: "#888888")
            }
        } else {
            nextDueLabel.text = "All up to date"
            nextDueLabel.textColor = UIColor(hexString: "#27ae60")
        }
    }
}

// MARK: - VaccineRingView

private final class VaccineRingView: UIView {
    private let trackLayer = CAShapeLayer()
    private let fillLayer = CAShapeLayer()
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(hexString: "#ede9f8").cgColor
        trackLayer.lineWidth = 10; trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        fillLayer.fillColor = UIColor.clear.cgColor
        fillLayer.strokeColor = UIColor(hexString: "#8b6dc4").cgColor
        fillLayer.lineWidth = 10; fillLayer.lineCap = .round; fillLayer.strokeEnd = 0
        layer.addSublayer(fillLayer)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setProgress(_ v: CGFloat) { progress = v; setNeedsLayout() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let r = (min(bounds.width, bounds.height) - 10) / 2
        let path = UIBezierPath(arcCenter: c, radius: r, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        trackLayer.path = path.cgPath; fillLayer.path = path.cgPath; fillLayer.strokeEnd = progress
    }
}

// MARK: - VaccineTabsCell

private final class VaccineTabsCell: UICollectionViewCell {
    static let reuseId = "VaccineTabsCell"
    var onToggle: ((Bool) -> Void)?

    private lazy var upcomingBtn: UIButton = makeTab("Upcoming", tag: 0)
    private lazy var completedBtn: UIButton = makeTab("Completed", tag: 1)
    private let indicator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(hexString: "#8b6dc4")
        v.layer.cornerRadius = 16 * Constraint.yCoeff; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        contentView.addSubview(indicator)
        contentView.addSubview(upcomingBtn)
        contentView.addSubview(completedBtn)

        contentView.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview()
            $0.height.equalTo(56 * Constraint.yCoeff)
        }
        indicator.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.leading.equalToSuperview().inset(4 * Constraint.xCoeff)
            $0.width.equalToSuperview().dividedBy(2).offset(-6)
        }
        upcomingBtn.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.width.equalToSuperview().dividedBy(2) }
        completedBtn.snp.makeConstraints { $0.trailing.top.bottom.equalToSuperview(); $0.width.equalToSuperview().dividedBy(2) }
    }
    required init?(coder: NSCoder) { fatalError() }

    private func makeTab(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        b.tag = tag
        b.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return b
    }

    func configure(showCompleted: Bool) {
        upcomingBtn.setTitleColor(showCompleted ? UIColor(hexString: "#999999") : .white, for: .normal)
        completedBtn.setTitleColor(showCompleted ? .white : UIColor(hexString: "#999999"), for: .normal)
        indicator.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            if showCompleted {
                $0.trailing.equalToSuperview().inset(4 * Constraint.xCoeff)
            } else {
                $0.leading.equalToSuperview().inset(4 * Constraint.xCoeff)
            }
            $0.width.equalToSuperview().dividedBy(2).offset(-6)
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.layoutIfNeeded()
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        onToggle?(sender.tag == 1)
    }
}

// MARK: - VaccineGroupHeaderCell

private final class VaccineGroupHeaderCell: UICollectionViewCell {
    static let reuseId = "VaccineGroupHeaderCell"

    private let label: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#555555"); return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview(); $0.centerY.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) { label.text = title }
}

// MARK: - VaccineCardCell

final class VaccineCardCell: UICollectionViewCell {
    static let reuseId = "VaccineCardCell"

    var onChevronTap: (() -> Void)?
    var onActionTap: (() -> Void)?
    var onDelete: (() -> Void)?
    var onCardTap: (() -> Void)?

    // MARK: Subviews

    private let leftAccent: UIView = {
        let v = UIView(); v.layer.cornerRadius = 3; return v
    }()
    private let nameLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#222222"); return l
    }()
    private let fullNameLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()
    private let badgeView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 10 * Constraint.yCoeff; v.clipsToBounds = true; return v
    }()
    private let badgeLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .semibold); return l
    }()

    // info rows
    private let row1Icon = UIImageView()
    private let row1Label = UILabel()
    private let row2Icon = UIImageView()
    private let row2Label = UILabel()
    private let warningIcon = UIImageView()
    private let warningLabel = UILabel()

    // expandable details
    private let detailsStack: UIStackView = {
        let s = UIStackView(); s.axis = .vertical; s.spacing = 4 * Constraint.yCoeff; return s
    }()
    private let doseRow = UILabel()
    private let doctorRow = UILabel()
    private let separator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(hexString: "#f0f0f0"); return v
    }()

    // action
    private lazy var actionButton: UIButton = {
        let b = UIButton(type: .system)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.titleLabel?.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        b.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        return b
    }()
    private lazy var chevronButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        b.tintColor = UIColor(hexString: "#aaaaaa")
        b.addTarget(self, action: #selector(chevronTapped), for: .touchUpInside)
        return b
    }()
    private lazy var menuButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        b.tintColor = UIColor(hexString: "#cccccc")
        b.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return b
    }()

    private var showChevron = false
    private var isExpanded = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        for lbl in [row1Label, row2Label] {
            lbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
            lbl.textColor = UIColor(hexString: "#555555")
        }
        for iv in [row1Icon, row2Icon] {
            iv.contentMode = .scaleAspectFit
            iv.tintColor = UIColor(hexString: "#999999")
        }
        warningIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        warningIcon.tintColor = UIColor(hexString: "#e74c3c")
        warningIcon.contentMode = .scaleAspectFit
        warningLabel.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        warningLabel.textColor = UIColor(hexString: "#e74c3c")

        for lbl in [doseRow, doctorRow] {
            lbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
            lbl.textColor = UIColor(hexString: "#555555")
        }

        badgeView.addSubview(badgeLabel)
        contentView.addSubview(leftAccent)
        contentView.addSubview(nameLabel)
        contentView.addSubview(fullNameLabel)
        contentView.addSubview(badgeView)
        contentView.addSubview(row1Icon)
        contentView.addSubview(row1Label)
        contentView.addSubview(row2Icon)
        contentView.addSubview(row2Label)
        contentView.addSubview(warningIcon)
        contentView.addSubview(warningLabel)
        contentView.addSubview(separator)
        contentView.addSubview(detailsStack)
        detailsStack.addArrangedSubview(doseRow)
        detailsStack.addArrangedSubview(doctorRow)
        contentView.addSubview(actionButton)
        contentView.addSubview(chevronButton)
        contentView.addSubview(menuButton)

        setupConstraints()

        let tapArea = UIView()
        tapArea.backgroundColor = .clear
        contentView.insertSubview(tapArea, at: 0)
        tapArea.snp.makeConstraints { $0.edges.equalToSuperview() }
        tapArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardBodyTapped)))
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onChevronTap = nil; onActionTap = nil; onDelete = nil; onCardTap = nil
    }

    private func setupConstraints() {
        leftAccent.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(5 * Constraint.xCoeff)
        }
        menuButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
            $0.width.height.equalTo(24 * Constraint.yCoeff)
        }
        badgeView.snp.makeConstraints {
            $0.trailing.equalTo(menuButton.snp.leading).offset(-6 * Constraint.xCoeff)
            $0.centerY.equalTo(menuButton)
        }
        badgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(leftAccent.snp.trailing).offset(14 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-8)
            $0.top.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        fullNameLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-8)
        }
        warningIcon.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(fullNameLabel.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.width.height.equalTo(14 * Constraint.yCoeff)
        }
        warningLabel.snp.makeConstraints {
            $0.leading.equalTo(warningIcon.snp.trailing).offset(4 * Constraint.xCoeff)
            $0.centerY.equalTo(warningIcon)
        }
        row1Icon.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.width.height.equalTo(14 * Constraint.yCoeff)
        }
        row1Label.snp.makeConstraints {
            $0.leading.equalTo(row1Icon.snp.trailing).offset(6 * Constraint.xCoeff)
            $0.centerY.equalTo(row1Icon)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        row2Icon.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.width.height.equalTo(14 * Constraint.yCoeff)
        }
        row2Label.snp.makeConstraints {
            $0.leading.equalTo(row2Icon.snp.trailing).offset(6 * Constraint.xCoeff)
            $0.centerY.equalTo(row2Icon)
        }
        separator.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(1)
        }
        detailsStack.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        actionButton.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.height.equalTo(42 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        chevronButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.centerY.equalTo(actionButton)
            $0.width.height.equalTo(32 * Constraint.yCoeff)
            $0.leading.equalTo(actionButton.snp.trailing).offset(8 * Constraint.xCoeff)
        }
    }

    func configure(vaccine: Vaccine, expanded: Bool) {
        isExpanded = expanded
        nameLabel.text = vaccine.name
        fullNameLabel.text = vaccine.fullName

        let status = vaccine.status
        let df = DateFormatter(); df.dateFormat = "MMM dd, yyyy"

        // Badge
        switch status {
        case .dueSoon:
            badgeLabel.text = "Due soon"; badgeLabel.textColor = UIColor(hexString: "#e67e22")
            badgeView.backgroundColor = UIColor(hexString: "#e67e22").withAlphaComponent(0.12)
        case .overdue:
            badgeLabel.text = "Overdue"; badgeLabel.textColor = UIColor(hexString: "#e74c3c")
            badgeView.backgroundColor = UIColor(hexString: "#e74c3c").withAlphaComponent(0.12)
        case .scheduled:
            badgeLabel.text = "Scheduled"; badgeLabel.textColor = UIColor(hexString: "#8b6dc4")
            badgeView.backgroundColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.12)
        case .completed:
            badgeLabel.text = "Completed"; badgeLabel.textColor = UIColor(hexString: "#27ae60")
            badgeView.backgroundColor = UIColor(hexString: "#27ae60").withAlphaComponent(0.12)
        case .upcoming:
            badgeLabel.text = "Upcoming"; badgeLabel.textColor = UIColor(hexString: "#888888")
            badgeView.backgroundColor = UIColor(hexString: "#888888").withAlphaComponent(0.1)
        }

        // Left accent
        switch status {
        case .overdue: leftAccent.backgroundColor = UIColor(hexString: "#e74c3c")
        case .dueSoon: leftAccent.backgroundColor = UIColor(hexString: "#e67e22")
        case .scheduled: leftAccent.backgroundColor = UIColor(hexString: "#8b6dc4")
        case .completed: leftAccent.backgroundColor = UIColor(hexString: "#27ae60")
        case .upcoming: leftAccent.backgroundColor = UIColor(hexString: "#dddddd")
        }

        // Warning row (overdue)
        let isOverdue = status == .overdue
        warningIcon.isHidden = !isOverdue
        warningLabel.isHidden = !isOverdue
        if isOverdue, let due = vaccine.dueDate {
            warningLabel.text = df.string(from: due)
            warningIcon.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.top.equalTo(fullNameLabel.snp.bottom).offset(6 * Constraint.yCoeff)
                $0.width.height.equalTo(14 * Constraint.yCoeff)
            }
            warningLabel.snp.remakeConstraints {
                $0.leading.equalTo(warningIcon.snp.trailing).offset(4 * Constraint.xCoeff)
                $0.centerY.equalTo(warningIcon)
                $0.trailing.lessThanOrEqualToSuperview().inset(16)
            }
        }

        // Info rows — use .snp.bottom anchors so rows stack below each other
        let topAnchor: ConstraintItem = isOverdue ? warningLabel.snp.bottom : fullNameLabel.snp.bottom

        if status == .scheduled, let sched = vaccine.scheduledDate {
            var dateStr = df.string(from: sched)
            if let t = vaccine.scheduledTimeString { dateStr += " • \(t)" }
            row1Icon.image = UIImage(systemName: "calendar")
            row1Label.text = dateStr
            row1Icon.isHidden = false; row1Label.isHidden = false
            row2Icon.isHidden = true; row2Label.isHidden = true
        } else if let due = vaccine.dueDate, status != .completed {
            row1Icon.image = UIImage(systemName: "calendar")
            row1Label.text = df.string(from: due)
            row1Icon.isHidden = false; row1Label.isHidden = false
            if !vaccine.ageRange.isEmpty {
                row2Icon.image = UIImage(systemName: "clock")
                row2Label.text = vaccine.ageRange
                row2Icon.isHidden = false; row2Label.isHidden = false
            } else {
                row2Icon.isHidden = true; row2Label.isHidden = true
            }
        } else if status == .completed, let done = vaccine.completedDate {
            row1Icon.image = UIImage(systemName: "checkmark.circle")
            row1Icon.tintColor = UIColor(hexString: "#27ae60")
            row1Label.text = "Completed \(df.string(from: done))"
            row1Label.textColor = UIColor(hexString: "#27ae60")
            row1Icon.isHidden = false; row1Label.isHidden = false
            row2Icon.isHidden = true; row2Label.isHidden = true
        } else {
            row1Icon.isHidden = true; row1Label.isHidden = true
            row2Icon.isHidden = true; row2Label.isHidden = true
        }

        row1Icon.snp.remakeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(topAnchor).offset(8 * Constraint.yCoeff)
            $0.width.height.equalTo(14 * Constraint.yCoeff)
        }
        row1Label.snp.remakeConstraints {
            $0.leading.equalTo(row1Icon.snp.trailing).offset(6 * Constraint.xCoeff)
            $0.centerY.equalTo(row1Icon)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-8)
        }

        let row2Top: ConstraintItem = row1Icon.isHidden ? topAnchor : row1Icon.snp.bottom
        let row2Offset: CGFloat = row1Icon.isHidden ? 0 : 8 * Constraint.yCoeff
        row2Icon.snp.remakeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(row2Top).offset(row2Offset)
            $0.width.height.equalTo(14 * Constraint.yCoeff)
        }
        row2Label.snp.remakeConstraints {
            $0.leading.equalTo(row2Icon.snp.trailing).offset(6 * Constraint.xCoeff)
            $0.centerY.equalTo(row2Icon)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        // Expanded details
        let hasDetails = vaccine.doseInfoString != nil || vaccine.doctorName != nil
        let shouldShowDetails = expanded && hasDetails

        doseRow.isHidden = vaccine.doseInfoString == nil
        doctorRow.isHidden = vaccine.doctorName == nil
        if let dose = vaccine.doseInfoString { doseRow.text = "Dose: \(dose)" }
        if let doc = vaccine.doctorName { doctorRow.text = "Doctor: \(doc)" }

        separator.isHidden = !shouldShowDetails
        detailsStack.isHidden = !shouldShowDetails

        // Determine the bottom of all visible info rows
        let infoBottom: ConstraintItem = {
            if !row2Icon.isHidden { return row2Icon.snp.bottom }
            if !row1Icon.isHidden { return row1Icon.snp.bottom }
            if !warningIcon.isHidden { return warningIcon.snp.bottom }
            return fullNameLabel.snp.bottom
        }()

        if shouldShowDetails {
            separator.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
                $0.top.equalTo(infoBottom).offset(12 * Constraint.yCoeff)
                $0.height.equalTo(1)
            }
            detailsStack.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
                $0.top.equalTo(separator.snp.bottom).offset(8 * Constraint.yCoeff)
            }
        }

        // Action button
        showChevron = hasDetails && status != .completed
        chevronButton.isHidden = !showChevron
        actionButton.isHidden = false

        let actionTop: ConstraintItem = shouldShowDetails ? detailsStack.snp.bottom : infoBottom

        switch status {
        case .overdue:
            actionButton.setTitle("Mark done", for: .normal)
            actionButton.backgroundColor = UIColor(hexString: "#3d2b7a")
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.borderWidth = 0
            actionButton.snp.remakeConstraints {
                $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
                $0.height.equalTo(42 * Constraint.yCoeff)
                $0.top.equalTo(actionTop).offset(12 * Constraint.yCoeff)
                $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
            }
        case .dueSoon:
            actionButton.setTitle("Schedule", for: .normal)
            actionButton.backgroundColor = .clear
            actionButton.setTitleColor(UIColor(hexString: "#333333"), for: .normal)
            actionButton.layer.borderWidth = 1
            actionButton.layer.borderColor = UIColor(hexString: "#dddddd").cgColor
            actionButton.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.height.equalTo(42 * Constraint.yCoeff)
                $0.top.equalTo(actionTop).offset(12 * Constraint.yCoeff)
                $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
                if showChevron { $0.trailing.equalTo(chevronButton.snp.leading).offset(-8 * Constraint.xCoeff) }
                else { $0.trailing.equalToSuperview().inset(14 * Constraint.xCoeff) }
            }
        case .scheduled:
            actionButton.isHidden = true
            actionButton.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.height.equalTo(0)
                $0.top.equalTo(infoBottom).offset(12 * Constraint.yCoeff)
                $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
            }
        case .upcoming:
            actionButton.setTitle("Options", for: .normal)
            actionButton.backgroundColor = .clear
            actionButton.setTitleColor(UIColor(hexString: "#333333"), for: .normal)
            actionButton.layer.borderWidth = 1
            actionButton.layer.borderColor = UIColor(hexString: "#dddddd").cgColor
            actionButton.snp.remakeConstraints {
                $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
                $0.height.equalTo(42 * Constraint.yCoeff)
                $0.top.equalTo(actionTop).offset(12 * Constraint.yCoeff)
                $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
            }
        default: // .completed
            actionButton.isHidden = true
            actionButton.snp.remakeConstraints {
                $0.leading.equalTo(nameLabel)
                $0.height.equalTo(0)
                $0.top.equalTo(infoBottom).offset(12 * Constraint.yCoeff)
                $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
            }
        }

        let img = UIImage(systemName: expanded ? "chevron.up" : "chevron.down")
        chevronButton.setImage(img, for: .normal)
    }

    @objc private func actionTapped() { onActionTap?() }
    @objc private func chevronTapped() { onChevronTap?() }
    @objc private func menuTapped() { onDelete?() }
    @objc private func cardBodyTapped() { onCardTap?() }
}

// MARK: - VaccineAddButtonCell

private final class VaccineAddButtonCell: UICollectionViewCell {
    static let reuseId = "VaccineAddButtonCell"
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 1.5
        contentView.layer.borderColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.4).cgColor
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff

        let iv = UIImageView(image: UIImage(systemName: "plus.circle"))
        iv.tintColor = UIColor(hexString: "#8b6dc4")
        iv.contentMode = .scaleAspectFit

        let lbl = UILabel()
        lbl.text = "Add vaccine record"
        lbl.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .medium)
        lbl.textColor = UIColor(hexString: "#8b6dc4")

        let stack = UIStackView(arrangedSubviews: [iv, lbl])
        stack.axis = .horizontal; stack.spacing = 8 * Constraint.xCoeff; stack.alignment = .center
        stack.isUserInteractionEnabled = false

        contentView.addSubview(stack)
        iv.snp.makeConstraints { $0.width.height.equalTo(20 * Constraint.yCoeff) }
        stack.snp.makeConstraints { $0.center.equalToSuperview() }

        // dashed border via CAShapeLayer
        let dash = CAShapeLayer()
        dash.strokeColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.4).cgColor
        dash.fillColor = UIColor.clear.cgColor
        dash.lineWidth = 1.5
        dash.lineDashPattern = [6, 4]
        contentView.layer.borderWidth = 0
        contentView.layer.addSublayer(dash)
        contentView.layer.borderWidth = 0

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        contentView.addGestureRecognizer(tap)
        contentView.isUserInteractionEnabled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let path = UIBezierPath(roundedRect: self.contentView.bounds, cornerRadius: 16 * Constraint.yCoeff)
            dash.path = path.cgPath
            dash.frame = self.contentView.bounds
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let dash = contentView.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
            let path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 16 * Constraint.yCoeff)
            dash.path = path.cgPath
            dash.frame = contentView.bounds
        }
    }

    @objc private func tapped() { onTap?() }
}

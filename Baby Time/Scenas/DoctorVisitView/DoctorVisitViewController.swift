import UIKit
import SnapKit

// MARK: - DoctorVisitViewController

final class DoctorVisitViewController: UIViewController {

    private nonisolated enum Section: Int, CaseIterable, Sendable {
        case main
    }

    private nonisolated enum Item: Hashable, Sendable {
        case nextAppointment(UUID)
        case noAppointment
        case sectionHeader(String)
        case upcoming(UUID)
        case past(UUID)
    }

    // MARK: - State
    private var visits: [DoctorVisit] = []
    private var expandedPastIDs: Set<UUID> = []

    // MARK: - Views
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100 * Constraint.yCoeff, right: 0)
        cv.register(DVNextAppointmentCell.self, forCellWithReuseIdentifier: DVNextAppointmentCell.reuseId)
        cv.register(DVSectionHeaderCell.self, forCellWithReuseIdentifier: DVSectionHeaderCell.reuseId)
        cv.register(DVUpcomingCell.self, forCellWithReuseIdentifier: DVUpcomingCell.reuseId)
        cv.register(DVPastVisitCell.self, forCellWithReuseIdentifier: DVPastVisitCell.reuseId)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "empty")
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private lazy var fabButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(hexString: "#8b6dc4")
        b.layer.cornerRadius = 28 * Constraint.yCoeff
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.18
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        return b
    }()

    // top nav
    private let topBar = DVTopBar()

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
        topBar.setBackVisible(isPushed)
        loadData()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(topBar)
        view.addSubview(collectionView)
        view.addSubview(fabButton)

        topBar.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(110 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(topBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        fabButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24 * Constraint.xCoeff)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16 * Constraint.yCoeff)
            $0.width.height.equalTo(56 * Constraint.yCoeff)
        }

        topBar.onCalendarTap = { [weak self] in self?.presentCalendar() }
        topBar.onBackTap = { [weak self] in self?.navigationController?.popViewController(animated: true) }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] cv, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .nextAppointment(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DVNextAppointmentCell.reuseId, for: indexPath) as! DVNextAppointmentCell
                if let visit = self.visits.first(where: { $0.id == id }) {
                    cell.configure(visit: visit)
                    cell.onDirections = { [weak self] in self?.openMaps(clinic: visit.clinic) }
                    cell.onReschedule = { [weak self] in self?.presentEdit(visit: visit) }
                }
                return cell

            case .noAppointment:
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
                cell.contentView.backgroundColor = .clear
                return cell

            case .sectionHeader(let title):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DVSectionHeaderCell.reuseId, for: indexPath) as! DVSectionHeaderCell
                cell.configure(title: title)
                return cell

            case .upcoming(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DVUpcomingCell.reuseId, for: indexPath) as! DVUpcomingCell
                if let visit = self.visits.first(where: { $0.id == id }) {
                    cell.configure(visit: visit)
                    cell.onTap = { [weak self] in self?.presentEdit(visit: visit) }
                }
                return cell

            case .past(let id):
                let cell = cv.dequeueReusableCell(withReuseIdentifier: DVPastVisitCell.reuseId, for: indexPath) as! DVPastVisitCell
                if let visit = self.visits.first(where: { $0.id == id }) {
                    let expanded = self.expandedPastIDs.contains(id)
                    cell.configure(visit: visit, expanded: expanded)
                    cell.onToggle = { [weak self] in
                        guard let self else { return }
                        if self.expandedPastIDs.contains(id) { self.expandedPastIDs.remove(id) }
                        else { self.expandedPastIDs.insert(id) }
                        var snap = self.dataSource.snapshot()
                        snap.reconfigureItems([.past(id)])
                        self.dataSource.apply(snap, animatingDifferences: true)
                    }
                    cell.onDelete = { [weak self] in self?.deleteVisit(id: id) }
                }
                return cell
            }
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)), subitems: [item])
            let sec = NSCollectionLayoutSection(group: group)
            sec.interGroupSpacing = 10 * Constraint.yCoeff
            sec.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
            return sec
        }
    }

    // MARK: - Data
    private func loadData() {
        visits = DoctorVisitStore.load()
        let name = BabyProfileStore.loadName() ?? "Baby"
        let photo = BabyProfileStore.loadPhoto()
        topBar.configure(name: name, photo: photo)
        applySnapshot()
    }

    private func applySnapshot() {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections([.main])

        // Next appointment
        let upcoming = visits.filter { !$0.isPast }.sorted { $0.visitDate < $1.visitDate }
        let past = visits.filter { $0.isPast }.sorted { $0.visitDate > $1.visitDate }

        if let next = upcoming.first {
            snap.appendItems([.nextAppointment(next.id)], toSection: .main)
        }

        // Upcoming section
        if !upcoming.isEmpty {
            snap.appendItems([.sectionHeader("Upcoming")], toSection: .main)
            snap.appendItems(upcoming.map { .upcoming($0.id) }, toSection: .main)
        }

        // Past visits section
        if !past.isEmpty {
            snap.appendItems([.sectionHeader("Past visits")], toSection: .main)
            snap.appendItems(past.map { .past($0.id) }, toSection: .main)
        }

        dataSource.apply(snap, animatingDifferences: true)
    }

    // MARK: - Actions
    @objc private func fabTapped() { presentAddVisit() }

    private func presentAddVisit() {
        let alert = UIAlertController(title: "Add Doctor Visit", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Doctor name" }
        alert.addTextField { $0.placeholder = "Visit reason (e.g. Well-check)" }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self, let doctor = alert?.textFields?[0].text, !doctor.isEmpty,
                  let reason = alert?.textFields?[1].text else { return }
            let v = DoctorVisit(doctorName: doctor, visitDate: Date().addingTimeInterval(7 * 86400),
                                visitTitle: reason.isEmpty ? "Visit" : reason)
            DoctorVisitStore.upsert(v)
            self.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentEdit(visit: DoctorVisit) {
        let alert = UIAlertController(title: visit.visitTitle, message: "\(visit.doctorName)\n\(visit.fullDateTimeString)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Mark completed", style: .default) { [weak self] _ in
            var v = visit; v.isCompleted = true
            DoctorVisitStore.upsert(v); self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "Edit details", style: .default) { [weak self] _ in
            self?.presentEditVisitDetails(visit: visit)
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DoctorVisitStore.delete(id: visit.id); self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentEditVisitDetails(visit: DoctorVisit) {
        let alert = UIAlertController(title: "Edit Visit", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = visit.visitTitle; tf.placeholder = "Visit title" }
        alert.addTextField { tf in tf.text = visit.doctorName; tf.placeholder = "Doctor name" }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            var v = visit
            if let title = alert?.textFields?[0].text, !title.isEmpty { v.visitTitle = title }
            if let doctor = alert?.textFields?[1].text { v.doctorName = doctor }
            DoctorVisitStore.upsert(v)
            self.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentCalendar() {
        if #available(iOS 16.0, *) {
            let vc = DoctorVisitCalendarViewController()
            vc.onWillDismiss = { [weak self] in self?.loadData() }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }

    private func deleteVisit(id: UUID) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DoctorVisitStore.delete(id: id); self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func openMaps(clinic: String) {
        let q = clinic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(q)") { UIApplication.shared.open(url) }
    }
}

// MARK: - DVTopBar

private final class DVTopBar: UIView {

    var onCalendarTap: (() -> Void)?
    var onBackTap: (() -> Void)?

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.isHidden = true
        return b
    }()

    private let avatarView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 18 * Constraint.yCoeff; v.clipsToBounds = true
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.35); return v
    }()
    private let avatarImage = UIImageView()
    private let avatarInitial: UILabel = {
        let l = UILabel(); l.textAlignment = .center
        l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4"); return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "BabyTime"
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private let pageTitle: UILabel = {
        let l = UILabel(); l.text = "Doctor Visits"
        l.font = .systemFont(ofSize: 26 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private lazy var calBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "calendar"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(calTapped), for: .touchUpInside); return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        avatarImage.contentMode = .scaleAspectFill; avatarImage.clipsToBounds = true
        addSubview(backButton)
        addSubview(avatarView); avatarView.addSubview(avatarImage); avatarView.addSubview(avatarInitial)
        addSubview(titleLabel); addSubview(calBtn); addSubview(pageTitle)

        backButton.snp.makeConstraints { $0.leading.equalToSuperview().inset(8 * Constraint.xCoeff); $0.centerY.equalTo(avatarView); $0.width.height.equalTo(36 * Constraint.yCoeff) }
        avatarView.snp.makeConstraints { $0.leading.equalToSuperview().inset(20 * Constraint.xCoeff); $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff); $0.width.height.equalTo(44 * Constraint.yCoeff) }
        avatarImage.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarInitial.snp.makeConstraints { $0.center.equalToSuperview() }
        titleLabel.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff); $0.bottom.equalTo(avatarView.snp.centerY).offset(-1) }
        pageTitle.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff); $0.top.equalTo(avatarView.snp.centerY).offset(2) }
        calBtn.snp.makeConstraints { $0.trailing.equalToSuperview().inset(20 * Constraint.xCoeff); $0.centerY.equalTo(avatarView); $0.width.height.equalTo(36 * Constraint.yCoeff) }

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, photo: UIImage?) {
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

    @objc private func calTapped() { onCalendarTap?() }
    @objc private func backTapped() { onBackTap?() }
}

// MARK: - DVNextAppointmentCell

private final class DVNextAppointmentCell: UICollectionViewCell {
    static let reuseId = "DVNextAppointmentCell"

    var onDirections: (() -> Void)?
    var onReschedule: (() -> Void)?

    private let accentStrip = UIView()
    private let nextLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "NEXT APPOINTMENT",
            attributes: [.kern: 1.0, .font: UIFont.systemFont(ofSize: 10 * Constraint.yCoeff, weight: .semibold),
                         .foregroundColor: UIColor(hexString: "#8b6dc4")])
        return l
    }()
    private let doctorLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private let specialtyLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()
    private let calIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.3)
        iv.contentMode = .scaleAspectFit; return iv
    }()
    private let dateLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 24 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#8b6dc4"); return l
    }()
    private lazy var directionsBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(" Directions", for: .normal); b.setImage(UIImage(systemName: "location.fill"), for: .normal)
        b.tintColor = .white; b.backgroundColor = UIColor(hexString: "#3d2b7a")
        b.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 20 * Constraint.yCoeff
        b.addTarget(self, action: #selector(dirTapped), for: .touchUpInside); return b
    }()
    private lazy var rescheduleBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(" Reschedule", for: .normal); b.setImage(UIImage(systemName: "calendar.badge.clock"), for: .normal)
        b.tintColor = UIColor(hexString: "#c8956a"); b.backgroundColor = UIColor(hexString: "#f5e6d3")
        b.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 20 * Constraint.yCoeff
        b.addTarget(self, action: #selector(resTapped), for: .touchUpInside); return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(hexString: "#f9f6ff")
        contentView.layer.cornerRadius = 20 * Constraint.yCoeff
        contentView.clipsToBounds = true

        accentStrip.backgroundColor = UIColor(hexString: "#8b6dc4")
        accentStrip.layer.cornerRadius = 3

        contentView.addSubview(accentStrip)
        contentView.addSubview(nextLabel)
        contentView.addSubview(doctorLabel)
        contentView.addSubview(specialtyLabel)
        contentView.addSubview(calIconView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(directionsBtn)
        contentView.addSubview(rescheduleBtn)

        accentStrip.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.width.equalTo(5 * Constraint.xCoeff) }
        nextLabel.snp.makeConstraints { $0.leading.equalTo(accentStrip.snp.trailing).offset(16 * Constraint.xCoeff); $0.top.equalToSuperview().inset(18 * Constraint.yCoeff) }
        doctorLabel.snp.makeConstraints { $0.leading.equalTo(nextLabel); $0.top.equalTo(nextLabel.snp.bottom).offset(4 * Constraint.yCoeff); $0.trailing.lessThanOrEqualTo(calIconView.snp.leading).offset(-8) }
        specialtyLabel.snp.makeConstraints { $0.leading.equalTo(nextLabel); $0.top.equalTo(doctorLabel.snp.bottom).offset(2 * Constraint.yCoeff); $0.trailing.lessThanOrEqualTo(calIconView.snp.leading).offset(-8) }
        calIconView.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalToSuperview().inset(20 * Constraint.yCoeff); $0.width.height.equalTo(52 * Constraint.yCoeff) }
        dateLabel.snp.makeConstraints { $0.leading.equalTo(nextLabel); $0.top.equalTo(specialtyLabel.snp.bottom).offset(12 * Constraint.yCoeff) }
        directionsBtn.snp.makeConstraints {
            $0.leading.equalTo(nextLabel); $0.top.equalTo(dateLabel.snp.bottom).offset(14 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(18 * Constraint.yCoeff); $0.height.equalTo(40 * Constraint.yCoeff); $0.width.equalTo(130 * Constraint.xCoeff)
        }
        rescheduleBtn.snp.makeConstraints {
            $0.leading.equalTo(directionsBtn.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.centerY.equalTo(directionsBtn); $0.height.equalTo(40 * Constraint.yCoeff); $0.width.equalTo(130 * Constraint.xCoeff)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(visit: DoctorVisit) {
        doctorLabel.text = visit.doctorName
        let sub = [visit.specialty, visit.clinic].filter { !$0.isEmpty }.joined(separator: " • ")
        specialtyLabel.text = sub
        dateLabel.text = visit.fullDateTimeString
    }

    @objc private func dirTapped() { onDirections?() }
    @objc private func resTapped() { onReschedule?() }
}

// MARK: - DVSectionHeaderCell

private final class DVSectionHeaderCell: UICollectionViewCell {
    static let reuseId = "DVSectionHeaderCell"

    private let label: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
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

// MARK: - DVUpcomingCell

private final class DVUpcomingCell: UICollectionViewCell {
    static let reuseId = "DVUpcomingCell"

    var onTap: (() -> Void)?

    private let monthLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#888888"); l.textAlignment = .center; return l
    }()
    private let dayLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); l.textAlignment = .center; return l
    }()
    private let typeBadge: UIView = {
        let v = UIView(); v.layer.cornerRadius = 8 * Constraint.yCoeff; v.clipsToBounds = true; return v
    }()
    private let typeBadgeLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 10 * Constraint.yCoeff, weight: .semibold); return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }()
    private let doctorLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#888888"); return l
    }()
    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = UIColor(hexString: "#cccccc"); iv.contentMode = .scaleAspectFit; return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        let dateCol = UIView()
        contentView.addSubview(dateCol)
        dateCol.addSubview(monthLabel); dateCol.addSubview(dayLabel)
        typeBadge.addSubview(typeBadgeLabel)
        contentView.addSubview(typeBadge)
        contentView.addSubview(titleLabel)
        contentView.addSubview(doctorLabel)
        contentView.addSubview(chevron)

        dateCol.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff); $0.centerY.equalToSuperview(); $0.width.equalTo(36 * Constraint.xCoeff) }
        monthLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        dayLabel.snp.makeConstraints { $0.top.equalTo(monthLabel.snp.bottom).offset(1); $0.leading.trailing.bottom.equalToSuperview() }

        chevron.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff); $0.centerY.equalToSuperview(); $0.width.height.equalTo(16 * Constraint.yCoeff) }
        typeBadge.snp.makeConstraints { $0.leading.equalTo(dateCol.snp.trailing).offset(14 * Constraint.xCoeff); $0.top.equalToSuperview().inset(14 * Constraint.yCoeff) }
        typeBadgeLabel.snp.makeConstraints { $0.top.bottom.equalToSuperview().inset(3 * Constraint.yCoeff); $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff) }
        titleLabel.snp.makeConstraints { $0.leading.equalTo(typeBadge.snp.leading); $0.top.equalTo(typeBadge.snp.bottom).offset(4 * Constraint.yCoeff); $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8) }
        doctorLabel.snp.makeConstraints { $0.leading.equalTo(titleLabel); $0.top.equalTo(titleLabel.snp.bottom).offset(2 * Constraint.yCoeff); $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(visit: DoctorVisit) {
        monthLabel.text = visit.monthString
        dayLabel.text = visit.dayString
        titleLabel.text = visit.visitTitle
        doctorLabel.text = visit.doctorName

        let (badgeColor, bgColor): (UIColor, UIColor) = {
            switch visit.visitType {
            case "VACCINATION": return (UIColor(hexString: "#8b6dc4"), UIColor(hexString: "#8b6dc4").withAlphaComponent(0.12))
            case "SPECIALIST":  return (UIColor(hexString: "#2980b9"), UIColor(hexString: "#2980b9").withAlphaComponent(0.12))
            case "SICK VISIT":  return (UIColor(hexString: "#e74c3c"), UIColor(hexString: "#e74c3c").withAlphaComponent(0.12))
            default:            return (UIColor(hexString: "#27ae60"), UIColor(hexString: "#27ae60").withAlphaComponent(0.12))
            }
        }()
        typeBadge.backgroundColor = bgColor
        typeBadgeLabel.text = visit.visitType
        typeBadgeLabel.textColor = badgeColor
    }

    @objc private func cellTapped() { onTap?() }
}

// MARK: - DVPastVisitCell

private final class DVPastVisitCell: UICollectionViewCell {
    static let reuseId = "DVPastVisitCell"

    var onToggle: (() -> Void)?
    var onDelete: (() -> Void)?

    // Collapsed row
    private let dateLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#666666"); return l
    }()
    private let dotView: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(hexString: "#cccccc")
        v.layer.cornerRadius = 3 * Constraint.yCoeff; return v
    }()
    private let typeLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#333333"); return l
    }()
    private lazy var viewNotesBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View notes", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        b.setTitleColor(UIColor(hexString: "#8b6dc4"), for: .normal)
        b.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside); return b
    }()
    private lazy var chevronBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside); return b
    }()

    // Expanded detail card
    private let detailCard = UIView()
    private let weightTitleLabel = DVPastVisitCell.makeInfoTitle("WEIGHT")
    private let weightValueLabel = DVPastVisitCell.makeInfoValue()
    private let heightTitleLabel = DVPastVisitCell.makeInfoTitle("HEIGHT")
    private let heightValueLabel = DVPastVisitCell.makeInfoValue()
    private let notesTitleLabel: UILabel = {
        let l = UILabel(); l.text = "Doctor's Notes"
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#aaaaaa"); return l
    }()
    private let notesBodyLabel: UILabel = {
        let l = UILabel(); l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .regular)
        l.textColor = UIColor(hexString: "#333333"); l.numberOfLines = 0; return l
    }()
    private let rxTitleLabel: UILabel = {
        let l = UILabel(); l.text = "Prescriptions"
        l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#aaaaaa"); return l
    }()
    private let rxStack: UIStackView = {
        let s = UIStackView(); s.axis = .vertical; s.spacing = 4 * Constraint.yCoeff; return s
    }()

    private static func makeInfoTitle(_ t: String) -> UILabel {
        let l = UILabel(); l.text = t
        l.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .medium)
        l.textColor = UIColor(hexString: "#aaaaaa"); return l
    }
    private static func makeInfoValue() -> UILabel {
        let l = UILabel(); l.font = .systemFont(ofSize: 24 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a1a"); return l
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16 * Constraint.yCoeff
        contentView.clipsToBounds = true

        detailCard.backgroundColor = .white

        contentView.addSubview(dateLabel)
        contentView.addSubview(dotView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(viewNotesBtn)
        contentView.addSubview(chevronBtn)
        contentView.addSubview(detailCard)

        detailCard.addSubview(weightTitleLabel)
        detailCard.addSubview(weightValueLabel)
        detailCard.addSubview(heightTitleLabel)
        detailCard.addSubview(heightValueLabel)
        detailCard.addSubview(notesTitleLabel)
        detailCard.addSubview(notesBodyLabel)
        detailCard.addSubview(rxTitleLabel)
        detailCard.addSubview(rxStack)

        setupConstraints()
    }
    required init?(coder: NSCoder) { fatalError() }
    override func prepareForReuse() { super.prepareForReuse(); onToggle = nil; onDelete = nil }

    private func setupConstraints() {
        dateLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalToSuperview().inset(14 * Constraint.yCoeff) }
        dotView.snp.makeConstraints { $0.leading.equalTo(dateLabel.snp.trailing).offset(8 * Constraint.xCoeff); $0.centerY.equalTo(dateLabel); $0.width.height.equalTo(6 * Constraint.yCoeff) }
        typeLabel.snp.makeConstraints { $0.leading.equalTo(dotView.snp.trailing).offset(8 * Constraint.xCoeff); $0.centerY.equalTo(dateLabel) }

        chevronBtn.snp.makeConstraints { $0.trailing.equalToSuperview().inset(12 * Constraint.xCoeff); $0.centerY.equalTo(dateLabel); $0.width.height.equalTo(28 * Constraint.yCoeff) }
        viewNotesBtn.snp.makeConstraints { $0.trailing.equalTo(chevronBtn.snp.leading).offset(-4 * Constraint.xCoeff); $0.centerY.equalTo(dateLabel) }

        detailCard.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(dateLabel.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.bottom.equalToSuperview()
        }

        let halfW = (UIScreen.main.bounds.width - 64) / 2
        weightTitleLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalToSuperview().inset(8 * Constraint.yCoeff) }
        weightValueLabel.snp.makeConstraints { $0.leading.equalTo(weightTitleLabel); $0.top.equalTo(weightTitleLabel.snp.bottom).offset(2 * Constraint.yCoeff) }
        heightTitleLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 + halfW * Constraint.xCoeff); $0.top.equalTo(weightTitleLabel) }
        heightValueLabel.snp.makeConstraints { $0.leading.equalTo(heightTitleLabel); $0.top.equalTo(heightTitleLabel.snp.bottom).offset(2 * Constraint.yCoeff) }

        notesTitleLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalTo(weightValueLabel.snp.bottom).offset(14 * Constraint.yCoeff) }
        notesBodyLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalTo(notesTitleLabel.snp.bottom).offset(4 * Constraint.yCoeff) }
        rxTitleLabel.snp.makeConstraints { $0.leading.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalTo(notesBodyLabel.snp.bottom).offset(12 * Constraint.yCoeff) }
        rxStack.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff); $0.top.equalTo(rxTitleLabel.snp.bottom).offset(4 * Constraint.yCoeff); $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff) }
    }

    func configure(visit: DoctorVisit, expanded: Bool) {
        let df = DateFormatter(); df.dateFormat = "MMM d"
        dateLabel.text = df.string(from: visit.visitDate)
        typeLabel.text = visit.visitTitle

        detailCard.isHidden = !expanded
        viewNotesBtn.isHidden = expanded
        chevronBtn.isHidden = !expanded
        chevronBtn.setImage(UIImage(systemName: "chevron.up"), for: .normal)

        if expanded {
            weightValueLabel.text = visit.weightKg.map { String(format: "%.1f kg", $0) } ?? "—"
            heightValueLabel.text = visit.heightCm.map { String(format: "%.0f cm", $0) } ?? "—"
            notesBodyLabel.text = visit.notes.isEmpty ? "No notes recorded." : visit.notes
            notesTitleLabel.isHidden = visit.notes.isEmpty
            notesBodyLabel.isHidden = visit.notes.isEmpty

            rxStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            rxTitleLabel.isHidden = visit.prescriptions.isEmpty
            rxStack.isHidden = visit.prescriptions.isEmpty
            for rx in visit.prescriptions {
                let row = UIStackView()
                row.axis = .horizontal; row.spacing = 6 * Constraint.xCoeff; row.alignment = .center
                let icon = UIImageView(image: UIImage(systemName: "pills.fill"))
                icon.tintColor = UIColor(hexString: "#8b6dc4"); icon.contentMode = .scaleAspectFit
                icon.snp.makeConstraints { $0.width.height.equalTo(16 * Constraint.yCoeff) }
                let lbl = UILabel(); lbl.text = rx
                lbl.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
                lbl.textColor = UIColor(hexString: "#8b6dc4")
                row.addArrangedSubview(icon); row.addArrangedSubview(lbl)
                rxStack.addArrangedSubview(row)
            }

            // hide weight/height if both nil
            let hasMeasurements = visit.weightKg != nil || visit.heightCm != nil
            weightTitleLabel.isHidden = !hasMeasurements; weightValueLabel.isHidden = !hasMeasurements
            heightTitleLabel.isHidden = !hasMeasurements; heightValueLabel.isHidden = !hasMeasurements
        }
    }

    @objc private func toggleTapped() { onToggle?() }
}

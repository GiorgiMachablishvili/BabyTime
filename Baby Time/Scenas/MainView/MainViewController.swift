import UIKit
import SnapKit

class MainViewController: UIViewController {

    var minute = 0

    private enum Section: Int, CaseIterable {
        case stats = 0
        case quickAdd = 1
    }

    private enum QuickAddItem: Int, CaseIterable {
        case feeding
        case sleep
        case diaper
        case growth
        case vaccination
        case doctorVisit
        case historyOfIllness

        var title: String {
            switch self {
            case .feeding: return "Feeding"
            case .sleep: return "Sleep"
            case .diaper: return "Diapers"
            case .growth: return "Growth"
            case .vaccination: return "Vaccination"
            case .doctorVisit: return "Doctor Visit"
            case .historyOfIllness: return "History of illness"
            }
        }

        var iconName: String {
            switch self {
            case .feeding: return "fork.knife"
            case .sleep: return "moon"
            case .diaper: return "figure.child.circle"
            case .growth: return "ruler"
            case .vaccination: return "syringe"
            case .doctorVisit: return "stethoscope"
            case .historyOfIllness: return "heart.text.square"
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .feeding: return .feedingViewColor
            case .sleep: return .sleepViewColor
            case .diaper: return .diaperViewColor
            case .growth, .vaccination, .doctorVisit, .historyOfIllness: return .growthViewColor
            }
        }
    }

    // MARK: - Header

    private lazy var babyButton: UIButton = {
        let view = UIButton(type: .system)
        view.backgroundColor = .feedingViewColor.withAlphaComponent(0.8)
        view.setImage(UIImage(systemName: "person"), for: .normal)
        view.tintColor = .white
        view.makeRoundCorners(33)
        view.clipsToBounds = true
        view.addTarget(self, action: #selector(pressBabyButton), for: .touchUpInside)
        return view
    }()

    private lazy var yourBabyLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Your Baby"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .title1)
        view.textColor = .black
        return view
    }()

    private lazy var babyInfoLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Set up baby profile in Setting"
        view.textAlignment = .left
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.textColor = .gray
        return view
    }()

    private lazy var headerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Collection view

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 20, right: 10)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(MainStatsRowCell.self, forCellWithReuseIdentifier: MainStatsRowCell.reuseId)
        cv.register(MainActionCardCell.self, forCellWithReuseIdentifier: MainActionCardCell.reuseId)
        cv.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader"
        )
        return cv
    }()

    // MARK: - Overlays (feeding / diaper modals)

    private lazy var feedingView: FeedingView = {
        let view = FeedingView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.feedingView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.feedingView.isHidden = true
            }
        }
        return view
    }()

    private lazy var diaper: DiaperView = {
        let view = DiaperView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.diaper.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.diaper.isHidden = true
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        applyBabyProfile()
        collectionView.reloadData()
    }

    private func applyBabyProfile() {
        let name = BabyProfileStore.loadName()
        let birthday = BabyProfileStore.loadBirthday()
        let photo = BabyProfileStore.loadPhoto()

        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            yourBabyLabel.text = name
        } else {
            yourBabyLabel.text = "Your Baby"
        }

        if let birthday {
            babyInfoLabel.text = ageText(from: birthday)
        } else {
            babyInfoLabel.text = "Set up baby profile in Setting"
        }

        if let photo {
            babyButton.setBackgroundImage(photo, for: .normal)
            babyButton.setImage(nil, for: .normal)
            babyButton.backgroundColor = .clear
            babyButton.imageView?.contentMode = .scaleAspectFill
            babyButton.contentHorizontalAlignment = .fill
            babyButton.contentVerticalAlignment = .fill
            babyButton.clipsToBounds = true
        } else {
            babyButton.setBackgroundImage(nil, for: .normal)
            babyButton.setImage(UIImage(systemName: "person"), for: .normal)
            babyButton.tintColor = .white
            babyButton.backgroundColor = .feedingViewColor.withAlphaComponent(0.8)
            babyButton.contentHorizontalAlignment = .center
            babyButton.contentVerticalAlignment = .center
        }
    }

    private func ageText(from birthday: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let start = cal.startOfDay(for: birthday)
        let end = cal.startOfDay(for: now)
        guard end >= start else { return "" }

        let comps = cal.dateComponents([.year, .month, .day], from: start, to: end)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)

        if years == 0 && months == 0 {
            return "\(days) days"
        }
        if years == 0 {
            return "\(months) months \(days) days"
        }
        let weeks = days / 7
        return "\(years) years \(months) months \(weeks) weeks"
    }

    private func setupUI() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(babyButton)
        headerContainer.addSubview(yourBabyLabel)
        headerContainer.addSubview(babyInfoLabel)
        view.addSubview(collectionView)
        view.addSubview(feedingView)
        view.addSubview(diaper)
    }

    private func setupConstraints() {
        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.trailing.equalToSuperview()
        }

        babyButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12 * Constraint.xCoeff)
            make.width.equalTo(66 * Constraint.yCoeff)
            make.height.equalTo(66 * Constraint.xCoeff)
        }

        yourBabyLabel.snp.makeConstraints { make in
            make.bottom.equalTo(babyButton.snp.centerY).offset(-2 * Constraint.xCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        babyInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(babyButton.snp.centerY).offset(2 * Constraint.xCoeff)
            make.leading.equalTo(babyButton.snp.trailing).offset(20 * Constraint.yCoeff)
        }

        headerContainer.snp.makeConstraints { make in
            make.bottom.equalTo(babyInfoLabel.snp.bottom).offset(16 * Constraint.xCoeff)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        feedingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        diaper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        diaper.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    }

    private func switchToTab(index: Int) {
        guard let tabBar = tabBarController, index >= 0, index < (tabBar.viewControllers?.count ?? 0) else { return }
        tabBar.selectedIndex = index
        if let nav = tabBar.viewControllers?[index] as? UINavigationController {
            nav.popToRootViewController(animated: false)
        }
    }

    @objc private func pressBabyButton() {
        switchToTab(index: 4)
    }

    private func handleQuickAddTap(_ item: QuickAddItem) {
        switch item {
        case .feeding:
            switchToTab(index: 1)
        case .sleep:
            switchToTab(index: 2)
        case .diaper:
            switchToTab(index: 3)
        case .growth:
            let vc = GrowthViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .vaccination:
            navigationController?.pushViewController(VaccinationViewController(), animated: true)
        case .doctorVisit:
            navigationController?.pushViewController(DoctorVisitViewController(), animated: true)
        case .historyOfIllness:
            navigationController?.pushViewController(HistoryOfIllnessViewController(), animated: true)
        }
    }

    private func feedingCount() -> Int { 0 }
    private func diaperCount() -> Int { 0 }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .stats: return 1
        case .quickAdd: return QuickAddItem.allCases.count
        case .none: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section) {
        case .stats:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainStatsRowCell.reuseId, for: indexPath) as! MainStatsRowCell
            cell.configure(feedingCount: feedingCount(), sleepMinutes: minute, diaperCount: diaperCount())
            return cell
        case .quickAdd:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainActionCardCell.reuseId, for: indexPath) as! MainActionCardCell
            let item = QuickAddItem(rawValue: indexPath.item)!
            cell.configure(
                backgroundColor: item.backgroundColor,
                icon: UIImage(systemName: item.iconName),
                title: item.title
            )
            cell.onTap = { [weak self] in
                self?.handleQuickAddTap(item)
            }
            return cell
        case .none:
            fatalError("Unexpected section")
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader, Section(rawValue: indexPath.section) == .quickAdd else {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
            header.subviews.forEach { $0.removeFromSuperview() }
            return header
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        let label = UILabel()
        label.text = "Quick Add"
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .black
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 20
        switch Section(rawValue: indexPath.section) {
        case .stats:
            return CGSize(width: width, height: 80 * Constraint.xCoeff)
        case .quickAdd:
            return CGSize(width: width, height: 70 * Constraint.xCoeff)
        case .none:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard Section(rawValue: section) == .quickAdd else {
            return CGSize(width: 0, height: 0)
        }
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
}

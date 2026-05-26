import UIKit
import SnapKit

final class MainViewController: UIViewController {
    // MARK: - Sections & Items
    private enum Section: Int, CaseIterable {
        case profile
        case grid
        case history
    }
    fileprivate enum GridItem: Int, CaseIterable {
        case feeding, sleep, diaper, growth, vaccination, doctorVisit
        var title: String {
            switch self {
            case .feeding:      return "FEEDING"
            case .sleep:        return "SLEEP"
            case .diaper:       return "DIAPERS"
            case .growth:       return "GROWTH"
            case .vaccination:  return "VACCINATION"
            case .doctorVisit:  return "DOCTOR VISIT"
            }
        }
        var iconName: String {
            switch self {
            case .feeding:      return "fork.knife"
            case .sleep:        return "moon"
            case .diaper:       return "figure.child"
            case .growth:       return "ruler"
            case .vaccination:  return "shield"
            case .doctorVisit:  return "stethoscope"
            }
        }
        var cardColor: UIColor {
            switch self {
            case .feeding:      return UIColor(hexString: "#e8f5f0")
            case .sleep:        return UIColor(hexString: "#fce8ec")
            case .diaper:       return UIColor(hexString: "#e8f5ee")
            case .growth:       return UIColor(hexString: "#c5d8dc")
            case .vaccination:  return UIColor.systemBackground
            case .doctorVisit:  return UIColor.systemBackground
            }
        }
        var iconTint: UIColor {
            switch self {
            case .feeding:      return UIColor(hexString: "#6aab90")
            case .sleep:        return UIColor(hexString: "#e07a8a")
            case .diaper:       return UIColor(hexString: "#5a9e72")
            case .growth:       return UIColor(hexString: "#4a7a88")
            case .vaccination:  return UIColor(hexString: "#7a8a9a")
            case .doctorVisit:  return UIColor(hexString: "#7a8a9a")
            }
        }
        var iconBg: UIColor {
            switch self {
            case .feeding:      return UIColor(hexString: "#6aab90").withAlphaComponent(0.18)
            case .sleep:        return UIColor(hexString: "#e07a8a").withAlphaComponent(0.18)
            case .diaper:       return UIColor(hexString: "#5a9e72").withAlphaComponent(0.18)
            case .growth:       return UIColor.white.withAlphaComponent(0.5)
            case .vaccination:  return UIColor(hexString: "#7a8a9a").withAlphaComponent(0.12)
            case .doctorVisit:  return UIColor(hexString: "#7a8a9a").withAlphaComponent(0.12)
            }
        }
    }
    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.backgroundColor = .clear
        v.showsVerticalScrollIndicator = false
        v.alwaysBounceVertical = true
        return v
    }()
    private lazy var contentView = UIView()
    // Profile header
    private lazy var profileContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        v.addGestureRecognizer(tap)
        v.isUserInteractionEnabled = true
        return v
    }()
    private lazy var photoView: UIButton = {
        let v = UIButton(type: .custom)
        v.backgroundColor = UIColor(hexString: "#c5d8dc")
        v.setImage(UIImage(systemName: "person.fill"), for: .normal)
        v.tintColor = .white
        v.layer.cornerRadius = 33 * Constraint.yCoeff
        v.clipsToBounds = true
        v.imageView?.contentMode = .scaleAspectFill
        v.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        return v
    }()
    private lazy var heartBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e07a8a")
        v.layer.cornerRadius = 11 * Constraint.yCoeff
        v.clipsToBounds = true
        let img = UIImageView(image: UIImage(systemName: "heart.fill"))
        img.tintColor = .white
        img.contentMode = .scaleAspectFit
        v.addSubview(img)
        img.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(12 * Constraint.yCoeff) }
        return v
    }()
    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 28, weight: .bold)
        v.textColor = UIColor(hexString: "#222222")
        return v
    }()
    private lazy var ageLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 15, weight: .regular)
        v.textColor = UIColor(hexString: "#888888")
        return v
    }()
    // Grid
    private lazy var gridContainer: UIView = UIView()
    // History row
    private lazy var historyCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0eef8")
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        let tap = UITapGestureRecognizer(target: self, action: #selector(historyTapped))
        v.addGestureRecognizer(tap)
        v.isUserInteractionEnabled = true
        return v
    }()
    private lazy var historyIconBg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.15)
        v.layer.cornerRadius = 20
        return v
    }()
    private lazy var historyIconView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "camera.fill"))
        v.tintColor = UIColor(hexString: "#8b6dc4")
        v.contentMode = .scaleAspectFit
        return v
    }()
    private lazy var historyTopLabel: UILabel = {
        let v = UILabel()
        v.text = "HISTORY"
        v.font = .systemFont(ofSize: 11, weight: .semibold)
        v.textColor = UIColor(hexString: "#888888")
        return v
    }()
    private lazy var historyBottomLabel: UILabel = {
        let v = UILabel()
        v.text = "Baby memories"
        v.font = .systemFont(ofSize: 18, weight: .bold)
        v.textColor = UIColor(hexString: "#222222")
        v.adjustsFontSizeToFitWidth = true
        v.minimumScaleFactor = 0.7
        return v
    }()
    // MARK: - Grid card views (keep reference to update values)
    private var gridCards: [GridItem: HomeGridCard] = [:]
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#f0f2f5")
        setupUI()
        setupConstraints()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        applyBabyProfile()
        updateCardValues()
    }
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        // Profile
        contentView.addSubview(profileContainer)
        profileContainer.addSubview(photoView)
        profileContainer.addSubview(heartBadge)
        profileContainer.addSubview(nameLabel)
        profileContainer.addSubview(ageLabel)
        // Grid
        contentView.addSubview(gridContainer)
        buildGrid()
        // History
        contentView.addSubview(historyCard)
        historyCard.addSubview(historyIconBg)
        historyIconBg.addSubview(historyIconView)
        historyCard.addSubview(historyTopLabel)
        historyCard.addSubview(historyBottomLabel)
    }
    private func buildGrid() {
        // 2-column grid: feeding/sleep, diaper/growth, vaccination/doctorVisit
        let pairs: [(GridItem, GridItem)] = [
            (.feeding, .sleep),
            (.diaper, .growth),
            (.vaccination, .doctorVisit)
        ]
        var lastRow: UIView? = nil
        for (left, right) in pairs {
            let leftCard = HomeGridCard()
            leftCard.configure(item: left, valueText: "—")
            leftCard.onTap = { [weak self] in self?.handleTap(left) }
            let rightCard = HomeGridCard()
            rightCard.configure(item: right, valueText: "—")
            rightCard.onTap = { [weak self] in self?.handleTap(right) }
            gridCards[left] = leftCard
            gridCards[right] = rightCard
            gridContainer.addSubview(leftCard)
            gridContainer.addSubview(rightCard)
            let topAnchor = lastRow?.snp.bottom ?? gridContainer.snp.top
            let offset: CGFloat = lastRow == nil ? 0 : 12 * Constraint.xCoeff
            leftCard.snp.makeConstraints {
                $0.top.equalTo(topAnchor).offset(offset)
                $0.leading.equalToSuperview()
                $0.width.equalToSuperview().multipliedBy(0.5).offset(-6)
                $0.height.equalTo(leftCard.snp.width).multipliedBy(0.95)
            }
            rightCard.snp.makeConstraints {
                $0.top.equalTo(leftCard)
                $0.trailing.equalToSuperview()
                $0.width.equalTo(leftCard)
                $0.height.equalTo(leftCard)
            }
            lastRow = leftCard
        }
        if let lastRow = lastRow {
            gridContainer.snp.makeConstraints {
                $0.bottom.equalTo(lastRow.snp.bottom)
            }
        }
    }
    private func setupConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        let pad: CGFloat = 20 * Constraint.yCoeff
        // Profile
        profileContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        photoView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.height.equalTo(66 * Constraint.yCoeff)
        }
        heartBadge.snp.makeConstraints {
            $0.trailing.equalTo(photoView).offset(4)
            $0.bottom.equalTo(photoView).offset(4)
            $0.width.height.equalTo(22 * Constraint.yCoeff)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(photoView.snp.trailing).offset(14 * Constraint.yCoeff)
            $0.top.equalTo(photoView).offset(8 * Constraint.xCoeff)
        }
        ageLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().offset(-8 * Constraint.xCoeff)
        }
        // Grid
        gridContainer.snp.makeConstraints {
            $0.top.equalTo(profileContainer.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        // History card — same size as one grid card
        historyCard.snp.makeConstraints {
            $0.top.equalTo(gridContainer.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.equalToSuperview().inset(pad)
            $0.width.equalTo(gridContainer.snp.width).multipliedBy(0.5).offset(-6)
            $0.height.equalTo(historyCard.snp.width).multipliedBy(0.95)
        }
        historyIconBg.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        historyIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        historyTopLabel.snp.makeConstraints {
            $0.top.equalTo(historyIconBg.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8 * Constraint.yCoeff)
        }
        historyBottomLabel.snp.makeConstraints {
            $0.top.equalTo(historyTopLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8 * Constraint.yCoeff)
            $0.bottom.lessThanOrEqualToSuperview().offset(-14 * Constraint.xCoeff)
        }
        contentView.snp.makeConstraints {
            $0.bottom.equalTo(historyCard.snp.bottom).offset(32 * Constraint.xCoeff)
        }
    }
    // MARK: - Data
    private func applyBabyProfile() {
        let name = BabyProfileStore.loadName()
        let birthday = BabyProfileStore.loadBirthday()
        let photo = BabyProfileStore.loadPhoto()
        nameLabel.text = name?.isEmpty == false ? name : "Your Baby"
        ageLabel.text = birthday.map { ageText(from: $0) } ?? "Set up profile in Settings"
        if let photo {
            photoView.setBackgroundImage(photo, for: .normal)
            photoView.setImage(nil, for: .normal)
            photoView.contentHorizontalAlignment = .fill
            photoView.contentVerticalAlignment = .fill
            photoView.imageView?.contentMode = .scaleAspectFill
        } else {
            photoView.setBackgroundImage(nil, for: .normal)
            photoView.setImage(UIImage(systemName: "person.fill"), for: .normal)
            photoView.tintColor = .white
            photoView.backgroundColor = UIColor(hexString: "#c5d8dc")
        }
    }
    private func updateCardValues() {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let feedingCount = FeedingLogStore.loadEntries()
            .filter { ($0.savedAtEpochSeconds ?? 0) >= cutoff.timeIntervalSince1970 }.count
        let sleepMins = SleepSessionStore.load().reduce(0) { acc, s in
            let start = max(s.start, cutoff)
            let end = min(s.end, Date())
            return acc + max(0, Int(end.timeIntervalSince(start) / 60))
        }
        let diaperCount = DiaperLogStore.load().filter { $0.date >= cutoff }.count
        let data = GrowthComparisonStore.loadOrMigrate()
        let heightText: String = {
            if let h = data.babyHeightCm, h > 0 {
                return h == floor(h) ? "\(Int(h)) cm" : String(format: "%.1f cm", h)
            }
            return "—"
        }()
        let vacCount = VisitReminderStore.load(kind: .vaccination).count
        let drCount  = VisitReminderStore.load(kind: .doctorVisit).count
        let sleepText: String = {
            let h = sleepMins / 60; let m = sleepMins % 60
            return h > 0 ? "\(h)h \(m)m" : "\(m)m"
        }()
        gridCards[.feeding]?.updateValue(feedingCount == 0 ? "0 times" : "\(feedingCount) times today")
        gridCards[.sleep]?.updateValue(sleepMins == 0 ? "0m" : sleepText)
        gridCards[.diaper]?.updateValue(diaperCount == 0 ? "0 changes" : "\(diaperCount) changes")
        gridCards[.growth]?.updateValue(heightText)
        gridCards[.vaccination]?.updateValue(vacCount == 0 ? "Up to date" : "\(vacCount) upcoming")
        gridCards[.doctorVisit]?.updateValue(drCount == 0 ? "None" : "Next upcoming")
    }
    private func ageText(from birthday: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day],
                                       from: cal.startOfDay(for: birthday),
                                       to: cal.startOfDay(for: now))
        let y = max(0, comps.year ?? 0)
        let m = max(0, comps.month ?? 0)
        let d = max(0, comps.day ?? 0)
        if y == 0 && m == 0 { return "\(d) days" }
        if y == 0 { return "\(m) months \(d) days" }
        return "\(y) years \(m) months \(d / 7) weeks"
    }
    // MARK: - Actions
    @objc private func profileTapped() {
        tabBarController?.selectedIndex = 4
    }
    @objc private func historyTapped() {
        let vc = MemoryViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    private func handleTap(_ item: GridItem) {
        switch item {
        case .feeding:      tabBarController?.selectedIndex = 1
        case .sleep:        tabBarController?.selectedIndex = 2
        case .diaper:
            let vc = DiaperViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .growth:
            let vc = GrowthViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .vaccination:
            let vc = VaccinationViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .doctorVisit:
            let vc = DoctorVisitViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
// MARK: - HomeGridCard
final class HomeGridCard: UIView {
    var onTap: (() -> Void)?
    private let iconBgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        return v
    }()
    private let iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        return v
    }()
    private let topLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 11, weight: .semibold)
        v.textColor = UIColor(hexString: "#888888")
        return v
    }()
    private let valueLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 18, weight: .bold)
        v.textColor = UIColor(hexString: "#222222")
        v.adjustsFontSizeToFitWidth = true
        v.minimumScaleFactor = 0.7
        return v
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(iconBgView)
        iconBgView.addSubview(iconView)
        addSubview(topLabel)
        addSubview(valueLabel)
        iconBgView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20 * Constraint.yCoeff)
        }
        topLabel.snp.makeConstraints {
            $0.top.equalTo(iconBgView.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8 * Constraint.yCoeff)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(topLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8 * Constraint.yCoeff)
            $0.bottom.lessThanOrEqualToSuperview().offset(-14 * Constraint.xCoeff)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }
    fileprivate func configure(item: MainViewController.GridItem, valueText: String) {
        backgroundColor = item.cardColor
        iconBgView.backgroundColor = item.iconBg
        iconView.image = UIImage(systemName: item.iconName)
        iconView.tintColor = item.iconTint
        topLabel.text = item.title
        valueLabel.text = valueText
    }
    func updateValue(_ text: String) {
        valueLabel.text = text
    }
    @objc private func tapped() { onTap?() }
}

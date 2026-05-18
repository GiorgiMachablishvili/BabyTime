import UIKit
import SnapKit

final class GrowthViewController: UIViewController {

    // MARK: - State

    private var allMeasurements: [GrowthMeasurement] = []
    private var selectedType: String = "weight"
    private let accent = UIColor(hexString: "#6557e8")

    private var filteredMeasurements: [GrowthMeasurement] {
        allMeasurements.filter { $0.typeRaw == selectedType }.sorted { $0.date > $1.date }
    }

    // MARK: - Header

    private lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        return v
    }()

    private lazy var avatarButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hexString: "#c5d8dc")
        b.setImage(UIImage(systemName: "person.fill"), for: .normal)
        b.tintColor = .white
        b.layer.cornerRadius = 20 * Constraint.yCoeff
        b.clipsToBounds = true
        return b
    }()

    private lazy var nameAgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .label
        b.layer.cornerRadius = 16 * Constraint.yCoeff
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Scroll

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()

    private lazy var contentView = UIView()

    // MARK: - Title

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Growth"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .label
        return l
    }()

    // MARK: - Segment

    private lazy var segmentContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.92, alpha: 1)
        v.layer.cornerRadius = 12
        return v
    }()

    private lazy var weightPill  = makeSegmentPill("Weight",  tag: 0)
    private lazy var heightPill  = makeSegmentPill("Height",  tag: 1)
    private lazy var headPill    = makeSegmentPill("Head",    tag: 2)

    // MARK: - Current card

    private lazy var currentCard: UIView = makeCard()

    private lazy var currentTypeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        l.letterSpacing(1.0)
        return l
    }()

    private lazy var currentValueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 44, weight: .bold)
        l.textColor = .label
        return l
    }()

    private lazy var percentileBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = accent
        l.backgroundColor = accent.withAlphaComponent(0.1)
        l.layer.cornerRadius = 10
        l.layer.borderWidth = 1
        l.layer.borderColor = accent.withAlphaComponent(0.3).cgColor
        l.clipsToBounds = true
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private lazy var changeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(hexString: "#4aad6f")
        l.isHidden = true
        return l
    }()

    // MARK: - Chart card

    private lazy var chartCard: UIView = makeCard()

    private lazy var chartTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Growth Chart"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private lazy var whoLabel: UILabel = {
        let l = UILabel()
        l.text = "WHO Standards"
        l.font = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
        return l
    }()

    private lazy var chartView: GrowthChartView = {
        let v = GrowthChartView()
        return v
    }()

    // MARK: - History

    private lazy var historyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "History"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        return l
    }()

    private lazy var historyStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        return s
    }()

    // MARK: - Add button

    private lazy var addMeasurementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Add measurement", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = accent
        b.layer.cornerRadius = 16
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Sheet

    private lazy var addSheetView: GrowthAddSheetView = {
        let v = GrowthAddSheetView()
        v.isHidden = true
        v.onClose = { [weak self] in self?.dismissSheet() }
        v.onSave = { [weak self] value, percentile, date in
            guard let self else { return }
            var m = GrowthMeasurement(
                typeRaw: self.selectedType,
                value: value,
                date: date,
                percentile: percentile
            )
            self.allMeasurements.append(m)
            GrowthMeasurementStore.save(self.allMeasurements)
            self.dismissSheet()
            self.refreshUI()
        }
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        allMeasurements = GrowthMeasurementStore.load()
        setupUI()
        setupConstraints()
        selectSegment(index: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        let isPushed = navigationController?.viewControllers.count ?? 0 > 1
        backButton.isHidden = !isPushed
        let hPad = 16 * Constraint.xCoeff
        avatarButton.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(isPushed ? 44 * Constraint.xCoeff : hPad)
        }
        refreshHeader()
    }

    // MARK: - Header

    private func refreshHeader() {
        let name = BabyProfileStore.loadName() ?? "Baby"
        nameAgeLabel.text = "\(name)\(babyAgeSuffix())"
        if let photo = BabyProfileStore.loadPhoto() {
            avatarButton.setBackgroundImage(photo, for: .normal)
            avatarButton.setImage(nil, for: .normal)
            avatarButton.contentHorizontalAlignment = .fill
            avatarButton.contentVerticalAlignment = .fill
        }
    }

    private func babyAgeSuffix() -> String {
        guard let bday = BabyProfileStore.loadBirthday() else { return "" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day],
                                       from: cal.startOfDay(for: bday),
                                       to: cal.startOfDay(for: Date()))
        let y = max(0, comps.year ?? 0)
        let m = max(0, comps.month ?? 0)
        let d = max(0, comps.day ?? 0)
        if y == 0 && m == 0 && d == 0 { return "" }
        if y == 0 && m == 0 { return ", \(d) days" }
        if y == 0 { return ", \(m) months \(d) days" }
        return ", \(y) years \(m) months \(d) days"
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(avatarButton)
        headerView.addSubview(nameAgeLabel)
        headerView.addSubview(addButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(segmentContainer)
        segmentContainer.addSubview(weightPill)
        segmentContainer.addSubview(heightPill)
        segmentContainer.addSubview(headPill)

        contentView.addSubview(currentCard)
        currentCard.addSubview(currentTypeLabel)
        currentCard.addSubview(currentValueLabel)
        currentCard.addSubview(percentileBadge)
        currentCard.addSubview(changeLabel)

        contentView.addSubview(chartCard)
        chartCard.addSubview(chartTitleLabel)
        chartCard.addSubview(whoLabel)
        chartCard.addSubview(chartView)

        contentView.addSubview(historyTitleLabel)
        contentView.addSubview(historyStack)
        contentView.addSubview(addMeasurementButton)

        view.addSubview(addSheetView)
    }

    private func setupConstraints() {
        let hPad = 16 * Constraint.xCoeff

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        avatarButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(hPad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        nameAgeLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarButton.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(hPad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32 * Constraint.yCoeff)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }

        segmentContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(40 * Constraint.yCoeff)
        }
        weightPill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(4)
            $0.width.equalTo(segmentContainer).multipliedBy(1.0/3.0).offset(-4)
        }
        heightPill.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalTo(weightPill.snp.trailing).offset(2)
            $0.width.equalTo(weightPill)
        }
        headPill.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview().inset(4)
            $0.leading.equalTo(heightPill.snp.trailing).offset(2)
        }

        currentCard.snp.makeConstraints {
            $0.top.equalTo(segmentContainer.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        currentTypeLabel.snp.makeConstraints {
            $0.top.leading.equalTo(currentCard).inset(16 * Constraint.xCoeff)
        }
        currentValueLabel.snp.makeConstraints {
            $0.top.equalTo(currentTypeLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(currentCard).offset(16 * Constraint.xCoeff)
        }
        percentileBadge.snp.makeConstraints {
            $0.top.trailing.equalTo(currentCard).inset(16 * Constraint.xCoeff)
            $0.height.equalTo(24 * Constraint.yCoeff)
            $0.width.greaterThanOrEqualTo(90 * Constraint.xCoeff)
        }
        changeLabel.snp.makeConstraints {
            $0.top.equalTo(currentValueLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.equalTo(currentCard).offset(16 * Constraint.xCoeff)
            $0.bottom.equalTo(currentCard).inset(16 * Constraint.xCoeff)
        }

        chartCard.snp.makeConstraints {
            $0.top.equalTo(currentCard.snp.bottom).offset(14 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        chartTitleLabel.snp.makeConstraints {
            $0.top.leading.equalTo(chartCard).inset(16 * Constraint.xCoeff)
        }
        whoLabel.snp.makeConstraints {
            $0.centerY.equalTo(chartTitleLabel)
            $0.trailing.equalTo(chartCard).inset(16 * Constraint.xCoeff)
        }
        chartView.snp.makeConstraints {
            $0.top.equalTo(chartTitleLabel.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.equalTo(chartCard).inset(16 * Constraint.xCoeff)
            $0.height.equalTo(180 * Constraint.yCoeff)
            $0.bottom.equalTo(chartCard).inset(16 * Constraint.xCoeff)
        }

        historyTitleLabel.snp.makeConstraints {
            $0.top.equalTo(chartCard.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
        }
        historyStack.snp.makeConstraints {
            $0.top.equalTo(historyTitleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
        }
        addMeasurementButton.snp.makeConstraints {
            $0.top.equalTo(historyStack.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(54 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(32 * Constraint.xCoeff)
        }

        addSheetView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Segment control

    private func makeSegmentPill(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        b.layer.cornerRadius = 9
        b.tag = tag
        b.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        return b
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        selectSegment(index: sender.tag)
    }

    private func selectSegment(index: Int) {
        let types = ["weight", "height", "head"]
        selectedType = types[index]
        let pills = [weightPill, heightPill, headPill]
        for (i, pill) in pills.enumerated() {
            if i == index {
                pill.backgroundColor = UIColor(hexString: "#1a1a2e")
                pill.setTitleColor(.white, for: .normal)
            } else {
                pill.backgroundColor = .clear
                pill.setTitleColor(UIColor.secondaryLabel, for: .normal)
            }
        }
        refreshUI()
    }

    // MARK: - Refresh

    private func refreshUI() {
        refreshHeader()
        let entries = filteredMeasurements
        let unit = selectedType == "weight" ? "kg" : "cm"

        // Current card
        switch selectedType {
        case "weight": currentTypeLabel.text = "CURRENT WEIGHT"
        case "height": currentTypeLabel.text = "CURRENT HEIGHT"
        case "head":   currentTypeLabel.text = "CURRENT HEAD CIRCUMFERENCE"
        default: break
        }

        if let latest = entries.first {
            let fmt = selectedType == "weight"
                ? String(format: "%.1f \(unit)", latest.value)
                : String(format: "%.0f \(unit)", latest.value)
            currentValueLabel.text = fmt

            if let pct = latest.percentile {
                percentileBadge.text = "  \(ordinal(pct)) percentile  "
                percentileBadge.isHidden = false
            } else {
                percentileBadge.isHidden = true
            }

            if entries.count >= 2 {
                let prev = entries[1]
                let diff = latest.value - prev.value
                let days = Int(latest.date.timeIntervalSince(prev.date) / 86400)
                let weeks = max(1, days / 7)
                let sign = diff >= 0 ? "↗ +" : "↘ "
                let diffStr = selectedType == "weight"
                    ? (abs(diff) >= 1 ? String(format: "%.1f kg", abs(diff)) : "\(Int(abs(diff * 1000)))g")
                    : String(format: "%.0f cm", abs(diff))
                changeLabel.text = "\(sign)\(diffStr) in \(weeks) week\(weeks == 1 ? "" : "s")"
                changeLabel.textColor = diff >= 0 ? UIColor(hexString: "#4aad6f") : UIColor.systemRed
                changeLabel.isHidden = false
            } else {
                changeLabel.isHidden = true
            }
        } else {
            currentValueLabel.text = "—"
            percentileBadge.isHidden = true
            changeLabel.isHidden = true
        }

        // Chart
        chartView.unit = unit
        if let bday = BabyProfileStore.loadBirthday() {
            chartView.points = entries.map { m in
                let ageMonths = m.date.timeIntervalSince(bday) / (30.44 * 86400)
                return (ageMonths: max(0, ageMonths), value: m.value)
            }
        } else {
            let sorted = entries.sorted { $0.date < $1.date }
            chartView.points = sorted.enumerated().map { i, m in (ageMonths: Double(i), value: m.value) }
        }

        // History
        historyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, m) in entries.prefix(20).enumerated() {
            let row = makeHistoryRow(measurement: m, unit: unit)
            historyStack.addArrangedSubview(row)
            if i < entries.count - 1 {
                let sep = UIView()
                sep.backgroundColor = UIColor(white: 0.9, alpha: 1)
                historyStack.addArrangedSubview(sep)
                sep.snp.makeConstraints { $0.height.equalTo(0.5) }
            }
        }

        if entries.isEmpty {
            let empty = UILabel()
            empty.text = "No entries yet. Tap '+ Add measurement' to start."
            empty.font = .systemFont(ofSize: 13)
            empty.textColor = .secondaryLabel
            empty.numberOfLines = 0
            historyStack.addArrangedSubview(empty)
        }
    }

    private func makeHistoryRow(measurement: GrowthMeasurement, unit: String) -> UIView {
        let row = UIView()

        let iconBg = UIView()
        iconBg.backgroundColor = UIColor(white: 0.93, alpha: 1)
        iconBg.layer.cornerRadius = 10
        let iconImg = UIImageView(image: UIImage(systemName: "calendar"))
        iconImg.tintColor = .secondaryLabel
        iconImg.contentMode = .scaleAspectFit
        iconBg.addSubview(iconImg)
        row.addSubview(iconBg)

        let df = DateFormatter(); df.dateFormat = "MMM d, yyyy"
        let dateL = UILabel()
        dateL.text = df.string(from: measurement.date)
        dateL.font = .systemFont(ofSize: 14, weight: .semibold)
        dateL.textColor = .label
        row.addSubview(dateL)

        let ageL = UILabel()
        ageL.text = ageText(for: measurement.date)
        ageL.font = .systemFont(ofSize: 12)
        ageL.textColor = .secondaryLabel
        row.addSubview(ageL)

        let valStr = unit == "kg"
            ? String(format: "%.1f %@", measurement.value, unit)
            : String(format: "%.0f %@", measurement.value, unit)
        let valueL = UILabel()
        valueL.text = valStr
        valueL.font = .systemFont(ofSize: 15, weight: .bold)
        valueL.textColor = accent
        row.addSubview(valueL)

        let pctL = UILabel()
        if let p = measurement.percentile {
            pctL.text = "\(ordinal(p)) %"
            pctL.font = .systemFont(ofSize: 12)
            pctL.textColor = .secondaryLabel
        }
        row.addSubview(pctL)

        iconBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(38 * Constraint.yCoeff)
        }
        iconImg.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(18 * Constraint.yCoeff)
        }
        dateL.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.leading.equalTo(iconBg.snp.trailing).offset(10)
        }
        ageL.snp.makeConstraints {
            $0.top.equalTo(dateL.snp.bottom).offset(2)
            $0.leading.equalTo(dateL)
            $0.bottom.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
        valueL.snp.makeConstraints {
            $0.top.equalTo(dateL)
            $0.trailing.equalToSuperview().inset(4)
        }
        pctL.snp.makeConstraints {
            $0.top.equalTo(valueL.snp.bottom).offset(2)
            $0.trailing.equalTo(valueL)
        }

        return row
    }

    private func ageText(for date: Date) -> String {
        guard let bday = BabyProfileStore.loadBirthday() else { return "" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.month, .day], from: bday, to: date)
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        if m == 0 { return "\(d) days old" }
        return "\(m) months old"
    }

    // MARK: - Sheet

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addTapped() {
        addSheetView.configure(type: selectedType)
        addSheetView.isHidden = false
        addSheetView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5) {
            self.addSheetView.transform = .identity
        }
    }

    private func dismissSheet() {
        UIView.animate(withDuration: 0.3) {
            self.addSheetView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.addSheetView.isHidden = true
            self.addSheetView.transform = .identity
        }
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 6
        return v
    }

    private func ordinal(_ n: Int) -> String {
        switch n % 100 {
        case 11, 12, 13: return "\(n)th"
        default:
            switch n % 10 {
            case 1: return "\(n)st"
            case 2: return "\(n)nd"
            case 3: return "\(n)rd"
            default: return "\(n)th"
            }
        }
    }
}

private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }
        attributedText = NSAttributedString(string: text, attributes: [.kern: spacing])
    }
}

import UIKit
import SnapKit

// MARK: - GrowthHistoryViewController

final class GrowthHistoryViewController: UIViewController {

    // MARK: State
    private let accent   = UIColor(hexString: "#8b6dc4")
    private let peach    = UIColor(hexString: "#f0a878")
    private var allMeasurements: [GrowthMeasurement] = []
    private var selectedType = "weight"

    // MARK: Header
    private lazy var headerView: UIView = {
        let v = UIView(); v.backgroundColor = .white; return v
    }()
    private lazy var backBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()
    private lazy var titleLbl: UILabel = {
        let l = UILabel()
        l.text = "Growth History"
        l.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        return l
    }()
    private lazy var avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.35)
        v.layer.cornerRadius = 18 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()
    private lazy var avatarImg: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv
    }()
    private lazy var avatarInit: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        l.textColor = accent; l.textAlignment = .center; return l
    }()
    private lazy var gearBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "gearshape"), for: .normal)
        b.tintColor = accent; return b
    }()

    // MARK: Scroll
    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView(); s.showsVerticalScrollIndicator = false; s.alwaysBounceVertical = true; return s
    }()
    private lazy var contentView = UIView()

    // MARK: Stat Cards
    private lazy var weightCard  = GrowthStatCard(iconName: "scalemass.fill",    iconBg: UIColor(hexString: "#e8eeff"), iconTint: UIColor(hexString: "#5b7ff5"), label: "Current Weight", unit: "kg")
    private lazy var heightCard  = GrowthStatCard(iconName: "ruler.fill",         iconBg: UIColor(hexString: "#e6f5ee"), iconTint: UIColor(hexString: "#4caf83"), label: "Current Height", unit: "cm")
    private lazy var headCard    = GrowthStatCard(iconName: "circle.dashed",      iconBg: UIColor(hexString: "#e6f5ee"), iconTint: UIColor(hexString: "#4caf83"), label: "Head Circ.",    unit: "cm")

    // MARK: Curve card
    private lazy var curveCard: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16 * Constraint.yCoeff
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()
    private lazy var curveTitleLbl: UILabel = {
        let l = UILabel()
        l.text = "Growth Curve"
        l.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        return l
    }()
    private lazy var segContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0ecfa")
        v.layer.cornerRadius = 14 * Constraint.yCoeff
        return v
    }()
    private lazy var wPill  = makeSegPill("Weight", tag: 0)
    private lazy var hPill  = makeSegPill("Height", tag: 1)
    private lazy var hcPill = makeSegPill("Head",   tag: 2)
    private lazy var chartView = GrowthHistoryChartView(accent: accent)

    // Legend
    private lazy var legendStack: UIStackView = {
        let s = UIStackView(); s.axis = .horizontal; s.spacing = 16 * Constraint.xCoeff; return s
    }()

    // MARK: Recent Logs
    private lazy var logsHeaderView: UIView = UIView()
    private lazy var logsTitleLbl: UILabel = {
        let l = UILabel()
        l.text = "Recent Logs"
        l.font = .systemFont(ofSize: 17 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        return l
    }()
    private lazy var viewAllBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View All", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .medium)
        b.tintColor = accent
        b.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        return b
    }()
    private lazy var logsStack: UIStackView = {
        let s = UIStackView(); s.axis = .vertical; s.spacing = 0; return s
    }()

    // MARK: Add sheet
    private lazy var addSheet: GrowthAddSheetView = {
        let v = GrowthAddSheetView()
        v.isHidden = true
        v.onClose = { [weak self] in self?.dismissSheet() }
        v.onSave  = { [weak self] value, pct, date in
            guard let self else { return }
            let m = GrowthMeasurement(typeRaw: self.addSheet.measurementType, value: value, date: date, percentile: pct)
            self.allMeasurements.append(m)
            GrowthMeasurementStore.save(self.allMeasurements)
            if AuthStore.isLoggedIn { APIClient.addGrowthMeasurement(m) { _ in } }
            self.dismissSheet()
            self.refreshAll()
        }
        return v
    }()

    // MARK: Bottom bar
    private lazy var bottomBar: UIView = {
        let v = UIView(); v.backgroundColor = .white; return v
    }()
    private lazy var addMeasBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Add New Measurement", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15 * Constraint.yCoeff, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = accent
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()
    private lazy var chartIconBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chart.bar.fill"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = peach
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        return b
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#f5f4fb")
        navigationController?.setNavigationBarHidden(true, animated: false)
        allMeasurements = GrowthMeasurementStore.load()
        setupUI()
        setupConstraints()
        selectSegment(0)
        refreshAvatar()
        if AuthStore.isLoggedIn { fetchFromBackend() }
    }

    private func fetchFromBackend() {
        APIClient.getGrowthMeasurements { [weak self] result in
            guard let self, case .success(let responses) = result else { return }
            let iso = ISO8601DateFormatter()
            let serverItems: [GrowthMeasurement] = responses.compactMap { r in
                guard let uuid = UUID(uuidString: r.id),
                      let date = iso.date(from: r.date) else { return nil }
                return GrowthMeasurement(id: uuid, typeRaw: r.type_raw, value: r.value, date: date, percentile: r.percentile.map { Int($0) })
            }
            let serverIDs = Set(serverItems.map { $0.id })
            let localOnly = self.allMeasurements.filter { !serverIDs.contains($0.id) }
            let merged = (serverItems + localOnly).sorted { $0.date > $1.date }
            GrowthMeasurementStore.save(merged)
            self.allMeasurements = merged
            self.refreshAll()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: Setup

    private func setupUI() {
        // Header
        view.addSubview(headerView)
        headerView.addSubview(backBtn)
        headerView.addSubview(titleLbl)
        headerView.addSubview(avatarView)
        avatarView.addSubview(avatarImg)
        avatarView.addSubview(avatarInit)
        headerView.addSubview(gearBtn)

        // Scroll
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Stat cards
        [weightCard, heightCard, headCard].forEach { contentView.addSubview($0) }

        // Curve card
        contentView.addSubview(curveCard)
        curveCard.addSubview(curveTitleLbl)
        curveCard.addSubview(segContainer)
        segContainer.addSubview(wPill); segContainer.addSubview(hPill); segContainer.addSubview(hcPill)
        curveCard.addSubview(chartView)
        curveCard.addSubview(legendStack)
        legendStack.addArrangedSubview(makeLegendItem(color: accent,                              label: "Baby's Progress", dashed: false))
        legendStack.addArrangedSubview(makeLegendItem(color: UIColor(white: 0.65, alpha: 1),     label: "WHO Percentile",  dashed: true))

        // Logs
        contentView.addSubview(logsHeaderView)
        logsHeaderView.addSubview(logsTitleLbl)
        logsHeaderView.addSubview(viewAllBtn)
        contentView.addSubview(logsStack)

        // Bottom bar
        view.addSubview(bottomBar)
        bottomBar.addSubview(addMeasBtn)
        bottomBar.addSubview(chartIconBtn)

        // Sheet (on top of everything)
        view.addSubview(addSheet)
    }

    private func setupConstraints() {
        let pad = 16 * Constraint.xCoeff

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        backBtn.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        titleLbl.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(backBtn.snp.trailing).offset(4 * Constraint.xCoeff)
        }
        gearBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(pad)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        avatarView.snp.makeConstraints {
            $0.trailing.equalTo(gearBtn.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        avatarImg.snp.makeConstraints  { $0.edges.equalToSuperview() }
        avatarInit.snp.makeConstraints { $0.center.equalToSuperview() }

        bottomBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(80 * Constraint.yCoeff)
        }
        addMeasBtn.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(pad)
            $0.top.equalToSuperview().offset(12 * Constraint.yCoeff)
            $0.trailing.equalTo(chartIconBtn.snp.leading).offset(-10 * Constraint.xCoeff)
            $0.height.equalTo(50 * Constraint.yCoeff)
        }
        chartIconBtn.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(pad)
            $0.top.equalTo(addMeasBtn)
            $0.width.height.equalTo(50 * Constraint.yCoeff)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBar.snp.top)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Stat cards
        weightCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        heightCard.snp.makeConstraints {
            $0.top.equalTo(weightCard.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        headCard.snp.makeConstraints {
            $0.top.equalTo(heightCard.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }

        // Curve card
        curveCard.snp.makeConstraints {
            $0.top.equalTo(headCard.snp.bottom).offset(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        curveTitleLbl.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16 * Constraint.xCoeff)
        }
        segContainer.snp.makeConstraints {
            $0.centerY.equalTo(curveTitleLbl)
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.height.equalTo(28 * Constraint.yCoeff)
        }
        wPill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(3)
            $0.width.equalTo(56 * Constraint.xCoeff)
        }
        hPill.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(3)
            $0.leading.equalTo(wPill.snp.trailing).offset(2)
            $0.width.equalTo(wPill)
        }
        hcPill.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview().inset(3)
            $0.leading.equalTo(hPill.snp.trailing).offset(2)
            $0.width.equalTo(wPill)
        }
        chartView.snp.makeConstraints {
            $0.top.equalTo(curveTitleLbl.snp.bottom).offset(12 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(8 * Constraint.xCoeff)
            $0.height.equalTo(180 * Constraint.yCoeff)
        }
        legendStack.snp.makeConstraints {
            $0.top.equalTo(chartView.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16 * Constraint.yCoeff)
        }

        // Logs
        logsHeaderView.snp.makeConstraints {
            $0.top.equalTo(curveCard.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(28 * Constraint.yCoeff)
        }
        logsTitleLbl.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        viewAllBtn.snp.makeConstraints   { $0.trailing.centerY.equalToSuperview() }
        logsStack.snp.makeConstraints {
            $0.top.equalTo(logsHeaderView.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.bottom.equalToSuperview().inset(20 * Constraint.yCoeff)
        }

        addSheet.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: Helpers

    private func makeSegPill(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 10 * Constraint.yCoeff
        b.tag = tag
        b.addTarget(self, action: #selector(segTapped(_:)), for: .touchUpInside)
        return b
    }

    private func makeLegendItem(color: UIColor, label: String, dashed: Bool) -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = dashed ? .clear : color
        if dashed {
            let dash = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 4))
            path.addLine(to: CGPoint(x: 20, y: 4))
            dash.path = path.cgPath
            dash.strokeColor = color.cgColor
            dash.lineWidth = 2
            dash.lineDashPattern = [4, 3]
            line.layer.addSublayer(dash)
        }
        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 11 * Constraint.yCoeff)
        lbl.textColor = UIColor(hexString: "#888888")

        container.addSubview(line); container.addSubview(lbl)
        line.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.equalTo(20 * Constraint.xCoeff)
            $0.height.equalTo(8 * Constraint.yCoeff)
        }
        lbl.snp.makeConstraints {
            $0.leading.equalTo(line.snp.trailing).offset(4)
            $0.centerY.trailing.equalToSuperview()
        }
        return container
    }

    // MARK: Data refresh

    private func refreshAvatar() {
        let name = BabyProfileStore.loadName() ?? "Baby"
        if let photo = BabyProfileStore.loadPhoto() {
            avatarImg.image = photo; avatarInit.isHidden = true
        } else {
            avatarImg.image = nil
            avatarInit.text = String(name.prefix(1)).uppercased()
            avatarInit.isHidden = false
        }
    }

    private func refreshAll() {
        allMeasurements = GrowthMeasurementStore.load()
        refreshStatCards()
        refreshChart()
        refreshLogs()
    }

    private func refreshStatCards() {
        let sorted = allMeasurements.sorted { $0.date > $1.date }
        let latestW  = sorted.first(where: { $0.typeRaw == "weight" })
        let latestH  = sorted.first(where: { $0.typeRaw == "height" })
        let latestHc = sorted.first(where: { $0.typeRaw == "head"   })
        weightCard.setValue(latestW.map  { String(format: "%.1f", $0.value) } ?? "–")
        heightCard.setValue(latestH.map  { String(format: "%.0f", $0.value) } ?? "–")
        headCard.setValue(latestHc.map   { String(format: "%.0f", $0.value) } ?? "–")
    }

    private func refreshChart() {
        let typeKey = selectedType
        let entries = allMeasurements.filter { $0.typeRaw == typeKey }.sorted { $0.date < $1.date }
        guard let bday = BabyProfileStore.loadBirthday() else {
            chartView.babyPoints = entries.enumerated().map { (Double($0), $1.value) }
            chartView.whoPoints  = []
            chartView.unit = typeKey == "weight" ? "kg" : "cm"
            chartView.setNeedsDisplay()
            return
        }
        chartView.babyPoints = entries.map { m in
            let months = m.date.timeIntervalSince(bday) / (30.44 * 86400)
            return (max(0, months), m.value)
        }
        let currentMonths = Date().timeIntervalSince(bday) / (30.44 * 86400)
        chartView.whoPoints  = whoData(for: typeKey, upTo: currentMonths)
        chartView.unit = typeKey == "weight" ? "kg" : "cm"
        chartView.setNeedsDisplay()
    }

    private func whoData(for type: String, upTo maxMonths: Double) -> [(Double, Double)] {
        // WHO 50th percentile (median) – approximate values
        let weightWHO: [(Double, Double)] = [(0,3.3),(1,4.4),(2,5.6),(3,6.4),(4,7.0),(5,7.5),(6,7.9),(7,8.3),(8,8.6),(9,8.9),(10,9.2),(11,9.4),(12,9.6),(18,10.9),(24,12.2)]
        let heightWHO: [(Double, Double)] = [(0,49.9),(1,54.7),(2,58.4),(3,61.4),(4,63.9),(5,65.9),(6,67.6),(7,69.2),(8,70.6),(9,72.0),(10,73.3),(11,74.5),(12,75.7),(18,82.3),(24,87.8)]
        let headWHO:   [(Double, Double)] = [(0,34.5),(1,37.3),(2,39.1),(3,40.5),(4,41.6),(5,42.6),(6,43.3),(7,44.0),(8,44.5),(9,45.0),(10,45.4),(11,45.8),(12,46.2),(18,47.6),(24,48.5)]
        let data: [(Double, Double)]
        switch type {
        case "weight": data = weightWHO
        case "height": data = heightWHO
        default:       data = headWHO
        }
        return data.filter { $0.0 <= maxMonths + 1 }
    }

    private func refreshLogs() {
        logsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let monthLogs = buildMonthLogs(limit: 6)
        if monthLogs.isEmpty {
            let lbl = UILabel()
            lbl.text = "No measurements yet."
            lbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff)
            lbl.textColor = UIColor(hexString: "#999999")
            logsStack.addArrangedSubview(lbl)
            return
        }
        for log in monthLogs {
            logsStack.addArrangedSubview(makeLogCard(log))
        }
    }

    private struct MonthLog {
        let monthLabel: String   // "Oct 24"
        let ageLabel:   String   // "4 months 12 days"
        let date:       Date
        let weight: Double?
        let height: Double?
        let head:   Double?
    }

    private func buildMonthLogs(limit: Int) -> [MonthLog] {
        let cal = DateFormatter()
        cal.dateFormat = "MMM yy"
        let sorted = allMeasurements.sorted { $0.date > $1.date }

        var groups: [(key: String, date: Date, items: [GrowthMeasurement])] = []
        for m in sorted {
            let key = cal.string(from: m.date)
            if let idx = groups.firstIndex(where: { $0.key == key }) {
                groups[idx].items.append(m)
            } else {
                groups.append((key: key, date: m.date, items: [m]))
            }
        }

        return groups.prefix(limit).map { group in
            let w  = group.items.first(where: { $0.typeRaw == "weight" })?.value
            let h  = group.items.first(where: { $0.typeRaw == "height" })?.value
            let hc = group.items.first(where: { $0.typeRaw == "head"   })?.value
            return MonthLog(
                monthLabel: group.key,
                ageLabel:   ageText(for: group.date),
                date:       group.date,
                weight: w, height: h, head: hc
            )
        }
    }

    private func ageText(for date: Date) -> String {
        guard let bday = BabyProfileStore.loadBirthday() else { return "" }
        let comps = Calendar.current.dateComponents([.month, .day], from: bday, to: date)
        let m = max(0, comps.month ?? 0); let d = max(0, comps.day ?? 0)
        if m == 0 { return "\(d) days" }
        return "\(m) months \(d) days"
    }

    private func makeLogCard(_ log: MonthLog) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 14 * Constraint.yCoeff
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6

        // Date header
        let dateLbl = UILabel()
        dateLbl.text = log.monthLabel
        dateLbl.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .semibold)
        dateLbl.textColor = UIColor(hexString: "#1a1a2e")

        let ageLbl = UILabel()
        ageLbl.text = log.ageLabel
        ageLbl.font = .systemFont(ofSize: 12 * Constraint.yCoeff)
        ageLbl.textColor = UIColor(hexString: "#999999")

        // Measurement columns
        let measureRow = UIStackView()
        measureRow.axis = .horizontal
        measureRow.distribution = .fillEqually
        measureRow.spacing = 0

        func makeCol(type: String, value: Double?) -> UIView {
            let col = UIView()
            let typeL = UILabel()
            typeL.text = type
            typeL.font = .systemFont(ofSize: 9 * Constraint.yCoeff, weight: .bold)
            typeL.textColor = UIColor(hexString: "#aaaaaa")
            typeL.letterSpacing = 0.8

            let unit = (type == "WEIGHT") ? "kg" : "cm"
            let valueL = UILabel()
            valueL.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
            valueL.textColor = UIColor(hexString: "#1a1a2e")

            let unitL = UILabel()
            unitL.text = unit
            unitL.font = .systemFont(ofSize: 10 * Constraint.yCoeff)
            unitL.textColor = UIColor(hexString: "#999999")

            if let v = value {
                valueL.text = (type == "WEIGHT") ? String(format: "%.1f", v) : String(format: "%.0f", v)
            } else {
                valueL.text = "–"; unitL.text = ""
            }

            col.addSubview(typeL); col.addSubview(valueL); col.addSubview(unitL)
            typeL.snp.makeConstraints  { $0.top.leading.equalToSuperview() }
            valueL.snp.makeConstraints { $0.top.equalTo(typeL.snp.bottom).offset(2); $0.leading.equalToSuperview() }
            unitL.snp.makeConstraints  { $0.leading.equalTo(valueL.snp.trailing).offset(2); $0.lastBaseline.equalTo(valueL) }
            col.snp.makeConstraints    { $0.bottom.equalTo(valueL.snp.bottom) }
            return col
        }

        measureRow.addArrangedSubview(makeCol(type: "WEIGHT", value: log.weight))
        measureRow.addArrangedSubview(makeCol(type: "HEIGHT", value: log.height))
        measureRow.addArrangedSubview(makeCol(type: "HEAD",   value: log.head))

        card.addSubview(dateLbl); card.addSubview(ageLbl); card.addSubview(measureRow)

        dateLbl.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14 * Constraint.xCoeff)
        }
        ageLbl.snp.makeConstraints {
            $0.top.equalTo(dateLbl.snp.bottom).offset(1)
            $0.leading.equalTo(dateLbl)
        }
        measureRow.snp.makeConstraints {
            $0.top.equalTo(ageLbl.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(14 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }

        let wrapper = UIView()
        wrapper.addSubview(card)
        card.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview().inset(10 * Constraint.yCoeff) }
        return wrapper
    }

    // MARK: Segment

    private func selectSegment(_ tag: Int) {
        let types = ["weight", "height", "head"]
        selectedType = types[tag]
        let pills = [wPill, hPill, hcPill]
        for (i, p) in pills.enumerated() {
            p.backgroundColor = i == tag ? accent : .clear
            p.setTitleColor(i == tag ? .white : UIColor(hexString: "#8b6dc4"), for: .normal)
        }
        refreshAll()
    }

    // MARK: Actions

    @objc private func segTapped(_ sender: UIButton) { selectSegment(sender.tag) }

    @objc private func addTapped() {
        let alert = UIAlertController(title: "Add Measurement", message: nil, preferredStyle: .actionSheet)
        for (title, type) in [("Weight (kg)", "weight"), ("Height (cm)", "height"), ("Head Circ. (cm)", "head")] {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.showAddSheet(type: type)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showAddSheet(type: String) {
        addSheet.configure(type: type)
        addSheet.isHidden = false
        addSheet.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) {
            self.addSheet.transform = .identity
        }
    }

    private func dismissSheet() {
        UIView.animate(withDuration: 0.3) {
            self.addSheet.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.addSheet.isHidden = true
            self.addSheet.transform = .identity
        }
    }

    @objc private func viewAllTapped() { /* already showing up to 6; could push full list */ }
    @objc private func backTapped()    { navigationController?.popViewController(animated: true) }
}

// MARK: - UILabel letterSpacing helper
private extension UILabel {
    var letterSpacing: CGFloat {
        get { 0 }
        set {
            guard let t = text else { return }
            attributedText = NSAttributedString(string: t, attributes: [.kern: newValue, .font: font as Any, .foregroundColor: textColor as Any])
        }
    }
}

// MARK: - GrowthStatCard

final class GrowthStatCard: UIView {

    private let valueLbl = UILabel()
    private let unitLbl  = UILabel()

    init(iconName: String, iconBg: UIColor, iconTint: UIColor, label: String, unit: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 14 * Constraint.yCoeff
        layer.shadowColor  = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset  = CGSize(width: 0, height: 2)
        layer.shadowRadius  = 6

        let iconBgView = UIView()
        iconBgView.backgroundColor = iconBg
        iconBgView.layer.cornerRadius = 12 * Constraint.yCoeff

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit

        let labelLbl = UILabel()
        labelLbl.text = label
        labelLbl.font = .systemFont(ofSize: 11 * Constraint.yCoeff)
        labelLbl.textColor = UIColor(hexString: "#999999")

        valueLbl.font = .systemFont(ofSize: 24 * Constraint.yCoeff, weight: .bold)
        valueLbl.textColor = UIColor(hexString: "#1a1a2e")
        valueLbl.text = "–"

        unitLbl.text = unit
        unitLbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff)
        unitLbl.textColor = UIColor(hexString: "#999999")

        iconBgView.addSubview(iconView)
        addSubview(iconBgView); addSubview(labelLbl); addSubview(valueLbl); addSubview(unitLbl)

        iconBgView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(42 * Constraint.yCoeff)
        }
        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(22 * Constraint.yCoeff)
        }
        labelLbl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14 * Constraint.yCoeff)
            $0.leading.equalTo(iconBgView.snp.trailing).offset(12 * Constraint.xCoeff)
        }
        valueLbl.snp.makeConstraints {
            $0.top.equalTo(labelLbl.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.leading.equalTo(labelLbl)
            $0.bottom.equalToSuperview().inset(14 * Constraint.yCoeff)
        }
        unitLbl.snp.makeConstraints {
            $0.leading.equalTo(valueLbl.snp.trailing).offset(4)
            $0.lastBaseline.equalTo(valueLbl)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ text: String) { valueLbl.text = text }
}

// MARK: - GrowthHistoryChartView

final class GrowthHistoryChartView: UIView {

    var babyPoints: [(Double, Double)] = [] { didSet { setNeedsDisplay() } }
    var whoPoints:  [(Double, Double)] = [] { didSet { setNeedsDisplay() } }
    var unit = "kg"

    private let accent: UIColor
    private let padL: CGFloat = 38
    private let padR: CGFloat = 12
    private let padT: CGFloat = 10
    private let padB: CGFloat = 28

    init(accent: UIColor) { self.accent = accent; super.init(frame: .zero); backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let allPts = babyPoints + whoPoints
        guard !allPts.isEmpty else { drawEmpty(rect); return }

        let chartR = CGRect(x: padL, y: padT, width: rect.width - padL - padR, height: rect.height - padT - padB)
        let allX = allPts.map { $0.0 }
        let allY = allPts.map { $0.1 }
        let minX = allX.min()!; let maxX = max(allX.max()!, minX + 1)
        let rawMinY = allY.min()!; let rawMaxY = allY.max()!
        let yPad = (rawMaxY - rawMinY) * 0.20
        let minY = max(0, rawMinY - yPad); let maxY = rawMaxY + yPad

        drawGrid(chartR, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        if !whoPoints.isEmpty  { drawWHO(chartR,  minX: minX, maxX: maxX, minY: minY, maxY: maxY) }
        if !babyPoints.isEmpty { drawBaby(chartR, minX: minX, maxX: maxX, minY: minY, maxY: maxY) }
        drawXLabels(chartR, minX: minX, maxX: maxX)
    }

    private func pt(_ p: (Double, Double), in r: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) -> CGPoint {
        CGPoint(
            x: r.minX + CGFloat((p.0 - minX) / (maxX - minX)) * r.width,
            y: r.maxY - CGFloat((p.1 - minY) / (maxY - minY)) * r.height
        )
    }

    private func drawGrid(_ r: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let ctx = UIGraphicsGetCurrentContext()!
        let gridColor = UIColor(white: 0.93, alpha: 1)
        let lf = UIFont.systemFont(ofSize: 9, weight: .medium)
        let la: [NSAttributedString.Key: Any] = [.font: lf, .foregroundColor: UIColor(white: 0.6, alpha: 1)]
        for i in 0...4 {
            let y = r.maxY - CGFloat(i) / 4 * r.height
            ctx.setStrokeColor(gridColor.cgColor); ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: r.minX, y: y)); ctx.addLine(to: CGPoint(x: r.maxX, y: y)); ctx.strokePath()
            let val = minY + (maxY - minY) * Double(i) / 4
            let s = unit == "kg" ? String(format: "%.1f", val) : String(format: "%.0f", val)
            let sz = s.size(withAttributes: la)
            s.draw(at: CGPoint(x: r.minX - sz.width - 3, y: y - sz.height/2), withAttributes: la)
        }
    }

    private func drawBaby(_ r: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let ctx = UIGraphicsGetCurrentContext()!
        let sorted = babyPoints.sorted { $0.0 < $1.0 }
        let pts = sorted.map { pt($0, in: r, minX: minX, maxX: maxX, minY: minY, maxY: maxY) }

        if pts.count > 1 {
            // Fill
            let fill = UIBezierPath()
            fill.move(to: CGPoint(x: pts.first!.x, y: r.maxY))
            pts.forEach { fill.addLine(to: $0) }
            fill.addLine(to: CGPoint(x: pts.last!.x, y: r.maxY)); fill.close()
            accent.withAlphaComponent(0.10).setFill(); fill.fill()
            // Line
            let line = UIBezierPath(); line.move(to: pts.first!)
            pts.dropFirst().forEach { line.addLine(to: $0) }
            ctx.setStrokeColor(accent.cgColor); ctx.setLineWidth(2)
            ctx.setLineCap(.round); ctx.setLineJoin(.round); line.stroke()
        }
        // Dots
        for (i, p) in pts.enumerated() {
            if i < pts.count - 1 {
                ctx.setFillColor(accent.withAlphaComponent(0.45).cgColor)
                ctx.fillEllipse(in: CGRect(x: p.x-3.5, y: p.y-3.5, width: 7, height: 7))
            } else {
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fillEllipse(in: CGRect(x: p.x-6, y: p.y-6, width: 12, height: 12))
                ctx.setFillColor(accent.cgColor)
                ctx.fillEllipse(in: CGRect(x: p.x-4, y: p.y-4, width: 8, height: 8))
            }
        }
    }

    private func drawWHO(_ r: CGRect, minX: Double, maxX: Double, minY: Double, maxY: Double) {
        let ctx = UIGraphicsGetCurrentContext()!
        let sorted = whoPoints.sorted { $0.0 < $1.0 }
        let pts = sorted.map { pt($0, in: r, minX: minX, maxX: maxX, minY: minY, maxY: maxY) }
        guard pts.count > 1 else { return }
        let path = UIBezierPath(); path.move(to: pts.first!)
        pts.dropFirst().forEach { path.addLine(to: $0) }
        let dashes: [CGFloat] = [5, 4]
        ctx.setStrokeColor(UIColor(white: 0.65, alpha: 1).cgColor)
        ctx.setLineWidth(1.5); ctx.setLineDash(phase: 0, lengths: dashes)
        path.stroke(); ctx.setLineDash(phase: 0, lengths: [])
    }

    private func drawXLabels(_ r: CGRect, minX: Double, maxX: Double) {
        let lf = UIFont.systemFont(ofSize: 9, weight: .medium)
        let la: [NSAttributedString.Key: Any] = [.font: lf, .foregroundColor: UIColor(white: 0.55, alpha: 1)]
        let labels: [(Double, String)] = [(0,"Birth"),(1,"1mo"),(2,"2mo"),(3,"3mo"),(maxX,"Now")]
        for (m, txt) in labels where m <= maxX + 0.5 {
            let x = r.minX + CGFloat((m - minX) / max(maxX - minX, 1)) * r.width
            let sz = txt.size(withAttributes: la)
            txt.draw(at: CGPoint(x: x - sz.width/2, y: r.maxY + 5), withAttributes: la)
        }
    }

    private func drawEmpty(_ rect: CGRect) {
        let s = "No data yet"
        let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.tertiaryLabel]
        let sz = s.size(withAttributes: a)
        s.draw(at: CGPoint(x: (rect.width-sz.width)/2, y: (rect.height-sz.height)/2), withAttributes: a)
    }
}

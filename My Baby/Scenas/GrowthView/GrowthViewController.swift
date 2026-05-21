import UIKit
import SnapKit

// MARK: - GrowthViewController

final class GrowthViewController: UIViewController {

    // MARK: State
    private let accent        = UIColor(hexString: "#8b6dc4")
    private let peach         = UIColor(hexString: "#f0a878")
    private var isMetric      = true
    private var isSingleParent = false
    private var compData      = GrowthComparisonStore.loadOrMigrate()
    private var selectedDate  = Date()

    // MARK: Header
    private lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .viewsBackGourdColor
        return v
    }()
    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = UIColor(hexString: "#555555")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()
    private lazy var avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#e8b5f5").withAlphaComponent(0.35)
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        v.clipsToBounds = true
        return v
    }()
    private lazy var avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private lazy var avatarInitLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        l.textColor = accent
        l.textAlignment = .center
        return l
    }()
    private lazy var gearButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "gearshape"), for: .normal)
        b.tintColor = accent
        return b
    }()
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Growth Comparison"
        l.font = .systemFont(ofSize: 20 * Constraint.yCoeff, weight: .bold)
        l.textColor = UIColor(hexString: "#1a1a2e")
        return l
    }()
    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "See how your baby is growing\ncompared to the family."
        l.font = .systemFont(ofSize: 11 * Constraint.yCoeff)
        l.textColor = UIColor(hexString: "#888888")
        l.numberOfLines = 2
        return l
    }()

    // MARK: Scroll
    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()
    private lazy var contentView = UIView()

    // MARK: Unit toggle
    private lazy var unitBg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.88, alpha: 1)
        v.layer.cornerRadius = 12 * Constraint.yCoeff
        return v
    }()
    private lazy var cmBtn = makeUnitBtn("cm", tag: 0)
    private lazy var ftBtn = makeUnitBtn("ft", tag: 1)

    // MARK: Comparison card
    private lazy var compCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#f0ecfa")
        v.layer.cornerRadius = 20 * Constraint.yCoeff
        return v
    }()
    private lazy var changeFamilyBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "person.2.fill"), for: .normal)
        b.setTitle("  Change Family Setup", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 11 * Constraint.yCoeff, weight: .medium)
        b.tintColor = accent
        b.setTitleColor(accent, for: .normal)
        b.semanticContentAttribute = .forceLeftToRight
        b.addTarget(self, action: #selector(changeFamilyTapped), for: .touchUpInside)
        return b
    }()
    private lazy var familyView = FamilyHeightView(accent: accent)

    // MARK: Input rows
    private lazy var motherField  = GrowthInputRow(labelText: "Mother height",           unit: "cm")
    private lazy var fatherField  = GrowthInputRow(labelText: "Father height",           unit: "cm")
    private lazy var babyHField   = GrowthInputRow(labelText: "Baby height",             unit: "cm")
    private lazy var babyWField   = GrowthInputRow(labelText: "Baby weight",             unit: "kg")
    private lazy var babyHcField  = GrowthInputRow(labelText: "Baby head circumference", unit: "cm")
    private lazy var dateInputRow = GrowthDateRow()

    private lazy var fieldsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [motherField, fatherField, babyHField, babyWField, babyHcField, dateInputRow])
        s.axis = .vertical
        s.spacing = 10 * Constraint.yCoeff
        return s
    }()

    // MARK: Action buttons
    private lazy var saveBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+ Save Measurement", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = accent
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()
    private lazy var historyBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "clock"), for: .normal)
        b.setTitle("  View History", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .medium)
        b.tintColor = peach
        b.setTitleColor(peach, for: .normal)
        b.backgroundColor = peach.withAlphaComponent(0.15)
        b.layer.cornerRadius = 14 * Constraint.yCoeff
        b.semanticContentAttribute = .forceLeftToRight
        b.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        return b
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hexString: "#f5f4fb")
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupConstraints()
        prefillFields()
        updateFieldsForFamilyType()
        updateUnitToggle()
        updateFamilyView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKB))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        allInputFields().forEach {
            $0.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        }
        dateInputRow.onDateChanged = { [weak self] date in
            self?.selectedDate = date
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        let isPushed = (navigationController?.viewControllers.count ?? 0) > 1
        backButton.isHidden = !isPushed
        avatarView.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(isPushed ? 44 * Constraint.xCoeff : 16 * Constraint.xCoeff)
        }
        refreshAvatar()
    }

    // MARK: Setup

    private func setupUI() {
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarInitLabel)
        headerView.addSubview(gearButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(unitBg)
        unitBg.addSubview(cmBtn)
        unitBg.addSubview(ftBtn)

        contentView.addSubview(compCard)
        compCard.addSubview(changeFamilyBtn)
        compCard.addSubview(familyView)

        contentView.addSubview(fieldsStack)
        contentView.addSubview(saveBtn)
        contentView.addSubview(historyBtn)
    }

    private func setupConstraints() {
        let pad = 16 * Constraint.xCoeff

        // Header
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(80 * Constraint.yCoeff)
        }
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8 * Constraint.xCoeff)
            $0.top.equalToSuperview().offset(12 * Constraint.yCoeff)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.top.equalToSuperview().offset(10 * Constraint.yCoeff)
            $0.width.height.equalTo(40 * Constraint.yCoeff)
        }
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarInitLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        gearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(pad)
            $0.top.equalToSuperview().offset(10 * Constraint.yCoeff)
            $0.width.height.equalTo(36 * Constraint.yCoeff)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(10 * Constraint.xCoeff)
            $0.top.equalTo(avatarView)
            $0.trailing.lessThanOrEqualTo(gearButton.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(2 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(gearButton.snp.leading).offset(-8)
        }

        // Scroll
        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Unit toggle — top-right, above card
        unitBg.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(30 * Constraint.yCoeff)
            $0.width.equalTo(76 * Constraint.xCoeff)
        }
        cmBtn.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(3)
            $0.width.equalToSuperview().multipliedBy(0.5).offset(-2)
        }
        ftBtn.snp.makeConstraints {
            $0.trailing.top.bottom.equalToSuperview().inset(3)
            $0.width.equalTo(cmBtn)
        }

        // Comparison card — full width, starts at same top as unit toggle
        compCard.snp.makeConstraints {
            $0.top.equalToSuperview().offset(58 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }
        changeFamilyBtn.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(12 * Constraint.yCoeff)
        }
        familyView.snp.makeConstraints {
            $0.top.equalTo(changeFamilyBtn.snp.bottom).offset(8 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(12 * Constraint.xCoeff)
            $0.height.equalTo(200 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(16 * Constraint.yCoeff)
        }

        // Input rows stack
        fieldsStack.snp.makeConstraints {
            $0.top.equalTo(compCard.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
        }

        // Buttons
        saveBtn.snp.makeConstraints {
            $0.top.equalTo(fieldsStack.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
        historyBtn.snp.makeConstraints {
            $0.top.equalTo(saveBtn.snp.bottom).offset(10 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(pad)
            $0.height.equalTo(52 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().inset(30 * Constraint.yCoeff)
        }
    }

    // MARK: Helpers

    private func makeUnitBtn(_ title: String, tag: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .semibold)
        b.layer.cornerRadius = 9 * Constraint.yCoeff
        b.tag = tag
        b.addTarget(self, action: #selector(unitTapped(_:)), for: .touchUpInside)
        return b
    }

    private func allInputFields() -> [UITextField] {
        [motherField.textField, fatherField.textField,
         babyHField.textField, babyWField.textField, babyHcField.textField]
    }

    // MARK: Data

    private func prefillFields() {
        if let h = compData.parent1HeightCm { motherField.textField.text = fmt(h, dec: 0) }
        if let h = compData.parent2HeightCm { fatherField.textField.text = fmt(h, dec: 0) }
        if let h = compData.babyHeightCm    { babyHField.textField.text  = fmt(h, dec: 1) }

        let all = GrowthMeasurementStore.load()
        if let w = all.filter({ $0.typeRaw == "weight" }).first {
            babyWField.textField.text = fmt(w.value, dec: 1)
        }
        if let hc = all.filter({ $0.typeRaw == "head" }).first {
            babyHcField.textField.text = fmt(hc.value, dec: 0)
        }
    }

    private func fmt(_ v: Double, dec: Int) -> String {
        String(format: "%.\(dec)f", v)
    }

    private func refreshAvatar() {
        let name = BabyProfileStore.loadName() ?? "Baby"
        if let photo = BabyProfileStore.loadPhoto() {
            avatarImageView.image = photo
            avatarInitLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarInitLabel.text = String(name.prefix(1)).uppercased()
            avatarInitLabel.isHidden = false
        }
    }

    // MARK: Unit toggle

    private func updateUnitToggle() {
        cmBtn.backgroundColor = isMetric ? accent : .clear
        cmBtn.setTitleColor(isMetric ? .white : UIColor(hexString: "#666666"), for: .normal)
        ftBtn.backgroundColor = isMetric ? .clear : accent
        ftBtn.setTitleColor(isMetric ? UIColor(hexString: "#666666") : .white, for: .normal)

        motherField.unitLabel.text  = isMetric ? "cm" : "ft"
        fatherField.unitLabel.text  = isMetric ? "cm" : "ft"
        babyHField.unitLabel.text   = isMetric ? "cm" : "ft"
        babyHcField.unitLabel.text  = isMetric ? "cm" : "in"

        updateFamilyView()
    }

    // MARK: Family view

    private func updateFamilyView() {
        familyView.update(
            p1H:          motherH(),
            babyH:        babyH(),
            babyW:        babyW(),
            babyHc:       babyHc(),
            p2H:          isSingleParent ? nil : fatherH(),
            p1Type:       compData.parent1Type,
            p2Type:       compData.parent2Type,
            p1Name:       compData.parent1Type.displayName,
            p2Name:       compData.parent2Type.displayName,
            isSingle:     isSingleParent,
            isMetric:     isMetric
        )
    }

    private func motherH() -> Double? { parse(motherField.textField.text) }
    private func fatherH() -> Double? { parse(fatherField.textField.text) }
    private func babyH()   -> Double? { parse(babyHField.textField.text) }
    private func babyW()   -> Double? { parse(babyWField.textField.text) }
    private func babyHc()  -> Double? { parse(babyHcField.textField.text) }

    private func parse(_ text: String?) -> Double? {
        Double(text?.replacingOccurrences(of: ",", with: ".") ?? "")
    }

    // MARK: Actions

    @objc private func unitTapped(_ sender: UIButton) {
        isMetric = sender.tag == 0
        updateUnitToggle()
    }

    @objc private func fieldChanged() {
        compData.parent1HeightCm = motherH()
        compData.parent2HeightCm = isSingleParent ? nil : fatherH()
        compData.babyHeightCm    = babyH()
        updateFamilyView()
    }

    @objc private func saveTapped() {
        compData.parent1HeightCm = motherH()
        compData.parent2HeightCm = isSingleParent ? nil : fatherH()
        compData.babyHeightCm    = babyH()
        GrowthComparisonStore.save(compData)

        var measurements = GrowthMeasurementStore.load()
        let date = selectedDate
        if let h  = babyH()  { measurements.append(GrowthMeasurement(typeRaw: "height", value: h,  date: date, percentile: nil)) }
        if let w  = babyW()  { measurements.append(GrowthMeasurement(typeRaw: "weight", value: w,  date: date, percentile: nil)) }
        if let hc = babyHc() { measurements.append(GrowthMeasurement(typeRaw: "head",   value: hc, date: date, percentile: nil)) }
        GrowthMeasurementStore.save(measurements)

        if let h = babyH() { GrowthComparisonStore.appendHistoryEntry(babyHeightCm: h) }
        updateFamilyView()

        let alert = UIAlertController(title: "Saved!", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { alert.dismiss(animated: true) }
    }

    @objc private func historyTapped() {
        let vc = GrowthHistoryViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func changeFamilyTapped() {
        let alert = UIAlertController(title: "Family Setup", message: "Select family type", preferredStyle: .actionSheet)

        // (title, p1Type, p2Type, singleParent)
        let options: [(String, GrowthComparisonData.ParentType, GrowthComparisonData.ParentType, Bool)] = [
            ("Father + Mother", .father, .mother, false),
            ("Mother + Father", .mother, .father, false),
            ("Mother + Mother", .mother, .mother, false),
            ("Father + Father", .father, .father, false),
            ("Mother",          .mother, .mother, true),
            ("Father",          .father, .father, true),
        ]
        for (title, p1, p2, single) in options {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.compData.parent1Type = p1
                self.compData.parent2Type = p2
                self.isSingleParent = single
                GrowthComparisonStore.save(self.compData)
                self.updateFieldsForFamilyType()
                self.updateFamilyView()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func updateFieldsForFamilyType() {
        let p1 = compData.parent1Type
        let p2 = compData.parent2Type

        if isSingleParent {
            // One parent only — show only motherField (parent1), hide fatherField
            let label = p1 == .mother ? "Mother height" : "Father height"
            motherField.setLabelText(label)
            fatherField.isHidden = true
        } else {
            fatherField.isHidden = false
            // Label each field according to parent type
            switch (p1, p2) {
            case (.mother, .father): motherField.setLabelText("Mother height"); fatherField.setLabelText("Father height")
            case (.father, .mother): motherField.setLabelText("Father height"); fatherField.setLabelText("Mother height")
            case (.mother, .mother): motherField.setLabelText("Mother 1 height"); fatherField.setLabelText("Mother 2 height")
            case (.father, .father): motherField.setLabelText("Father 1 height"); fatherField.setLabelText("Father 2 height")
            default: break
            }
        }
    }

    @objc private func backTapped()  { navigationController?.popViewController(animated: true) }
    @objc private func dismissKB()   { view.endEditing(true) }
}

// MARK: - FamilyHeightView

final class FamilyHeightView: UIView {

    private let accent: UIColor
    private let maxBarH: CGFloat = 140 * Constraint.yCoeff

    // Bars
    private let p1Bar   = UIView()
    private let babyBar = UIView()
    private let p2Bar   = UIView()

    // Icons inside bars
    private let p1Icon   = UIImageView()
    private let babyIcon = UIImageView()
    private let p2Icon   = UIImageView()

    // Labels
    private let p1NameLbl   = UILabel()
    private let p1HLbl      = UILabel()
    private let babyNameLbl = UILabel()
    private let babyHLbl    = UILabel()
    private let p2NameLbl   = UILabel()
    private let p2HLbl      = UILabel()

    // Measurement chips on baby bar
    private let hChip  = GrowthChip()
    private let wChip  = GrowthChip()
    private let hcChip = GrowthChip()

    // Bar containers (fixed height, bars anchor to their bottom)
    private let p1Container   = UIView()
    private let babyContainer = UIView()
    private let p2Container   = UIView()

    private var p1BarHC:   SnapKit.Constraint?
    private var babyBarHC: SnapKit.Constraint?
    private var p2BarHC:   SnapKit.Constraint?

    init(accent: UIColor) {
        self.accent = accent
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // Bar styles
        let barRadius = 18 * Constraint.xCoeff
        p1Bar.layer.cornerRadius   = barRadius
        babyBar.layer.cornerRadius = barRadius
        p2Bar.layer.cornerRadius   = barRadius

        p1Bar.backgroundColor   = UIColor(white: 0.80, alpha: 1)
        babyBar.backgroundColor = accent.withAlphaComponent(0.25)
        p2Bar.backgroundColor   = UIColor(white: 0.80, alpha: 1)

        // Icons
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 22)
        p1Icon.image   = UIImage(systemName: "figure.stand", withConfiguration: iconCfg)
        babyIcon.image = UIImage(systemName: "figure.child", withConfiguration: iconCfg)
        p2Icon.image   = UIImage(systemName: "figure.stand", withConfiguration: iconCfg)
        for iv in [p1Icon, p2Icon] { iv.tintColor = UIColor(white: 0.50, alpha: 1); iv.contentMode = .scaleAspectFit }
        babyIcon.tintColor = accent; babyIcon.contentMode = .scaleAspectFit

        // Name labels
        for l in [p1NameLbl, p2NameLbl] {
            l.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .medium)
            l.textColor = UIColor(hexString: "#666666"); l.textAlignment = .center
        }
        babyNameLbl.font = .systemFont(ofSize: 12 * Constraint.yCoeff, weight: .semibold)
        babyNameLbl.textColor = accent; babyNameLbl.textAlignment = .center

        // Height labels
        for l in [p1HLbl, p2HLbl] {
            l.font = .systemFont(ofSize: 11 * Constraint.yCoeff)
            l.textColor = UIColor(hexString: "#999999"); l.textAlignment = .center
        }
        babyHLbl.font = .systemFont(ofSize: 11 * Constraint.yCoeff)
        babyHLbl.textColor = accent; babyHLbl.textAlignment = .center

        // Build hierarchy
        p1Bar.addSubview(p1Icon)
        babyBar.addSubview(babyIcon)
        babyBar.addSubview(hChip)
        babyBar.addSubview(wChip)
        babyBar.addSubview(hcChip)
        p2Bar.addSubview(p2Icon)

        p1Container.addSubview(p1Bar)
        babyContainer.addSubview(babyBar)
        p2Container.addSubview(p2Bar)

        let colStack = UIStackView(arrangedSubviews: [p1Container, babyContainer, p2Container])
        colStack.axis = .horizontal
        colStack.distribution = .fillEqually
        colStack.spacing = 14 * Constraint.xCoeff

        addSubview(colStack)
        addSubview(p1NameLbl);   addSubview(p1HLbl)
        addSubview(babyNameLbl); addSubview(babyHLbl)
        addSubview(p2NameLbl);   addSubview(p2HLbl)

        // colStack fills top portion, labels below
        let labelH = 34 * Constraint.yCoeff
        colStack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(labelH)
        }

        // Bars anchor to bottom of their containers
        p1Bar.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.72)
            p1BarHC = $0.height.equalTo(maxBarH).constraint
        }
        babyBar.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.72)
            babyBarHC = $0.height.equalTo(maxBarH * 0.4).constraint
        }
        p2Bar.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.72)
            p2BarHC = $0.height.equalTo(maxBarH).constraint
        }

        // Icons inside bars
        p1Icon.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(22 * Constraint.xCoeff)
            $0.height.equalTo(36 * Constraint.yCoeff)
        }
        babyIcon.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(18 * Constraint.xCoeff)
            $0.height.equalTo(28 * Constraint.yCoeff)
        }
        p2Icon.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10 * Constraint.yCoeff)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(22 * Constraint.xCoeff)
            $0.height.equalTo(36 * Constraint.yCoeff)
        }

        // Chips stack vertically on baby bar
        hChip.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(8 * Constraint.yCoeff)
            $0.height.equalTo(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(4 * Constraint.xCoeff)
        }
        wChip.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(hChip.snp.top).offset(-4 * Constraint.yCoeff)
            $0.height.equalTo(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(4 * Constraint.xCoeff)
        }
        hcChip.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(wChip.snp.top).offset(-4 * Constraint.yCoeff)
            $0.height.equalTo(16 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(4 * Constraint.xCoeff)
        }

        // Name / height labels below colStack
        p1NameLbl.snp.makeConstraints {
            $0.top.equalTo(colStack.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.centerX.equalTo(p1Container)
        }
        p1HLbl.snp.makeConstraints {
            $0.top.equalTo(p1NameLbl.snp.bottom).offset(1)
            $0.centerX.equalTo(p1Container)
        }
        babyNameLbl.snp.makeConstraints {
            $0.top.equalTo(colStack.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.centerX.equalTo(babyContainer)
        }
        babyHLbl.snp.makeConstraints {
            $0.top.equalTo(babyNameLbl.snp.bottom).offset(1)
            $0.centerX.equalTo(babyContainer)
        }
        p2NameLbl.snp.makeConstraints {
            $0.top.equalTo(colStack.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.centerX.equalTo(p2Container)
        }
        p2HLbl.snp.makeConstraints {
            $0.top.equalTo(p2NameLbl.snp.bottom).offset(1)
            $0.centerX.equalTo(p2Container)
        }
    }

    func update(p1H: Double?, babyH: Double?, babyW: Double?, babyHc: Double?,
                p2H: Double?,
                p1Type: GrowthComparisonData.ParentType,
                p2Type: GrowthComparisonData.ParentType,
                p1Name: String, p2Name: String,
                isSingle: Bool, isMetric: Bool) {

        // Update silhouette icons
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 22)
        let womanIcon = UIImage(systemName: "figure.stand.dress", withConfiguration: iconCfg)
        let manIcon   = UIImage(systemName: "figure.stand",       withConfiguration: iconCfg)
        p1Icon.image = p1Type == .mother ? womanIcon : manIcon
        p2Icon.image = p2Type == .mother ? womanIcon : manIcon

        // Show/hide right parent column for single parent
        p2Container.isHidden  = isSingle
        p2NameLbl.isHidden    = isSingle
        p2HLbl.isHidden       = isSingle

        let maxActual = max([p1H, p2H].compactMap { $0 }.max() ?? 180, 1.0)
        let minH = maxBarH * 0.15

        p1BarHC?.update(offset:   max(minH, CGFloat((p1H   ?? maxActual) / maxActual) * maxBarH))
        babyBarHC?.update(offset: max(minH, CGFloat((babyH ?? maxActual * 0.35) / maxActual) * maxBarH))
        p2BarHC?.update(offset:   max(minH, CGFloat((p2H   ?? maxActual) / maxActual) * maxBarH))

        p1NameLbl.text   = p1Name
        p2NameLbl.text   = p2Name
        babyNameLbl.text = "Baby"

        let hFmt: (Double) -> String = isMetric ? { "\(Int($0)) cm" } : { Self.cmToFt($0) }
        p1HLbl.text   = p1H.map   { hFmt($0) } ?? "–"
        p2HLbl.text   = p2H.map   { hFmt($0) } ?? "–"
        babyHLbl.text = babyH.map { isMetric ? String(format: "%.1f cm", $0) : Self.cmToFt($0) } ?? "–"

        hChip.isHidden  = true
        wChip.isHidden  = true
        hcChip.isHidden = true

        setNeedsLayout(); layoutIfNeeded()
    }

    private static func cmToFt(_ cm: Double) -> String {
        let totalIn = cm / 2.54; let ft = Int(totalIn / 12)
        let inches = Int(totalIn.truncatingRemainder(dividingBy: 12))
        return "\(ft)'\(inches)\""
    }
}

// MARK: - GrowthChip

final class GrowthChip: UILabel {
    override var text: String? {
        didSet {
            isHidden = text == nil
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 9 * Constraint.yCoeff, weight: .medium)
        textColor = UIColor(hexString: "#444444")
        backgroundColor = UIColor.white.withAlphaComponent(0.85)
        layer.cornerRadius = 6 * Constraint.yCoeff
        clipsToBounds = true
        textAlignment = .center
        isHidden = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - GrowthInputRow

final class GrowthInputRow: UIView {

    let textField = UITextField()
    let unitLabel = UILabel()
    private let nameLbl = UILabel()

    func setLabelText(_ text: String) { nameLbl.text = text }

    init(labelText: String, unit: String) {
        super.init(frame: .zero)

        nameLbl.text = labelText
        nameLbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        nameLbl.textColor = UIColor(hexString: "#888888")

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 14 * Constraint.yCoeff

        textField.font = .systemFont(ofSize: 22 * Constraint.yCoeff, weight: .semibold)
        textField.textColor = UIColor(hexString: "#1a1a2e")
        textField.keyboardType = .decimalPad
        textField.borderStyle = .none
        textField.placeholder = "–"

        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        unitLabel.textColor = UIColor(hexString: "#888888")

        addSubview(nameLbl)
        addSubview(container)
        container.addSubview(textField)
        container.addSubview(unitLabel)

        nameLbl.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        container.snp.makeConstraints {
            $0.top.equalTo(nameLbl.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(54 * Constraint.yCoeff)
        }
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(unitLabel.snp.leading).offset(-8)
        }
        unitLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - GrowthDateRow

final class GrowthDateRow: UIView {

    var onDateChanged: ((Date) -> Void)?

    private let container  = UIView()
    private let textField  = UITextField()
    private let calIcon    = UIImageView()
    private let datePicker = UIDatePicker()
    private let df: DateFormatter = { let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"; return f }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let nameLbl = UILabel()
        nameLbl.text = "Measurement date"
        nameLbl.font = .systemFont(ofSize: 13 * Constraint.yCoeff, weight: .regular)
        nameLbl.textColor = UIColor(hexString: "#888888")

        container.backgroundColor = .white
        container.layer.cornerRadius = 14 * Constraint.yCoeff

        textField.font = .systemFont(ofSize: 18 * Constraint.yCoeff, weight: .semibold)
        textField.textColor = UIColor(hexString: "#1a1a2e")
        textField.placeholder = "DD/MM/YYYY"
        textField.borderStyle = .none

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        textField.inputView = datePicker

        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicking))
        toolbar.setItems([.flexibleSpace(), done], animated: false)
        textField.inputAccessoryView = toolbar

        calIcon.image = UIImage(systemName: "calendar")
        calIcon.tintColor = UIColor(hexString: "#8b6dc4")
        calIcon.contentMode = .scaleAspectFit

        addSubview(nameLbl)
        addSubview(container)
        container.addSubview(textField)
        container.addSubview(calIcon)

        nameLbl.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        container.snp.makeConstraints {
            $0.top.equalTo(nameLbl.snp.bottom).offset(4 * Constraint.yCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(54 * Constraint.yCoeff)
        }
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(calIcon.snp.leading).offset(-8)
        }
        calIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(22 * Constraint.yCoeff)
        }
    }

    @objc private func dateChanged() {
        textField.text = df.string(from: datePicker.date)
        onDateChanged?(datePicker.date)
    }
    @objc private func donePicking() { textField.resignFirstResponder() }
}

// GrowthHistoryViewController is defined in GrowthHistoryViewController.swift

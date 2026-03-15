import UIKit
import SnapKit

/// Skin tone options for parent avatars (visual round color circles).
enum GrowthSkinTone {
    static let colors: [UIColor] = [
        UIColor(hexString: "#FFE0BD"),
        UIColor(hexString: "#F1C27D"),
        UIColor(hexString: "#E0AC69"),
        UIColor(hexString: "#C68642"),
        UIColor(hexString: "#8D5524"),
        UIColor(hexString: "#5C3317"),
    ]
}

/// Preset parent label pairs.
enum GrowthParentPreset: String, CaseIterable {
    case motherFather = "Mother + Father"
    case fatherFather = "Father + Father"
    case motherMother = "Mother + Mother"

    var parent1Label: String {
        switch self {
        case .motherFather, .motherMother: return "Mother"
        case .fatherFather: return "Father"
        }
    }

    var parent2Label: String {
        switch self {
        case .motherFather, .fatherFather: return "Father"
        case .motherMother: return "Mother"
        }
    }
}

final class GrowthComparisonView: UIView {

    var onValuesChanged: (() -> Void)?

    var parent1Height: Double? {
        Double(parent1HeightField.text?.replacingOccurrences(of: ",", with: ".") ?? "")
    }
    var parent2Height: Double? {
        Double(parent2HeightField.text?.replacingOccurrences(of: ",", with: ".") ?? "")
    }
    var babyHeight: Double? {
        Double(babyHeightField.text?.replacingOccurrences(of: ",", with: ".") ?? "")
    }
    var parent1LabelText: String { parent1LabelField.text ?? "" }
    var parent2LabelText: String { parent2LabelField.text ?? "" }
    var parent1SkinToneIndex: Int = 0 { didSet { updateParent1Avatar(); onValuesChanged?() } }
    var parent2SkinToneIndex: Int = 0 { didSet { updateParent2Avatar(); onValuesChanged?() } }

    private let chartHeight: CGFloat = 220

    // MARK: - Parent preset
    private lazy var presetLabel: UILabel = {
        let v = UILabel()
        v.text = "Parents"
        v.font = .systemFont(ofSize: 15, weight: .semibold)
        v.textColor = .buttonTitleColor
        return v
    }()

    private lazy var presetStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 10
        v.distribution = .fillEqually
        return v
    }()

    // MARK: - Parent 1
    private lazy var parent1Container: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private lazy var parent1AvatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()

    private lazy var parent1Icon: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "person.fill"))
        v.tintColor = .white
        v.contentMode = .scaleAspectFit
        return v
    }()

    private lazy var parent1LabelField: UITextField = {
        let v = UITextField()
        v.placeholder = "Parent 1"
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textColor = .buttonTitleColor
        v.borderStyle = .roundedRect
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.delegate = self
        return v
    }()

    private lazy var parent1HeightField: UITextField = {
        let v = UITextField()
        v.placeholder = "Height (cm)"
        v.keyboardType = .decimalPad
        v.font = .systemFont(ofSize: 15, weight: .medium)
        v.textColor = .buttonTitleColor
        v.borderStyle = .roundedRect
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return v
    }()

    private lazy var parent1SkinStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 8
        return v
    }()

    // MARK: - Parent 2
    private lazy var parent2Container: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private lazy var parent2AvatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()

    private lazy var parent2Icon: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "person.fill"))
        v.tintColor = .white
        v.contentMode = .scaleAspectFit
        return v
    }()

    private lazy var parent2LabelField: UITextField = {
        let v = UITextField()
        v.placeholder = "Parent 2"
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textColor = .buttonTitleColor
        v.borderStyle = .roundedRect
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.delegate = self
        return v
    }()

    private lazy var parent2HeightField: UITextField = {
        let v = UITextField()
        v.placeholder = "Height (cm)"
        v.keyboardType = .decimalPad
        v.font = .systemFont(ofSize: 15, weight: .medium)
        v.textColor = .buttonTitleColor
        v.borderStyle = .roundedRect
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return v
    }()

    private lazy var parent2SkinStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 8
        return v
    }()

    // MARK: - Baby
    private lazy var babySectionLabel: UILabel = {
        let v = UILabel()
        v.text = "Baby's height"
        v.font = .systemFont(ofSize: 15, weight: .semibold)
        v.textColor = .buttonTitleColor
        return v
    }()

    private lazy var babyHeightField: UITextField = {
        let v = UITextField()
        v.placeholder = "Height (cm)"
        v.keyboardType = .decimalPad
        v.font = .systemFont(ofSize: 16, weight: .medium)
        v.textColor = .buttonTitleColor
        v.borderStyle = .roundedRect
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        return v
    }()

    // MARK: - Height comparison chart
    private lazy var chartContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private lazy var chartTitleLabel: UILabel = {
        let v = UILabel()
        v.text = "Height comparison"
        v.font = .systemFont(ofSize: 16, weight: .semibold)
        v.textColor = .buttonTitleColor
        return v
    }()

    private lazy var chartAvatarsStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.spacing = 16
        return v
    }()

    private var babyAvatarColumn: GrowthAvatarColumnView?
    private var parent1AvatarColumn: GrowthAvatarColumnView?
    private var parent2AvatarColumn: GrowthAvatarColumnView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .viewsBackGourdColor
        setupPresetButtons()
        setupSkinTonePickers()
        setupUI()
        setupConstraints()
        updateParent1Avatar()
        updateParent2Avatar()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupPresetButtons() {
        for preset in GrowthParentPreset.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(preset.rawValue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            btn.setTitleColor(.buttonTitleColor, for: .normal)
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 10
            btn.tag = preset == .motherFather ? 0 : (preset == .fatherFather ? 1 : 2)
            btn.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
            presetStack.addArrangedSubview(btn)
        }
    }

    private func setupSkinTonePickers() {
        for (idx, color) in GrowthSkinTone.colors.enumerated() {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = color
            btn.tag = idx
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.clear.cgColor
            btn.addTarget(self, action: #selector(skinTone1Tapped(_:)), for: .touchUpInside)
            parent1SkinStack.addArrangedSubview(btn)
        }
        for (idx, color) in GrowthSkinTone.colors.enumerated() {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = color
            btn.tag = idx
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.clear.cgColor
            btn.addTarget(self, action: #selector(skinTone2Tapped(_:)), for: .touchUpInside)
            parent2SkinStack.addArrangedSubview(btn)
        }
    }

    private func setupUI() {
        addSubview(presetLabel)
        addSubview(presetStack)
        addSubview(parent1Container)
        parent1Container.addSubview(parent1AvatarView)
        parent1AvatarView.addSubview(parent1Icon)
        parent1Container.addSubview(parent1LabelField)
        parent1Container.addSubview(parent1HeightField)
        parent1Container.addSubview(parent1SkinStack)
        addSubview(parent2Container)
        parent2Container.addSubview(parent2AvatarView)
        parent2AvatarView.addSubview(parent2Icon)
        parent2Container.addSubview(parent2LabelField)
        parent2Container.addSubview(parent2HeightField)
        parent2Container.addSubview(parent2SkinStack)
        addSubview(babySectionLabel)
        addSubview(babyHeightField)
        addSubview(chartContainer)
        chartContainer.addSubview(chartTitleLabel)
        chartContainer.addSubview(chartAvatarsStack)

        let babyCol = GrowthAvatarColumnView()
        babyCol.configure(label: "Baby", avatarColor: .growthViewColor, isBaby: true)
        let p1Col = GrowthAvatarColumnView()
        p1Col.configure(label: "Parent 1", avatarColor: UIColor(hexString: "#e8b5f5"), isBaby: false)
        let p2Col = GrowthAvatarColumnView()
        p2Col.configure(label: "Parent 2", avatarColor: UIColor(hexString: "#bdf0c2"), isBaby: false)
        babyAvatarColumn = babyCol
        parent1AvatarColumn = p1Col
        parent2AvatarColumn = p2Col
        chartAvatarsStack.addArrangedSubview(babyCol)
        chartAvatarsStack.addArrangedSubview(p1Col)
        chartAvatarsStack.addArrangedSubview(p2Col)
    }

    private func setupConstraints() {
        presetLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
        }
        presetStack.snp.makeConstraints { make in
            make.top.equalTo(presetLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }

        parent1Container.snp.makeConstraints { make in
            make.top.equalTo(presetStack.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
        }
        parent1AvatarView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.size.equalTo(56)
        }
        parent1Icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        parent1LabelField.snp.makeConstraints { make in
            make.leading.equalTo(parent1AvatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(parent1AvatarView)
            make.height.equalTo(36)
        }
        parent1HeightField.snp.makeConstraints { make in
            make.top.equalTo(parent1AvatarView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        parent1SkinStack.snp.makeConstraints { make in
            make.top.equalTo(parent1HeightField.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        for v in parent1SkinStack.arrangedSubviews {
            v.snp.makeConstraints { make in
                make.width.equalTo(24)
            }
        }

        parent2Container.snp.makeConstraints { make in
            make.top.equalTo(parent1Container.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }
        parent2AvatarView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.size.equalTo(56)
        }
        parent2Icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        parent2LabelField.snp.makeConstraints { make in
            make.leading.equalTo(parent2AvatarView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(parent2AvatarView)
            make.height.equalTo(36)
        }
        parent2HeightField.snp.makeConstraints { make in
            make.top.equalTo(parent2AvatarView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        parent2SkinStack.snp.makeConstraints { make in
            make.top.equalTo(parent2HeightField.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        for v in parent2SkinStack.arrangedSubviews {
            v.snp.makeConstraints { make in
                make.width.equalTo(24)
            }
        }

        babySectionLabel.snp.makeConstraints { make in
            make.top.equalTo(parent2Container.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        babyHeightField.snp.makeConstraints { make in
            make.top.equalTo(babySectionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        chartContainer.snp.makeConstraints { make in
            make.top.equalTo(babyHeightField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
        }
        chartTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        chartAvatarsStack.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(chartHeight)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func updateParent1Avatar() {
        let idx = max(0, min(parent1SkinToneIndex, GrowthSkinTone.colors.count - 1))
        parent1AvatarView.backgroundColor = GrowthSkinTone.colors[idx]
        for (i, sub) in parent1SkinStack.arrangedSubviews.enumerated() {
            (sub as? UIButton)?.layer.borderColor = (i == parent1SkinToneIndex ? UIColor.growthViewColor.cgColor : UIColor.clear.cgColor)
        }
    }

    private func updateParent2Avatar() {
        let idx = max(0, min(parent2SkinToneIndex, GrowthSkinTone.colors.count - 1))
        parent2AvatarView.backgroundColor = GrowthSkinTone.colors[idx]
        for (i, sub) in parent2SkinStack.arrangedSubviews.enumerated() {
            (sub as? UIButton)?.layer.borderColor = (i == parent2SkinToneIndex ? UIColor.growthViewColor.cgColor : UIColor.clear.cgColor)
        }
    }

    @objc private func presetTapped(_ sender: UIButton) {
        let preset: GrowthParentPreset
        switch sender.tag {
        case 0: preset = .motherFather
        case 1: preset = .fatherFather
        default: preset = .motherMother
        }
        parent1LabelField.text = preset.parent1Label
        parent2LabelField.text = preset.parent2Label
        fieldChanged()
    }

    @objc private func skinTone1Tapped(_ sender: UIButton) {
        parent1SkinToneIndex = sender.tag
    }

    @objc private func skinTone2Tapped(_ sender: UIButton) {
        parent2SkinToneIndex = sender.tag
    }

    @objc private func fieldChanged() {
        updateChart()
        onValuesChanged?()
    }

    private func updateChart() {
        let p1 = parent1Height ?? 0
        let p2 = parent2Height ?? 0
        let baby = babyHeight ?? 0
        let maxH = max(p1, p2, baby, 1)
        parent1AvatarColumn?.setHeight(p1, maxHeight: maxH)
        parent2AvatarColumn?.setHeight(p2, maxHeight: maxH)
        babyAvatarColumn?.setHeight(baby, maxHeight: maxH)
        parent1AvatarColumn?.updateLabel(parent1LabelText.isEmpty ? "Parent 1" : parent1LabelText)
        parent2AvatarColumn?.updateLabel(parent2LabelText.isEmpty ? "Parent 2" : parent2LabelText)
        let skin1 = GrowthSkinTone.colors[max(0, min(parent1SkinToneIndex, GrowthSkinTone.colors.count - 1))]
        let skin2 = GrowthSkinTone.colors[max(0, min(parent2SkinToneIndex, GrowthSkinTone.colors.count - 1))]
        parent1AvatarColumn?.updateAvatarColor(skin1)
        parent2AvatarColumn?.updateAvatarColor(skin2)
    }

    // MARK: - Public API
    func configure(
        parent1Height: Double?,
        parent2Height: Double?,
        babyHeight: Double?,
        parent1Label: String?,
        parent2Label: String?,
        parent1SkinIndex: Int,
        parent2SkinIndex: Int
    ) {
        if let v = parent1Height, v > 0 { parent1HeightField.text = "\(v)" }
        if let v = parent2Height, v > 0 { parent2HeightField.text = "\(v)" }
        if let v = babyHeight, v > 0 { babyHeightField.text = "\(v)" }
        parent1LabelField.text = parent1Label
        parent2LabelField.text = parent2Label
        parent1SkinToneIndex = parent1SkinIndex
        parent2SkinToneIndex = parent2SkinIndex
        updateChart()
    }

    func updateChartFromValues() {
        updateChart()
    }
}

extension GrowthComparisonView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        onValuesChanged?()
    }
}

// MARK: - Avatar column for height comparison (avatar positioned at height on scale)
final class GrowthAvatarColumnView: UIView {
    private let scaleHeight: CGFloat = 160
    private var avatarBottomConstraint: SnapKit.Constraint?
    private let scaleContainer = UIView()
    private let avatarView = UIView()
    private let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
    private let labelLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        scaleContainer.backgroundColor = UIColor(white: 0.96, alpha: 1)
        scaleContainer.layer.cornerRadius = 12
        avatarView.layer.cornerRadius = 24
        avatarView.clipsToBounds = true
        avatarIcon.tintColor = .white
        avatarIcon.contentMode = .scaleAspectFit
        labelLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        labelLabel.textColor = .buttonTitleColor
        labelLabel.textAlignment = .center
        valueLabel.font = .systemFont(ofSize: 11, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .center

        addSubview(scaleContainer)
        scaleContainer.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        addSubview(valueLabel)
        addSubview(labelLabel)

        scaleContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(scaleHeight)
        }
        avatarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(48)
            self.avatarBottomConstraint = make.bottom.equalTo(scaleContainer.snp.bottom).offset(0).constraint
        }
        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(scaleContainer.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        labelLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(label: String, avatarColor: UIColor, isBaby: Bool = false) {
        labelLabel.text = label
        avatarView.backgroundColor = avatarColor
        avatarIcon.image = UIImage(systemName: isBaby ? "figure.child" : "person.fill")
    }

    func updateAvatarColor(_ color: UIColor) {
        avatarView.backgroundColor = color
    }

    func updateLabel(_ text: String) {
        labelLabel.text = text
    }

    func setHeight(_ value: Double, maxHeight: Double) {
        let ratio = maxHeight > 0 && value > 0 ? (value / maxHeight) : 0
        let offsetFromBottom = CGFloat(ratio) * scaleHeight
        avatarBottomConstraint?.update(offset: offsetFromBottom)
        valueLabel.text = value > 0 ? "\(Int(value)) cm" : "—"
    }
}

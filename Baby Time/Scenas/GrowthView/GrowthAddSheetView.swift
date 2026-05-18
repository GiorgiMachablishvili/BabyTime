import UIKit
import SnapKit

final class GrowthAddSheetView: UIView {

    var onSave: ((Double, Int?, Date) -> Void)?
    var onClose: (() -> Void)?
    var measurementType: String = "weight"

    private let accent = UIColor(hexString: "#6557e8")

    private lazy var blurView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return v
    }()

    private lazy var sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .label
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        b.tintColor = .secondaryLabel
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()

    private lazy var valueLabel = makeFieldLabel("Value")

    private lazy var valueTextField: UITextField = {
        let tf = makeTextField()
        tf.placeholder = "e.g. 6.4"
        tf.keyboardType = .decimalPad
        return tf
    }()

    private lazy var unitSuffixLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var percentileLabel = makeFieldLabel("Percentile (optional)")

    private lazy var percentileTextField: UITextField = {
        let tf = makeTextField()
        tf.placeholder = "e.g. 62"
        tf.keyboardType = .numberPad
        return tf
    }()

    private lazy var dateLabel = makeFieldLabel("Date")

    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.maximumDate = Date()
        dp.tintColor = accent
        return dp
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.layer.cornerRadius = 14
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        blurView.addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(type: String) {
        measurementType = type
        switch type {
        case "weight":
            titleLabel.text = "Add Weight"
            unitSuffixLabel.text = "kg"
        case "height":
            titleLabel.text = "Add Height"
            unitSuffixLabel.text = "cm"
        case "head":
            titleLabel.text = "Add Head Circumference"
            unitSuffixLabel.text = "cm"
        default: break
        }
        saveButton.backgroundColor = accent
        valueTextField.text = ""
        percentileTextField.text = ""
        datePicker.date = Date()
    }

    private func setupUI() {
        addSubview(blurView)
        addSubview(sheetView)
        sheetView.addSubview(titleLabel)
        sheetView.addSubview(closeButton)
        sheetView.addSubview(valueLabel)
        sheetView.addSubview(valueTextField)
        sheetView.addSubview(unitSuffixLabel)
        sheetView.addSubview(percentileLabel)
        sheetView.addSubview(percentileTextField)
        sheetView.addSubview(dateLabel)
        sheetView.addSubview(datePicker)
        sheetView.addSubview(saveButton)
    }

    private func setupConstraints() {
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheetView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(420 * Constraint.xCoeff)
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalTo(sheetView).inset(20 * Constraint.xCoeff)
        }
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalTo(sheetView).inset(16 * Constraint.xCoeff)
            $0.width.height.equalTo(32 * Constraint.yCoeff)
        }
        valueLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.equalTo(sheetView).offset(20 * Constraint.xCoeff)
        }
        valueTextField.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.equalTo(sheetView).offset(20 * Constraint.xCoeff)
            $0.trailing.equalTo(unitSuffixLabel.snp.leading).offset(-8 * Constraint.xCoeff)
            $0.height.equalTo(46 * Constraint.yCoeff)
        }
        unitSuffixLabel.snp.makeConstraints {
            $0.centerY.equalTo(valueTextField)
            $0.trailing.equalTo(sheetView).inset(20 * Constraint.xCoeff)
            $0.width.equalTo(32 * Constraint.xCoeff)
        }
        percentileLabel.snp.makeConstraints {
            $0.top.equalTo(valueTextField.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.equalTo(sheetView).offset(20 * Constraint.xCoeff)
        }
        percentileTextField.snp.makeConstraints {
            $0.top.equalTo(percentileLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.trailing.equalTo(sheetView).inset(20 * Constraint.xCoeff)
            $0.height.equalTo(46 * Constraint.yCoeff)
        }
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(percentileTextField.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.equalTo(sheetView).offset(20 * Constraint.xCoeff)
        }
        datePicker.snp.makeConstraints {
            $0.centerY.equalTo(dateLabel)
            $0.trailing.equalTo(sheetView).inset(20 * Constraint.xCoeff)
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(24 * Constraint.xCoeff)
            $0.leading.trailing.equalTo(sheetView).inset(20 * Constraint.xCoeff)
            $0.height.equalTo(52 * Constraint.yCoeff)
        }
    }

    @objc private func saveTapped() {
        guard let text = valueTextField.text, let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            valueTextField.layer.borderWidth = 1
            valueTextField.layer.borderColor = UIColor.systemRed.cgColor
            valueTextField.layer.cornerRadius = 10
            return
        }
        let percentile = Int(percentileTextField.text ?? "")
        onSave?(value, percentile, datePicker.date)
    }

    @objc private func closeTapped() { onClose?() }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeTextField() -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tf.layer.cornerRadius = 10
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        tf.leftViewMode = .always
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .label
        return tf
    }
}

import UIKit
import SnapKit

class TimeButtonView: UIView {

    private let selectedColor = UIColor.pressButtonColor
    private let normalColor = UIColor.buttonGayColor

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .black
        view.textAlignment = .center
        view.text = "Duration (minutes)"
        return view
    }()

    private lazy var fiveMinutesButton: TimePillView = {
        let view = TimePillView()
        view.timeLabel.text = "5 min"
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var tenMinutesButton: TimePillView = {
        let view = TimePillView()
        view.timeLabel.text = "10 min"
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var fifteenMinutesButton: TimePillView = {
        let view = TimePillView()
        view.timeLabel.text = "15 min"
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var twentyMinutesButton: TimePillView = {
        let view = TimePillView()
        view.timeLabel.text = "20 min"
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var thirtyMinutesButton: TimePillView = {
        let view = TimePillView()
        view.timeLabel.text = "30 min"
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()



    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupConstraint()
        applySelection(selected: fiveMinutesButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(fiveMinutesButton)
        addSubview(tenMinutesButton)
        addSubview(fifteenMinutesButton)
        addSubview(twentyMinutesButton)
        addSubview(thirtyMinutesButton)
        [fiveMinutesButton, tenMinutesButton, fifteenMinutesButton, twentyMinutesButton, thirtyMinutesButton].forEach { $0.backgroundColor = normalColor }
    }

    private func setupConstraint() {
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(snp.top).offset(20 * Constraint.xCoeff)
            make.leading.equalToSuperview()
        }

        fiveMinutesButton.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.equalTo(snp.leading).offset(10 * Constraint.yCoeff)
            make.height.equalTo(40 * Constraint.yCoeff)
            make.width.equalTo(60 * Constraint.yCoeff)
        }

        tenMinutesButton.snp.remakeConstraints { make in
            make.top.equalTo(fiveMinutesButton.snp.top)
            make.leading.equalTo(fiveMinutesButton.snp.trailing).offset(5 * Constraint.yCoeff)
            make.height.equalTo(40 * Constraint.yCoeff)
            make.width.equalTo(60 * Constraint.yCoeff)
        }

        fifteenMinutesButton.snp.remakeConstraints { make in
            make.top.equalTo(fiveMinutesButton.snp.top)
            make.leading.equalTo(tenMinutesButton.snp.trailing).offset(5 * Constraint.yCoeff)
            make.height.equalTo(40 * Constraint.yCoeff)
            make.width.equalTo(60 * Constraint.yCoeff)
        }

        twentyMinutesButton.snp.remakeConstraints { make in
            make.top.equalTo(fiveMinutesButton.snp.top)
            make.leading.equalTo(fifteenMinutesButton.snp.trailing).offset(5 * Constraint.yCoeff)
            make.height.equalTo(40 * Constraint.yCoeff)
            make.width.equalTo(60 * Constraint.yCoeff)
        }

        thirtyMinutesButton.snp.remakeConstraints { make in
            make.top.equalTo(fiveMinutesButton.snp.top)
            make.leading.equalTo(twentyMinutesButton.snp.trailing).offset(5 * Constraint.yCoeff)
            make.height.equalTo(40 * Constraint.yCoeff)
            make.width.equalTo(60 * Constraint.yCoeff)
        }
    }

    private func applySelection(selected: UIView) {
        let buttons = [fiveMinutesButton, tenMinutesButton, fifteenMinutesButton, twentyMinutesButton, thirtyMinutesButton]
        buttons.forEach { button in
            let isSelected = (button === selected)
            button.backgroundColor = isSelected ? selectedColor : normalColor
            button.timeLabel.textColor = isSelected ? UIColor.labelWhiteColor : UIColor.pressButtonTitleColor
        }
    }

    @objc private func handlePillTap(_ gesture: UITapGestureRecognizer) {
        guard let tapped = gesture.view else { return }
        applySelection(selected: tapped)
        switch tapped {
        case fiveMinutesButton:
            fiveMinutesButtonTapped(fiveMinutesButton)
        case tenMinutesButton:
            tenMinutesButtonTapped(tenMinutesButton)
        case fifteenMinutesButton:
            fifteenMinutesButtonTapped(fifteenMinutesButton)
        case twentyMinutesButton:
            twentyMinutesButtonTapped(twentyMinutesButton)
        case thirtyMinutesButton:
            thirtyMinutesButtonTapped(thirtyMinutesButton)
        default:
            break
        }
    }

    @objc private func fiveMinutesButtonTapped(_ sender: UIView) {
        applySelection(selected: fiveMinutesButton)
    }

    @objc private func tenMinutesButtonTapped(_ sender: UIView) {
        applySelection(selected: tenMinutesButton)
    }

    @objc private func fifteenMinutesButtonTapped(_ sender: UIView) {
        applySelection(selected: fifteenMinutesButton)
    }

    @objc private func twentyMinutesButtonTapped(_ sender: UIView) {
        applySelection(selected: twentyMinutesButton)
    }

    @objc private func thirtyMinutesButtonTapped(_ sender: UIView) {
        applySelection(selected: thirtyMinutesButton)
    }



}

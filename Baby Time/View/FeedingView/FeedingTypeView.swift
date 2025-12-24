import UIKit
import SnapKit

class FeedingTypeView: UIView {

    private let selectedColor = UIColor.pressButtonColor
    private let normalColor = UIColor.buttonGayColor

    private lazy var typeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Type"
        view.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var breastButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = selectedColor
        view.iconImageView.image = UIImage(systemName: "figure.seated.side.right.child.lap")?.withRenderingMode(.alwaysTemplate)
        view.iconImageView.tintColor = UIColor.labelWhiteColor
        view.titleLabel.text = "Breast"
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(breastTapped)))
        return view
    }()

    private lazy var bottleButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = normalColor
        view.iconImageView.image = UIImage(systemName: "waterbottle")?.withRenderingMode(.alwaysTemplate)
        view.iconImageView.tintColor = UIColor.pressButtonTitleColor
        view.titleLabel.text = "Bottle"
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bottleTapped)))
        return view
    }()

    private lazy var formulaButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = normalColor
        view.iconImageView.image = UIImage(systemName: "flask")?.withRenderingMode(.alwaysTemplate)
        view.iconImageView.tintColor = UIColor.pressButtonTitleColor
        view.titleLabel.text = "Formula"
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(formulaTapped)))
        return view
    }()

    private lazy var solidButton: ActionCardButton = {
        let view = ActionCardButton()
        view.backgroundColor = normalColor
        view.iconImageView.image = UIImage(systemName: "carrot")?.withRenderingMode(.alwaysTemplate)
        view.iconImageView.tintColor = UIColor.pressButtonTitleColor
        view.titleLabel.text = "Solid"
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(solidTapped)))
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        applySelection(selected: breastButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(typeLabel)
        addSubview(breastButton)
        addSubview(bottleButton)
        addSubview(formulaButton)
        addSubview(solidButton)
    }

    private func setupConstraints() {
        typeLabel.snp.remakeConstraints { make in
            make.top.equalTo(snp.top).offset(20 * Constraint.xCoeff)
            make.leading.equalTo(snp.leading).offset(10 * Constraint.xCoeff)
        }

        breastButton.snp.remakeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(20 * Constraint.xCoeff)
            make.leading.equalTo(snp.leading).offset(10 * Constraint.xCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
            make.width.equalTo(90 * Constraint.xCoeff)
        }

        bottleButton.snp.remakeConstraints { make in
            make.top.equalTo(breastButton.snp.top)
            make.leading.equalTo(breastButton.snp.trailing).offset(4 * Constraint.xCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
            make.width.equalTo(90 * Constraint.xCoeff)
        }

        formulaButton.snp.remakeConstraints { make in
            make.top.equalTo(breastButton.snp.top)
            make.leading.equalTo(bottleButton.snp.trailing).offset(4 * Constraint.xCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
            make.width.equalTo(90 * Constraint.xCoeff)
        }

        solidButton.snp.remakeConstraints { make in
            make.top.equalTo(breastButton.snp.top)
            make.trailing.equalTo(snp.trailing).offset(-10 * Constraint.xCoeff)
            make.height.equalTo(70 * Constraint.xCoeff)
            make.width.equalTo(90 * Constraint.xCoeff)
        }
    }

    // MARK: - Selection Handling
    private func applySelection(selected: ActionCardButton) {
        let buttons = [breastButton, bottleButton, formulaButton, solidButton]
        buttons.forEach { button in
            let isSelected = (button === selected)
            button.backgroundColor = isSelected ? selectedColor : normalColor
            button.titleLabel.textColor = isSelected ? UIColor.labelWhiteColor : UIColor.pressButtonTitleColor
            button.iconImageView.tintColor = isSelected ? UIColor.labelWhiteColor : UIColor.pressButtonTitleColor
        }
    }

    @objc private func breastTapped() {
        applySelection(selected: breastButton)
    }

    @objc private func bottleTapped() {
        applySelection(selected: bottleButton)
    }

    @objc private func formulaTapped() {
        applySelection(selected: formulaButton)
    }

    @objc private func solidTapped() {
        applySelection(selected: solidButton)
    }
}

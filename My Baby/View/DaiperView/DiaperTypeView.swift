

import UIKit
import SnapKit

final class DiaperTypeView: UIView {

    enum DiaperType: CaseIterable {
        case wet, dirty, mixed

        var title: String {
            switch self {
            case .wet: return "Wet"
            case .dirty: return "Dirty"
            case .mixed: return "Mixed"
            }
        }

        // Emoji like the screenshot
        var iconText: String {
            switch self {
            case .wet: return "💧"
            case .dirty: return "💩"
            case .mixed: return "💧💩"
            }
        }
    }

    // MARK: - Public

    var selectedType: DiaperType = .wet {
        didSet { updateSelectionUI() }
    }

    var onTypeChanged: ((DiaperType) -> Void)?

    // MARK: - UI

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.text = "Type"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let wetButton = TypeCardButton()
    private let dirtyButton = TypeCardButton()
    private let mixedButton = TypeCardButton()

    private lazy var buttonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [wetButton, dirtyButton, mixedButton])
        stack.axis = .horizontal
        stack.spacing = 14
        stack.distribution = .fillEqually
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupButtons()
        updateSelectionUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(typeLabel)
        addSubview(buttonsStack)
    }

    private func setupConstraints() {
        typeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        buttonsStack.snp.makeConstraints {
            $0.top.equalTo(typeLabel.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(120 * Constraint.xCoeff)
        }
    }

    private func setupButtons() {
        wetButton.configure(icon: DiaperType.wet.iconText, title: DiaperType.wet.title)
        dirtyButton.configure(icon: DiaperType.dirty.iconText, title: DiaperType.dirty.title)
        mixedButton.configure(icon: DiaperType.mixed.iconText, title: DiaperType.mixed.title)

        wetButton.onTap = { [weak self] in self?.select(.wet) }
        dirtyButton.onTap = { [weak self] in self?.select(.dirty) }
        mixedButton.onTap = { [weak self] in self?.select(.mixed) }
    }

    private func select(_ type: DiaperType) {
        selectedType = type
        onTypeChanged?(type)
    }

    private func updateSelectionUI() {
        wetButton.setSelected(selectedType == .wet)
        dirtyButton.setSelected(selectedType == .dirty)
        mixedButton.setSelected(selectedType == .mixed)
    }
}


// MARK: - Private Card Button

private final class TypeCardButton: UIControl {

    var onTap: (() -> Void)?

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .regular)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.label.withAlphaComponent(0.65)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 18
        clipsToBounds = true

        addSubview(iconLabel)
        addSubview(titleLabel)

        iconLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-12 * Constraint.yCoeff)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.centerX.equalToSuperview()
        }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    func configure(icon: String, title: String) {
        iconLabel.text = icon
        titleLabel.text = title
    }

    func setSelected(_ selected: Bool) {
        if selected {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
        } else {
            backgroundColor = UIColor.systemGray6
        }
    }

    @objc private func tapped() {
        onTap?()
    }
}

import UIKit
import SnapKit

class DiaperView: UIView {

    var onTapCloseButton: (() -> Void)?
    var onTapSave: ((DiaperType, String?) -> Void)?
    private(set) var selectedDiaperType: DiaperTypeView.DiaperType = .wet
    private var sheetHeightConstraint: SnapKit.Constraint?
    private var notesTopToPickerConstraint: SnapKit.Constraint?
    private var notesTopToTitleConstraint: SnapKit.Constraint?

    // MARK: - Subviews

    private lazy var blurEffectView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray.withAlphaComponent(0.9)
        return view
    }()

    private lazy var sheetView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Log Diaper"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .label
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        b.tintColor = .label
        b.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return b
    }()

    // Type picker (shown when FAB opens sheet)
    private lazy var diaperTypeView: DiaperTypeView = {
        let view = DiaperTypeView()
        return view
    }()

    // Badge (shown when quick-log button opens sheet)
    private lazy var typeBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18 * Constraint.yCoeff
        v.clipsToBounds = true
        v.isHidden = true
        return v
    }()

    private lazy var typeBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private lazy var notesView: NotesOptionalView = {
        let view = NotesOptionalView()
        return view
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton()
        b.makeRoundCorners(12)
        b.setTitle("Save", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.labelWhiteColor, for: .normal)
        b.backgroundColor = .pressButtonColor
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupUI()
        setupConstraints()
        diaperTypeView.onTypeChanged = { [weak self] type in
            self?.selectedDiaperType = type
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        addSubview(blurEffectView)
        addSubview(sheetView)
        sheetView.addSubview(titleLabel)
        sheetView.addSubview(closeButton)
        sheetView.addSubview(diaperTypeView)
        sheetView.addSubview(typeBadge)
        typeBadge.addSubview(typeBadgeLabel)
        sheetView.addSubview(notesView)
        sheetView.addSubview(saveButton)
    }

    private func setupConstraints() {
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }

        sheetView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            sheetHeightConstraint = $0.height.equalTo(480 * Constraint.xCoeff).constraint
        }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalTo(sheetView).inset(10 * Constraint.xCoeff)
        }
        closeButton.snp.makeConstraints {
            $0.top.equalTo(sheetView).offset(10 * Constraint.xCoeff)
            $0.trailing.equalTo(sheetView).inset(10 * Constraint.xCoeff)
            $0.width.height.equalTo(44 * Constraint.xCoeff)
        }
        diaperTypeView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalTo(sheetView).inset(16 * Constraint.xCoeff)
        }
        typeBadge.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.centerX.equalTo(sheetView)
            $0.height.equalTo(36 * Constraint.yCoeff)
        }
        typeBadgeLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20 * Constraint.xCoeff)
        }
        notesView.snp.makeConstraints {
            notesTopToPickerConstraint = $0.top.equalTo(diaperTypeView.snp.bottom).offset(20 * Constraint.xCoeff).constraint
            notesTopToTitleConstraint  = $0.top.equalTo(titleLabel.snp.bottom).offset(45 * Constraint.xCoeff).constraint
            $0.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            $0.height.equalTo(140 * Constraint.xCoeff)
        }
        notesTopToTitleConstraint?.deactivate()
        saveButton.snp.makeConstraints {
            $0.top.equalTo(notesView.snp.bottom).offset(20 * Constraint.yCoeff)
            $0.leading.trailing.equalToSuperview().inset(30 * Constraint.yCoeff)
            $0.height.equalTo(50 * Constraint.xCoeff)
        }
    }

    // MARK: - Configure

    func configure(initialType: DiaperType, showTypePicker: Bool) {
        notesView.reset()

        let mapped: DiaperTypeView.DiaperType
        switch initialType {
        case .wet:   mapped = .wet
        case .dirty: mapped = .dirty
        case .mixed: mapped = .mixed
        }
        selectedDiaperType = mapped
        diaperTypeView.selectedType = mapped

        diaperTypeView.isHidden = !showTypePicker
        typeBadge.isHidden = showTypePicker

        if showTypePicker {
            sheetHeightConstraint?.update(offset: 480 * Constraint.xCoeff)
            notesTopToTitleConstraint?.deactivate()
            notesTopToPickerConstraint?.activate()
        } else {
            typeBadgeLabel.text = initialType.badgeTitle
            typeBadge.backgroundColor = initialType.accentColor
            sheetHeightConstraint?.update(offset: 420 * Constraint.xCoeff)
            notesTopToPickerConstraint?.deactivate()
            notesTopToTitleConstraint?.activate()
        }
        layoutIfNeeded()
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() { onTapCloseButton?() }

    @objc private func saveTapped() {
        let mapped: DiaperType
        switch selectedDiaperType {
        case .wet:   mapped = .wet
        case .dirty: mapped = .dirty
        case .mixed: mapped = .mixed
        }
        let note = notesView.notesText
        onTapSave?(mapped, note)
    }
}

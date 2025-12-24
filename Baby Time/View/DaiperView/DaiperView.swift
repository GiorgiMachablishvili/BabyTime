

import UIKit
import SnapKit

class DaiperView: UIView {

    var onTapCloseButton: (() -> Void)?
    private(set) var selectedDiaperType: DiaperTypeView.DiaperType = .wet

    private lazy var blurEffectView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .gray.withAlphaComponent(0.9)
        return view
    }()

    private lazy var feedingView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var logDiaperTitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Log Diaper"
        view.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        view.textColor = .label
        return view
    }()

    private lazy var closeFeedingViewButton: UIButton = {
        let view = UIButton(frame: .zero)
        let image = UIImage(systemName: "xmark.circle")!
        view.setImage(image, for: .normal)
        view.tintColor = .label
        view.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return view
    }()

    private lazy var diaperTypeView: DiaperTypeView = {
        let view = DiaperTypeView()
        return view
    }()

    private lazy var notesOptionalView: NotesOptionalView = {
        let view = NotesOptionalView()
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.makeRoundCorners(12)
        view.setTitle("Save", for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        view.setTitleColor(.labelWhiteColor, for: .normal)
        view.backgroundColor = .pressButtonColor
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupUI()
        setupConstraint()
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(blurEffectView)
        addSubview(feedingView)
        feedingView.addSubview(logDiaperTitleLabel)
        feedingView.addSubview(closeFeedingViewButton)
        feedingView.addSubview(diaperTypeView)
        feedingView.addSubview(notesOptionalView)
        feedingView.addSubview(saveButton)
    }

    private func setupConstraint() {
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        feedingView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(550 * Constraint.xCoeff)
        }

        logDiaperTitleLabel.snp.remakeConstraints { make in
            make.top.leading.equalTo(feedingView).inset(10 * Constraint.xCoeff)
        }

        closeFeedingViewButton.snp.remakeConstraints { make in
            make.top.equalTo(feedingView.snp.top).offset(10 * Constraint.xCoeff)
            make.trailing.equalTo(feedingView.snp.trailing).offset(-10 * Constraint.xCoeff)
            make.height.width.equalTo(34 * Constraint.xCoeff)
        }

        diaperTypeView.snp.makeConstraints { make in
            make.top.equalTo(logDiaperTitleLabel.snp.bottom).offset(24 * Constraint.xCoeff)
            make.leading.trailing.equalTo(feedingView).inset(16 * Constraint.xCoeff)
        }

        notesOptionalView.snp.remakeConstraints { make in
            make.top.equalTo(diaperTypeView.snp.bottom).offset(20 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(10 * Constraint.yCoeff)
            make.height.equalTo(80 * Constraint.xCoeff)
        }

        saveButton.snp.remakeConstraints { make in
            make.top.equalTo(notesOptionalView.snp.bottom).offset(20 * Constraint.yCoeff)
            make.leading.trailing.equalToSuperview().inset(30 * Constraint.yCoeff)
            make.height.equalTo(50 * Constraint.xCoeff)
        }
    }

    private func setupBindings() {
            diaperTypeView.onTypeChanged = { [weak self] type in
                self?.selectedDiaperType = type
            }
        }

    @objc private func closeButtonTapped() {
        self.onTapCloseButton?()
    }

}

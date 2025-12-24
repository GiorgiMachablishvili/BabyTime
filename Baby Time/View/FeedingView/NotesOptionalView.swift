import UIKit
import SnapKit

class NotesOptionalView: UIView {

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .black
        view.textAlignment = .center
        view.text = "Notes (optional)"
        return view
    }()

    private lazy var notesTextField: UITextField = {
        let view = UITextField(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.textColor = .label
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        view.textAlignment = .left
        let placeholder = NSAttributedString(string: "Add a note...", attributes: [
            .foregroundColor: UIColor.black.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ])
        view.attributedPlaceholder = placeholder
        view.borderStyle = .none
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        view.leftView = leftPadding
        view.leftViewMode = .always
        view.rightView = rightPadding
        view.rightViewMode = .always
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(notesTextField)
    }

    private func setupConstraints() {
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(snp.top).offset(20 * Constraint.xCoeff)
            make.leading.equalToSuperview()
        }

        notesTextField.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(16 * Constraint.xCoeff)
            make.height.equalTo(44 * Constraint.xCoeff)
        }
    }
}

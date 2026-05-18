import UIKit
import SnapKit

class NotesOptionalView: UIView {

    var notesText: String? {
        let t = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty || t == "" ? nil : t
    }

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .black
        view.textAlignment = .left
        view.text = "Notes"
        return view
    }()

    private lazy var notesTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.textColor = .label
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        view.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isScrollEnabled = false
        view.delegate = self
        return view
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "Add a note..."
        l.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor.black.withAlphaComponent(0.4)
        l.isUserInteractionEnabled = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(notesTextView)
        notesTextView.addSubview(placeholderLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview()
        }
        notesTextView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(16 * Constraint.yCoeff)
            $0.height.equalTo(90 * Constraint.xCoeff)
        }
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(14)
        }
    }

    func reset() {
        notesTextView.text = ""
        placeholderLabel.isHidden = false
    }
}

extension NotesOptionalView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

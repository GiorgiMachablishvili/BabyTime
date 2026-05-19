import UIKit
import SnapKit

final class VisitEditViewController: UIViewController {

    var visit: VisitReminder?
    var forDate: Date?
    var kind: VisitReminder.Kind = .vaccination
    var onSave: ((VisitReminder) -> Void)?
    var onDelete: ((UUID) -> Void)?

    private var selectedDaysBefore: Set<Int> = []

    private lazy var noteLabel: UILabel = {
        let view = UILabel()
        view.text = "Note"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var noteTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "e.g. Routine checkup, vaccine name"
        view.borderStyle = .roundedRect
        view.font = .systemFont(ofSize: 16)
        return view
    }()

    private lazy var notifyLabel: UILabel = {
        let view = UILabel()
        view.text = "Notify me before the visit"
        view.font = .systemFont(ofSize: 14, weight: .medium)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var daysStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        view.distribution = .fillEqually
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .onDrag
        view.alwaysBounceVertical = true
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var saveButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Save", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = .growthViewColor
        view.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var deleteButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Delete", for: .normal)
        view.setTitleColor(.systemRed, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return view
    }()

    private var dayButtons: [Int: UIButton] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = visit == nil ? "Add Visit" : "Edit Visit"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        setupDaysStack()
        setupUI()
        setupConstraints()
        if let v = visit {
            noteTextField.text = v.note
            selectedDaysBefore = Set(v.notifyDaysBefore)
            deleteButton.isHidden = false
            updateDayButtons()
        } else {
            selectedDaysBefore = [1]
            deleteButton.isHidden = true
            updateDayButtons()
        }
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    private func setupDaysStack() {
        for d in VisitReminder.notifyDaysBeforeOptions {
            let btn = UIButton(type: .system)
            btn.setTitle("\(d)d", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            btn.tag = d
            btn.layer.cornerRadius = 10
            btn.clipsToBounds = true
            btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
            dayButtons[d] = btn
            daysStack.addArrangedSubview(btn)
        }
    }

    private func updateDayButtons() {
        for (d, btn) in dayButtons {
            let selected = selectedDaysBefore.contains(d)
            btn.backgroundColor = selected ? UIColor.growthViewColor : UIColor.secondarySystemFill
            btn.setTitleColor(selected ? .white : .label, for: .normal)
        }
    }

    @objc private func dayTapped(_ sender: UIButton) {
        let d = sender.tag
        if selectedDaysBefore.contains(d) {
            selectedDaysBefore.remove(d)
        } else {
            selectedDaysBefore.insert(d)
        }
        if selectedDaysBefore.isEmpty {
            selectedDaysBefore.insert(1)
        }
        updateDayButtons()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(noteLabel)
        contentView.addSubview(noteTextField)
        contentView.addSubview(notifyLabel)
        contentView.addSubview(daysStack)
        contentView.addSubview(saveButton)
        contentView.addSubview(deleteButton)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        noteLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalToSuperview().offset(20)
        }
        noteTextField.snp.makeConstraints {
            $0.top.equalTo(noteLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        notifyLabel.snp.makeConstraints {
            $0.top.equalTo(noteTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }
        daysStack.snp.makeConstraints {
            $0.top.equalTo(notifyLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(daysStack.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        deleteButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let id = visit?.id ?? UUID()
        let date = visit?.visitDate ?? forDate ?? Date()
        let note = (noteTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let days = Array(selectedDaysBefore).sorted()
        let updated = VisitReminder(id: id, visitDate: date, note: note, notifyDaysBefore: days, kind: kind)
        onSave?(updated)
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        guard let id = visit?.id else { return }
        onDelete?(id)
        dismiss(animated: true)
    }
}

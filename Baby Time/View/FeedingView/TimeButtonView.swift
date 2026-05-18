import UIKit
import SnapKit

class TimeButtonView: UIView {

    private let selectedColor = UIColor.pressButtonColor
    private let normalColor   = UIColor.buttonGayColor

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .black
        l.text = "Duration (minutes)"
        return l
    }()

    // Row 1 — fixed presets
    private let row1ScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceHorizontal = true
        return s
    }()
    private let row1Stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    // Row 2 — custom pills + Other
    private let row2ScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceHorizontal = true
        return s
    }()
    private let row2Stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private lazy var min5  = makePill("5 min")
    private lazy var min10 = makePill("10 min")
    private lazy var min15 = makePill("15 min")
    private lazy var min20 = makePill("20 min")
    private lazy var min30 = makePill("30 min")
    private lazy var otherPill = makePill("Other")

    private var allPills: [TimePillView] = []
    private weak var selectedPill: TimePillView?

    var selectedDurationText: String? { selectedPill?.timeLabel.text }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()

        [min5, min10, min15, min20, min30].forEach { row1Stack.addArrangedSubview($0) }
        row2Stack.addArrangedSubview(otherPill)

        allPills = [min5, min10, min15, min20, min30, otherPill]
        applySelection(selected: min5)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makePill(_ text: String) -> TimePillView {
        let v = TimePillView()
        v.timeLabel.text = text
        v.backgroundColor = normalColor
        v.isUserInteractionEnabled = true
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pillTapped(_:))))
        return v
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(row1ScrollView)
        row1ScrollView.addSubview(row1Stack)
        addSubview(row2ScrollView)
        row2ScrollView.addSubview(row2Stack)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            $0.leading.equalToSuperview()
        }
        row1ScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40 * Constraint.xCoeff)
        }
        row1Stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            $0.height.equalTo(row1ScrollView)
        }
        row2ScrollView.snp.makeConstraints {
            $0.top.equalTo(row1ScrollView.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40 * Constraint.xCoeff)
        }
        row2Stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            $0.height.equalTo(row2ScrollView)
        }
    }

    func reset() {
        // Remove any custom pills from row2, keep only Other
        row2Stack.arrangedSubviews.forEach {
            if $0 !== otherPill {
                row2Stack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
        allPills = [min5, min10, min15, min20, min30, otherPill]
        otherPill.timeLabel.text = "Other"
        row2ScrollView.setContentOffset(.zero, animated: false)
        applySelection(selected: min5)
    }

    private func applySelection(selected: TimePillView) {
        allPills.forEach { pill in
            let on = pill === selected
            pill.backgroundColor = on ? selectedColor : normalColor
            pill.timeLabel.textColor = on ? .labelWhiteColor : .pressButtonTitleColor
        }
        selectedPill = selected
    }

    @objc private func pillTapped(_ g: UITapGestureRecognizer) {
        guard let pill = g.view as? TimePillView else { return }
        if pill === otherPill {
            presentCustomInput()
        } else {
            applySelection(selected: pill)
        }
    }

    private func addCustomPill(text: String) {
        let pill = makePill(text)
        allPills.insert(pill, at: allPills.count - 1)
        let otherIndex = row2Stack.arrangedSubviews.firstIndex(of: otherPill) ?? row2Stack.arrangedSubviews.count
        row2Stack.insertArrangedSubview(pill, at: otherIndex)
        applySelection(selected: pill)

        DispatchQueue.main.async {
            let rightEdge = self.row2Stack.frame.maxX + 10
            let offset = max(0, rightEdge - self.row2ScrollView.bounds.width)
            self.row2ScrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
        }
    }

    private func presentCustomInput() {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController {
                let alert = UIAlertController(title: "Custom duration", message: "Enter minutes", preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.placeholder = "e.g. 25"
                    tf.keyboardType = .numberPad
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    guard let self,
                          let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                          let mins = Int(text), mins > 0 else { return }
                    self.addCustomPill(text: "\(mins) min")
                })
                vc.present(alert, animated: true)
                return
            }
            responder = r.next
        }
    }
}

import UIKit
import SnapKit

final class VolumeButtonView: UIView {

    private let selectedColor = UIColor.pressButtonColor
    private let normalColor   = UIColor.buttonGayColor

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .left
        l.text = "Volume (ml)"
        return l
    }()

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

    // Row 1 presets (fixed)
    private lazy var ml30  = makePill("30 ml")
    private lazy var ml60  = makePill("60 ml")
    private lazy var ml90  = makePill("90 ml")
    private lazy var ml120 = makePill("120 ml")
    private lazy var ml150 = makePill("150 ml")

    // Row 2 presets (fixed)
    private lazy var ml180 = makePill("180 ml")
    private lazy var ml210 = makePill("210 ml")
    private lazy var ml240 = makePill("240 ml")
    private lazy var otherPill = makePill("Other")

    private var allPills: [TimePillView] = []
    private weak var selectedPillView: TimePillView?

    var selectedVolumeText: String? { selectedPillView?.timeLabel.text }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()

        [ml30, ml60, ml90, ml120, ml150].forEach { row1Stack.addArrangedSubview($0) }
        [ml180, ml210, ml240, otherPill].forEach   { row2Stack.addArrangedSubview($0) }

        allPills = [ml30, ml60, ml90, ml120, ml150, ml180, ml210, ml240, otherPill]
        applySelection(selected: ml30)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makePill(_ text: String) -> TimePillView {
        let v = TimePillView()
        v.timeLabel.text = text
        v.isUserInteractionEnabled = true
        v.backgroundColor = normalColor
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
            $0.leading.equalToSuperview().offset(10 * Constraint.yCoeff)
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
        // Remove any custom pills from row2 (keep only fixed presets + Other)
        let fixedRow2: [UIView] = [ml180, ml210, ml240, otherPill]
        row2Stack.arrangedSubviews.forEach {
            if !fixedRow2.contains($0) {
                row2Stack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
        // Restore row2 order in case anything was disrupted
        fixedRow2.forEach { v in
            if v.superview == nil { row2Stack.addArrangedSubview(v) }
        }
        allPills = [ml30, ml60, ml90, ml120, ml150, ml180, ml210, ml240, otherPill]
        otherPill.timeLabel.text = "Other"
        row2ScrollView.setContentOffset(.zero, animated: false)
        applySelection(selected: ml30)
    }

    private func applySelection(selected: TimePillView) {
        allPills.forEach { pill in
            let on = pill === selected
            pill.backgroundColor = on ? selectedColor : normalColor
            pill.timeLabel.textColor = on ? .labelWhiteColor : .pressButtonTitleColor
        }
        selectedPillView = selected
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
                let alert = UIAlertController(title: "Custom volume", message: "Enter amount in ml", preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.placeholder = "e.g. 135"
                    tf.keyboardType = .numberPad
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    guard let self,
                          let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                          let ml = Int(text), ml > 0 else { return }
                    self.addCustomPill(text: "\(ml) ml")
                })
                vc.present(alert, animated: true)
                return
            }
            responder = r.next
        }
    }
}

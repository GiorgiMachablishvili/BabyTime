import UIKit
import SnapKit

final class VolumeButtonView: UIView {

    private let selectedColor = UIColor.pressButtonColor
    private let normalColor = UIColor.buttonGayColor

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .left
        l.text = "Volume (ml)"
        return l
    }()

    private func makePill(_ text: String) -> TimePillView {
        let v = TimePillView()
        v.timeLabel.text = text
        v.isUserInteractionEnabled = true
        v.backgroundColor = normalColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePillTap(_:)))
        v.addGestureRecognizer(tap)
        return v
    }

    private lazy var ml30 = makePill("30 ml")
    private lazy var ml60 = makePill("60 ml")
    private lazy var ml90 = makePill("90 ml")
    private lazy var ml120 = makePill("120 ml")
    private lazy var ml150 = makePill("150 ml")
    private lazy var ml180 = makePill("180 ml")
    private lazy var ml210 = makePill("210 ml")
    private lazy var ml240 = makePill("240 ml")
    private lazy var ml270 = makePill("270 ml")

    /// Currently selected volume pill; used to expose selected volume text.
    private weak var selectedPillView: TimePillView?

    /// The volume string of the currently selected pill (e.g. "90 ml", "120 ml").
    var selectedVolumeText: String? {
        selectedPillView?.timeLabel.text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        applySelection(selected: ml30)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        addSubview(titleLabel)
        [ml30, ml60, ml90, ml120, ml150, ml180, ml210, ml240, ml270].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20 * Constraint.xCoeff)
            make.leading.equalToSuperview().offset(10 * Constraint.xCoeff)
        }

        ml30.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.equalToSuperview().offset(10 * Constraint.xCoeff)
            make.height.equalTo(40 * Constraint.xCoeff)
            make.width.equalTo(70 * Constraint.xCoeff)
        }
        ml60.snp.makeConstraints { make in
            make.top.equalTo(ml30)
            make.leading.equalTo(ml30.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml90.snp.makeConstraints { make in
            make.top.equalTo(ml30)
            make.leading.equalTo(ml60.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml120.snp.makeConstraints { make in
            make.top.equalTo(ml30)
            make.leading.equalTo(ml90.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml150.snp.makeConstraints { make in
            make.top.equalTo(ml30)
            make.leading.equalTo(ml120.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml180.snp.makeConstraints { make in
            make.top.equalTo(ml30.snp.bottom).offset(10 * Constraint.xCoeff)
            make.leading.equalToSuperview().offset(10 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml210.snp.makeConstraints { make in
            make.top.equalTo(ml180)
            make.leading.equalTo(ml180.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml240.snp.makeConstraints { make in
            make.top.equalTo(ml180)
            make.leading.equalTo(ml210.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
        ml270.snp.makeConstraints { make in
            make.top.equalTo(ml180)
            make.leading.equalTo(ml240.snp.trailing).offset(5 * Constraint.xCoeff)
            make.size.equalTo(ml30)
        }
    }

    private func applySelection(selected: UIView) {
        let buttons = [ml30, ml60, ml90, ml120, ml150, ml180, ml210, ml240, ml270]
        buttons.forEach { btn in
            let isSelected = (btn === selected)
            btn.backgroundColor = isSelected ? selectedColor : normalColor
            btn.timeLabel.textColor = isSelected ? UIColor.labelWhiteColor : UIColor.pressButtonTitleColor
        }
        selectedPillView = selected as? TimePillView
    }

    @objc private func handlePillTap(_ gesture: UITapGestureRecognizer) {
        guard let tapped = gesture.view else { return }
        applySelection(selected: tapped)
    }
}

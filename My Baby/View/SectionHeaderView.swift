import UIKit
import SnapKit

final class SectionHeaderView: UIView {

    // MARK: - Callbacks
    var onTapPlus: (() -> Void)?
    var onTapCalendar: (() -> Void)?

    // MARK: - UI

    lazy var calendarButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "calendar.badge.clock"), for: .normal)
        view.tintColor = .white
        view.backgroundColor = .orangeColor
        view.clipsToBounds = true
        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 34, weight: .bold)
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        view.numberOfLines = 1
        return view
    }()

    lazy var subtitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 18, weight: .regular)
        view.textColor = UIColor.secondaryLabel
        view.numberOfLines = 1
        return view
    }()

    lazy var plusButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.tintColor = .white
        view.backgroundColor = .orangeColor
        view.clipsToBounds = true
        return view
    }()

    private var titleTrailingToCalendar: SnapKit.Constraint?
    private var titleTrailingToPlus: SnapKit.Constraint?
    private var calendarButtonWidth: SnapKit.Constraint?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(calendarButton)
        addSubview(plusButton)
    }

    private func setupConstraints() {
        // Title constraints, including two alternative trailing constraints we can toggle
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(snp.top).offset(60 * Constraint.xCoeff)
            make.leading.equalTo(snp.leading).offset(20 * Constraint.yCoeff)
            titleTrailingToCalendar = make.trailing.lessThanOrEqualTo(calendarButton.snp.leading).offset(-12 * Constraint.yCoeff).constraint
            titleTrailingToPlus = make.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-12 * Constraint.yCoeff).constraint
        }
        titleTrailingToCalendar?.activate()
        titleTrailingToPlus?.deactivate()

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6 * Constraint.xCoeff)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(calendarButton.snp.leading).offset(-12 * Constraint.yCoeff)
        }

        calendarButton.snp.makeConstraints { make in
            make.trailing.equalTo(plusButton.snp.leading).offset(-12 * Constraint.yCoeff)
            make.centerY.equalTo(titleLabel.snp.bottom).offset(-3 * Constraint.xCoeff)
            make.height.equalTo(48 * Constraint.xCoeff)
            calendarButtonWidth = make.width.equalTo(48 * Constraint.yCoeff).constraint
        }
        calendarButtonWidth?.activate()

        plusButton.snp.makeConstraints {
            $0.trailing.equalTo(snp.trailing).offset(-20 * Constraint.yCoeff)
            $0.centerY.equalTo(titleLabel.snp.bottom).offset(-3 * Constraint.xCoeff)
            $0.width.equalTo(48 * Constraint.yCoeff)
            $0.height.equalTo(48 * Constraint.xCoeff)
        }
    }

    private func setupActions() {
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
    }

    @objc private func plusTapped() {
        onTapPlus?()
    }

    @objc private func calendarTapped() {
        onTapCalendar?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        plusButton.layer.cornerRadius = plusButton.bounds.height / 2
        calendarButton.layer.cornerRadius = calendarButton.bounds.height / 2
    }

    // MARK: - Public API

    /// Configure everything from outside
    func configure(
        title: String,
        subtitle: String,
        showsPlusButton: Bool = true,
        plusColor: UIColor = .systemOrange,
        showsCalendarButton: Bool = false,
        calendarColor: UIColor? = nil
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        plusButton.isHidden = !showsPlusButton
        plusButton.backgroundColor = plusColor

        calendarButton.isHidden = !showsCalendarButton
        calendarButtonWidth?.update(offset: showsCalendarButton ? 48 * Constraint.yCoeff : 0)
        if let calendarColor = calendarColor {
            calendarButton.backgroundColor = calendarColor
        }
        if showsCalendarButton {
            titleTrailingToCalendar?.activate()
            titleTrailingToPlus?.deactivate()
            subtitleLabel.snp.remakeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(6 * Constraint.xCoeff)
                $0.leading.equalTo(titleLabel)
                $0.trailing.lessThanOrEqualTo(calendarButton.snp.leading).offset(-12 * Constraint.yCoeff)
            }
        } else {
            titleTrailingToCalendar?.deactivate()
            titleTrailingToPlus?.activate()
            subtitleLabel.snp.remakeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(6 * Constraint.xCoeff)
                $0.leading.equalTo(titleLabel)
                $0.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-12 * Constraint.yCoeff)
            }
        }
    }

    /// If you want to change only plus button visibility later
    func setPlusButtonVisible(_ visible: Bool) {
        plusButton.isHidden = !visible
    }
}

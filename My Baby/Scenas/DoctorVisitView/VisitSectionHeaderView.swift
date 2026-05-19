import UIKit
import SnapKit

final class VisitSectionHeaderView: UIView {

    // MARK: - Public Closures

    var onTapPlus: (() -> Void)?
    var onTapCalendar: (() -> Void)?

    // MARK: - Private UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "plus")
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.isHidden = true
        return button
    }()

    private let calendarButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "calendar")
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.isHidden = true
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupViews()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupViews()
        setupConstraints()
        setupActions()
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(plusButton)
        addSubview(calendarButton)
    }

    private func setupConstraints() {
        // Plus and Calendar buttons on the right
        calendarButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(30)
        }

        plusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(calendarButton.snp.leading).offset(-8)
            make.size.equalTo(30)
        }

        // Title label top-left
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-8)
            make.height.greaterThanOrEqualTo(20)
        }

        // Subtitle label below title label
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-8)
            make.bottom.equalToSuperview().inset(8)
            make.height.greaterThanOrEqualTo(16)
        }
    }

    private func setupActions() {
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(didTapCalendar), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(
        title: String,
        subtitle: String,
        showsPlusButton: Bool,
        plusColor: UIColor,
        showsCalendarButton: Bool,
        calendarColor: UIColor
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        plusButton.isHidden = !showsPlusButton
        plusButton.tintColor = plusColor

        calendarButton.isHidden = !showsCalendarButton
        calendarButton.tintColor = calendarColor
    }

    // MARK: - Actions

    @objc private func didTapPlus() {
        onTapPlus?()
    }

    @objc private func didTapCalendar() {
        onTapCalendar?()
    }
}


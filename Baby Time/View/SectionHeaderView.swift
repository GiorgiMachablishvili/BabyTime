

import UIKit
import SnapKit

final class SectionHeaderView: UIView {

    // MARK: - Callbacks
    var onTapPlus: (() -> Void)?

    // MARK: - UI

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

    override func layoutSubviews() {
        super.layoutSubviews()
        // round button (circle)
        plusButton.layer.cornerRadius = plusButton.bounds.height / 2
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(plusButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(snp.top).offset(60 * Constraint.xCoeff)
            $0.leading.equalTo(snp.leading).offset(20 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-12)
        }

        plusButton.snp.makeConstraints {
            $0.trailing.equalTo(snp.trailing).offset(-20 * Constraint.yCoeff)
            $0.centerY.equalTo(titleLabel.snp.bottom).offset(-3) // visually matches screenshot
            $0.width.height.equalTo(48)
        }
    }

    private func setupActions() {
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
    }

    @objc private func plusTapped() {
        onTapPlus?()
    }

    // MARK: - Public API

    /// Configure everything from outside
    func configure(
        title: String,
        subtitle: String,
        showsPlusButton: Bool = true,
        plusColor: UIColor = .systemOrange
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        plusButton.isHidden = !showsPlusButton
        plusButton.backgroundColor = plusColor
    }

    /// If you want to change only plus button visibility later
    func setPlusButtonVisible(_ visible: Bool) {
        plusButton.isHidden = !visible
    }
}



import UIKit
import SnapKit

final class ActionCardButton: UIView {

    // MARK: - Callback

    var onTap: (() -> Void)?

    // MARK: - UI

    lazy var iconImageView: UIImageView = {
        let iv = UIImageView(frame: .zero)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .buttonTitleColor
        return iv
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .buttonTitleColor
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraint()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 20
        clipsToBounds = true

        addSubview(iconImageView)
        addSubview(titleLabel)
    }

    private func setupConstraint() {
        iconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Public API

    func configure(
        backgroundColor: UIColor,
        icon: UIImage?,
        title: String,
        textColor: UIColor = .black,
        iconColor: UIColor = .black
    ) {
        self.backgroundColor = backgroundColor
        iconImageView.image = icon
        iconImageView.tintColor = iconColor
        titleLabel.text = title
        titleLabel.textColor = textColor
    }
}

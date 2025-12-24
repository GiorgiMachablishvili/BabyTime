

import UIKit
import SnapKit

final class StatsCardView: UIView {

    // MARK: - UI

    private let iconContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        view.layer.cornerRadius = 20
        return view
    }()

    lazy var iconImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.tintColor = .white
        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textColor = .white
        view.font = .systemFont(ofSize: 14, weight: .light)
        return view
    }()

    lazy var countLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textColor = .white
        view.font = .systemFont(ofSize: 24, weight: .bold)
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 20
        clipsToBounds = true

        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(countLabel)
    }

    private func setupConstraints() {
        iconContainerView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(8)
            $0.width.height.equalTo(40)
        }

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalTo(iconContainerView.snp.trailing).offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    // MARK: - Configuration API (THIS IS IMPORTANT)

    func configure(
        backgroundColor: UIColor,
        icon: UIImage?,
        title: String,
        count: Int
    ) {
        self.backgroundColor = backgroundColor
        iconImageView.image = icon
        titleLabel.text = title
        countLabel.text = "\(count)"
    }
}

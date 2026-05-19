import UIKit
import SnapKit

/// Reusable section header: title + optional "See All" button.
final class HistorySectionHeaderView: UICollectionReusableView {
    static let reuseId = "HistorySectionHeaderView"

    var onTapSeeAll: (() -> Void)?

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 20, weight: .semibold)
        v.textColor = UIColor.label.withAlphaComponent(0.88)
        v.numberOfLines = 1
        return v
    }()

    private let seeAllButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("See All", for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.isHidden = true
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        seeAllButton.addTarget(self, action: #selector(didTapSeeAll), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(seeAllButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.bottom.equalToSuperview().offset(-6 * Constraint.xCoeff)
            $0.top.greaterThanOrEqualToSuperview().offset(8 * Constraint.xCoeff)
            $0.trailing.lessThanOrEqualTo(seeAllButton.snp.leading).offset(-12 * Constraint.yCoeff)
        }
        seeAllButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-16 * Constraint.yCoeff)
        }
    }

    func configure(title: String, showsSeeAll: Bool) {
        titleLabel.text = title
        seeAllButton.isHidden = !showsSeeAll
    }

    @objc private func didTapSeeAll() {
        onTapSeeAll?()
    }
}


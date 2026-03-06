import UIKit
import SnapKit

final class FeedingSectionHeaderView: UICollectionReusableView {

    static let reuseId = "FeedingSectionHeaderView"

    var onTapAdd: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 22, weight: .bold)
        view.textColor = .label
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 15, weight: .regular)
        view.textColor = .secondaryLabel
        return view
    }()

    private lazy var addButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.tintColor = .white
        view.backgroundColor = .feedingViewColor
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(addButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(16 * Constraint.yCoeff)
            $0.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-12 * Constraint.yCoeff)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4 * Constraint.xCoeff)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-12 * Constraint.yCoeff)
        }
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16 * Constraint.yCoeff)
            $0.centerY.equalTo(titleLabel.snp.bottom).offset(-6 * Constraint.xCoeff)
            $0.width.equalTo(48 * Constraint.yCoeff)
            $0.height.equalTo(48 * Constraint.xCoeff)
        }
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func addTapped() {
        onTapAdd?()
    }

    func configure(title: String, subtitle: String, showsAddButton: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        addButton.isHidden = !showsAddButton
    }
}

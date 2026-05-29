import UIKit
import SnapKit

final class FeedingSectionHeaderView: UICollectionReusableView {

    static let reuseId = "FeedingSectionHeaderView"

    var onTapAdd: (() -> Void)?
    var onTapViewAll: (() -> Void)?

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

    private lazy var viewAllButton: UIButton = {
        let btn = UIButton(type: .system)

        // "View all  →"
        var config = UIButton.Configuration.plain()
        config.title = "View all"
        config.image = UIImage(systemName: "chevron.right",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        btn.configuration = config
        btn.titleLabel?.font = .systemFont(ofSize: 14 * Constraint.yCoeff, weight: .medium)
        btn.isHidden = true
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(addButton)
        addSubview(viewAllButton)

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
        viewAllButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16 * Constraint.yCoeff)
            $0.centerY.equalTo(titleLabel)
        }

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func addTapped() {
        onTapAdd?()
    }

    @objc private func viewAllTapped() {
        onTapViewAll?()
    }

    func configure(title: String, subtitle: String, showsAddButton: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        addButton.isHidden = !showsAddButton
        viewAllButton.isHidden = true
    }

    func configureSimple(title: String) {
        titleLabel.text = title
        subtitleLabel.text = ""
        addButton.isHidden = true
        viewAllButton.isHidden = true
        titleLabel.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
    }

    /// Shows "Today / <date>" on the left and a "View all →" link on the right.
    func configureTodayHeader(title: String) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16 * Constraint.yCoeff, weight: .bold)
        subtitleLabel.text = ""
        addButton.isHidden = true
        viewAllButton.isHidden = false
        // titleLabel's existing trailing constraint (<=addButton.leading) keeps it from
        // overlapping the right-side button area, which is sufficient here.
    }
}

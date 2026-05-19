import UIKit
import SnapKit

final class MainActionCardCell: UICollectionViewCell {

    static let reuseId = "MainActionCardCell"

    var onTap: (() -> Void)?

    private lazy var cardView: ActionCardButton = {
        let view = ActionCardButton()
        view.onTap = { [weak self] in
            self?.onTap?()
        }
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        contentView.addSubview(cardView)
    }

    private func setupConstraints() {
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(backgroundColor: UIColor, icon: UIImage?, title: String, valueText: String? = nil) {
        cardView.configure(
            backgroundColor: backgroundColor,
            icon: icon,
            title: title,
            valueText: valueText,
            textColor: .buttonTitleColor,
            iconColor: .buttonTitleColor
        )
    }
}

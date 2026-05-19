

import UIKit
import SnapKit

final class SleepHistoryTitleCell: UICollectionViewCell {

    private let titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Sleep History"
        view.font = .systemFont(ofSize: 26, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()
    

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear

        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}



import UIKit
import SnapKit

final class GenderButton: UIControl {

    var onTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textAlignment = .center
        l.textColor = UIColor.label.withAlphaComponent(0.5)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    convenience init(title: String) {
        self.init(frame: .zero)
        titleLabel.text = title
    }

    func setSelected(_ selected: Bool, selectedColor: UIColor) {
        if selected {
            backgroundColor = selectedColor
            titleLabel.textColor = .white
        } else {
            backgroundColor = UIColor.systemGray6
            titleLabel.textColor = UIColor.label.withAlphaComponent(0.5)
        }
    }

    @objc private func tapped() {
        onTap?()
    }
}

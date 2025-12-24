import UIKit
import SnapKit

final class TimePillView: UIView {

    lazy var timeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textAlignment = .center
        view.textColor = .buttonTitleColor
        view.font = .systemFont(ofSize: 14, weight: .medium)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // pill = half height
        layer.cornerRadius = bounds.height / 2
    }

    private func setupUI() {
        backgroundColor = UIColor.systemGray6
        addSubview(timeLabel)
    }

    private func setupConstraints() {
        timeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8))
        }
    }

    // MARK: - Public API

    func configure(timeText: String) {
        timeLabel.text = timeText
    }

    // Optional: if you want to change style too
    func configure(timeText: String, backgroundColor: UIColor, textColor: UIColor) {
        self.backgroundColor = backgroundColor
        timeLabel.textColor = textColor
        timeLabel.text = timeText
    }
}

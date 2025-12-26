import UIKit
import SnapKit

final class SleepHistoryCell: UICollectionViewCell {

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        return view
    }()

    private let iconBox: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.25)
        view.layer.cornerRadius = 14
        return view
    }()

    private let iconImage: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UIImage(systemName: "moon")
        view.tintColor = .white
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.text = "Sleep"
        view.font = .systemFont(ofSize: 20, weight: .semibold)
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()

    private let subtitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 16)
        view.textColor = .secondaryLabel
        return view
    }()

    private let timeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 18, weight: .semibold)
        view.textAlignment = .right
        view.textColor = UIColor.label.withAlphaComponent(0.85)
        return view
    }()

    private let dateLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = .systemFont(ofSize: 15)
        view.textAlignment = .right
        view.textColor = .secondaryLabel
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 22
        contentView.clipsToBounds = true

        setupUI()
        setupConstraints()
        configureViews()
        setContentVisibility(isEmpty: true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        contentView.addSubview(emptyStateView)
        contentView.addSubview(iconBox)
        iconBox.addSubview(iconImage)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(dateLabel)
    }

    private func setupConstraints() {
        emptyStateView.snp.remakeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(180)
        }

        iconBox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(18)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(60)
        }

        iconImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(26)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.equalTo(iconBox.snp.trailing).offset(16)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalToSuperview().offset(-18)
            $0.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-12)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.trailing.equalToSuperview().offset(-18)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(6)
            $0.trailing.equalTo(timeLabel)
        }
    }

    private func configureViews() {
        emptyStateView.configure(
            icon: UIImage(systemName: "fork.knife"),
            iconTint: .sleepViewColor.withAlphaComponent(0.95),
            circleColor: .sleepViewColor.withAlphaComponent(0.40),
            title: "No feedings yet",
            subtitle: "Tap the + button to log a feeding"
        )
    }

    private func setContentVisibility(isEmpty: Bool) {
        emptyStateView.isHidden = !isEmpty
        iconBox.isHidden = isEmpty
        iconImage.isHidden = isEmpty
        titleLabel.isHidden = isEmpty
        subtitleLabel.isHidden = isEmpty
        timeLabel.isHidden = isEmpty
        dateLabel.isHidden = isEmpty
    }

    func configure(statusText: String, timeText: String, dateText: String) {
        subtitleLabel.text = statusText
        timeLabel.text = timeText
        dateLabel.text = dateText
        setContentVisibility(isEmpty: false)
    }

    func configureEmpty() {
        // Reuse existing empty view configuration and show it
        setContentVisibility(isEmpty: true)
    }
}

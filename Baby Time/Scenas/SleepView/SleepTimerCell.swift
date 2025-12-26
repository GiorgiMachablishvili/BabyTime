

import UIKit
import SnapKit

final class SleepTimerCell: UICollectionViewCell {

    enum State {
        case idle
        case running(elapsedText: String)
    }

    var onTapStart: (() -> Void)?
    var onTapStop: (() -> Void)?

    private lazy var moonImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UIImage(systemName: "moon")
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textAlignment = .center
        return view
    }()

    private lazy var timeLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textAlignment = .center
        view.isHidden = true
        return view
    }()

    private lazy var actionButton: UIButton = {
        let view = UIButton(type: .system)
        view.tintColor = .white
        view.clipsToBounds = true
        view.makeRoundCorners(33)
        return view
    }()

    private lazy var hintLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.textAlignment = .center
        return view
    }()

    private var state: State = .idle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
        render(.idle)
        contentView.clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
//        actionButton.layer.cornerRadius = actionButton.bounds.height / 2
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 24
        contentView.clipsToBounds = true
        contentView.backgroundColor = .systemBackground

        contentView.addSubview(moonImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(hintLabel)
    }

    private func setupConstraints() {
        moonImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(moonImageView.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        actionButton.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(18)
            $0.centerX.equalToSuperview()
            $0.height.width.equalTo(66)
        }

        hintLabel.snp.makeConstraints {
            $0.top.equalTo(actionButton.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-28)
        }
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    @objc private func actionTapped() {
        switch state {
        case .idle: onTapStart?()
        case .running: onTapStop?()
        }
    }

    func render(_ state: State) {
        self.state = state

        switch state {
        case .idle:
            contentView.backgroundColor = .systemBackground

            moonImageView.tintColor = UIColor.systemPurple.withAlphaComponent(0.35)

            titleLabel.text = "Start sleep timer"
            titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
            titleLabel.textColor = UIColor.label.withAlphaComponent(0.65)

            timeLabel.isHidden = true

            actionButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            actionButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.35)
            actionButton.tintColor = .white

            hintLabel.text = "Tap to start"
            hintLabel.font = .systemFont(ofSize: 16)
            hintLabel.textColor = .secondaryLabel

        case .running(let elapsedText):
            contentView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.35)

            moonImageView.tintColor = .white.withAlphaComponent(0.9)

            titleLabel.text = "Sleeping"
            titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
            titleLabel.textColor = .white.withAlphaComponent(0.85)

            timeLabel.isHidden = false
            timeLabel.text = elapsedText
            timeLabel.font = .systemFont(ofSize: 56, weight: .bold)
            timeLabel.textColor = .white

            actionButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            actionButton.backgroundColor = .white
            actionButton.tintColor = UIColor.systemOrange.withAlphaComponent(0.9)

            hintLabel.text = "Tap to stop"
            hintLabel.font = .systemFont(ofSize: 16)
            hintLabel.textColor = .white.withAlphaComponent(0.8)
    }
}
}

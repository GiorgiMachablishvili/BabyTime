import UIKit
import SnapKit

// MARK: - LogPastSleepViewController

final class LogPastSleepViewController: UIViewController {

    var onSave: ((SleepSession) -> Void)?

    // MARK: - State
    private var startDate: Date = {
        // Default: 1 hour ago
        Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    }()
    private var endDate: Date = Date()

    // MARK: - Views

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        b.tintColor = UIColor(hexString: "#8b6dc4")
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Log Past Sleep"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(hexString: "#8b6dc4")
        l.textAlignment = .center
        return l
    }()

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.alwaysBounceVertical = true
        return s
    }()
    private lazy var contentView = UIView()

    // Moon hero icon
    private lazy var heroView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.1)
        v.layer.cornerRadius = 18
        return v
    }()
    private lazy var moonIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "moon.stars.fill"))
        iv.tintColor = UIColor(hexString: "#8b6dc4")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // Start
    private lazy var startCard = makePickerCard(title: "Sleep Start")
    private lazy var startPicker: UIDatePicker = makeDatePicker()

    // End
    private lazy var endCard = makePickerCard(title: "Wake Up")
    private lazy var endPicker: UIDatePicker = makeDatePicker()

    // Duration badge
    private lazy var durationCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#8b6dc4").withAlphaComponent(0.08)
        v.layer.cornerRadius = 14
        return v
    }()
    private lazy var durationIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "clock.fill"))
        iv.tintColor = UIColor(hexString: "#8b6dc4")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private lazy var durationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = UIColor(hexString: "#8b6dc4")
        return l
    }()

    // Save
    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor(hexString: "#8b6dc4")
        b.layer.cornerRadius = 16
        b.setTitle("Save Sleep", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Helpers

    private func makePickerCard(title: String) -> UIView {
        let v = UIView()
        v.backgroundColor = .cardBackground
        v.layer.cornerRadius = 14
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        l.tag = 99
        v.addSubview(l)
        l.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
        }
        return v
    }

    private func makeDatePicker() -> UIDatePicker {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = UIColor(hexString: "#8b6dc4")
        dp.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        return dp
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()
        startPicker.date = startDate
        endPicker.date = endDate
        updateDuration()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(heroView)
        heroView.addSubview(moonIcon)

        // Start card
        contentView.addSubview(startCard)
        startCard.addSubview(startPicker)

        // End card
        contentView.addSubview(endCard)
        endCard.addSubview(endPicker)

        // Duration
        contentView.addSubview(durationCard)
        durationCard.addSubview(durationIcon)
        durationCard.addSubview(durationLabel)

        view.addSubview(saveButton)
    }

    private func setupConstraints() {
        let hPad: CGFloat = 20 * Constraint.xCoeff

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(hPad)
            $0.width.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }
        scrollView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(saveButton.snp.top).offset(-12 * Constraint.xCoeff)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Hero
        heroView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(120 * Constraint.xCoeff)
        }
        moonIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(52 * Constraint.xCoeff)
        }

        // Start card
        startCard.snp.makeConstraints {
            $0.top.equalTo(heroView.snp.bottom).offset(20 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(70 * Constraint.xCoeff)
        }
        startPicker.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }

        // End card
        endCard.snp.makeConstraints {
            $0.top.equalTo(startCard.snp.bottom).offset(12 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(70 * Constraint.xCoeff)
        }
        endPicker.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }

        // Duration
        durationCard.snp.makeConstraints {
            $0.top.equalTo(endCard.snp.bottom).offset(16 * Constraint.xCoeff)
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.height.equalTo(52 * Constraint.xCoeff)
            $0.bottom.equalToSuperview().inset(24 * Constraint.xCoeff)
        }
        durationIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(18)
        }
        durationLabel.snp.makeConstraints {
            $0.leading.equalTo(durationIcon.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
        }

        // Save
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(hPad)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16 * Constraint.xCoeff)
            $0.height.equalTo(54 * Constraint.xCoeff)
        }
    }

    // MARK: - Logic

    @objc private func dateChanged(_ sender: UIDatePicker) {
        if sender === startPicker {
            startDate = sender.date
            // If end is before start, push end forward
            if endDate <= startDate {
                endDate = startDate.addingTimeInterval(3600)
                endPicker.setDate(endDate, animated: true)
            }
        } else {
            endDate = sender.date
            // If end is before start, pull start back
            if startDate >= endDate {
                startDate = endDate.addingTimeInterval(-3600)
                startPicker.setDate(startDate, animated: true)
            }
        }
        updateDuration()
    }

    private func updateDuration() {
        let seconds = endDate.timeIntervalSince(startDate)
        guard seconds > 0 else {
            durationLabel.text = "Invalid range"
            saveButton.alpha = 0.5
            saveButton.isEnabled = false
            return
        }
        saveButton.alpha = 1
        saveButton.isEnabled = true
        let h = Int(seconds / 3600)
        let m = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if h > 0 {
            durationLabel.text = "Duration: \(h)h \(m)m"
        } else {
            durationLabel.text = "Duration: \(m)m"
        }
    }

    // MARK: - Actions

    @objc private func backTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        guard endDate > startDate else { return }
        let session = SleepSession(start: startDate, end: endDate)
        onSave?(session)
        dismiss(animated: true)
    }
}

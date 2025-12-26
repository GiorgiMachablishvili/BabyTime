import UIKit
import SnapKit

final class SleepViewController: UIViewController {

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self

        cv.register(SleepTimerCell.self, forCellWithReuseIdentifier: "SleepTimerCell")
        cv.register(SleepHistoryTitleCell.self, forCellWithReuseIdentifier: "SleepHistoryTitleCell")
        cv.register(SleepHistoryCell.self, forCellWithReuseIdentifier: "SleepHistoryCell")
        return cv
    }()

    // MARK: - Timer state
    private var timer: Timer?
    private var sleepStartDate: Date?
    private var sessions: [SleepSession] = []
    private var isTimerExpanded: Bool = false

    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        return df
    }()

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor

        setupUI()
        setupConstraints()

        sectionHeaderView.configure(
            title: "Sleep Tracker",
            subtitle: "Monitor your baby's sleep",
            showsPlusButton: false
        )
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(120 * Constraint.xCoeff)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(sectionHeaderView.snp.bottom).offset(10 * Constraint.xCoeff)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func startSleep() {
        guard timer == nil else { return }
        sleepStartDate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // update only timer cell
            self?.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }
        RunLoop.main.add(timer!, forMode: .common)

        isTimerExpanded = true
        collectionView.performBatchUpdates({
            collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }, completion: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func stopSleep() {
        guard let start = sleepStartDate else { return }

        timer?.invalidate()
        timer = nil

        let end = Date()
        sleepStartDate = nil

        let session = SleepSession(start: start, end: end)
        sessions.insert(session, at: 0)

        // reload timer cell + insert history cell
        isTimerExpanded = false
        collectionView.performBatchUpdates({
            collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
            collectionView.insertItems(at: [IndexPath(item: 0, section: 2)])
        }, completion: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func elapsedText() -> String {
        guard let start = sleepStartDate else { return "0:00" }
        let total = Int(Date().timeIntervalSince(start))
        let mins = total / 60
        let secs = total % 60
        return "\(mins):" + String(format: "%02d", secs)
    }

    deinit {
        timer?.invalidate()
    }
}

extension SleepViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return sessions.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SleepTimerCell", for: indexPath) as! SleepTimerCell

            if sleepStartDate == nil {
                cell.render(.idle)
            } else {
                cell.render(.running(elapsedText: elapsedText()))
            }

            cell.onTapStart = { [weak self] in self?.startSleep() }
            cell.onTapStop = { [weak self] in self?.stopSleep() }

            return cell

        case 1:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "SleepHistoryTitleCell", for: indexPath)

        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SleepHistoryCell", for: indexPath) as! SleepHistoryCell
            let session = sessions[indexPath.item]

            let timeText = timeFormatter.string(from: session.end)
            let dateText = dateFormatter.string(from: session.end)

            let durationSeconds = Int(session.end.timeIntervalSince(session.start))
            let durationMinutes = max(1, durationSeconds / 60)
            let statusText = "sleep time: \(durationMinutes) min"
            cell.configure(statusText: statusText, timeText: timeText, dateText: dateText)
            return cell

        default:
            return UICollectionViewCell()
        }
    }
}

extension SleepViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.bounds.width - 32 // 16 left + 16 right

        switch indexPath.section {
        case 0:
            return CGSize(width: width, height: isTimerExpanded ? 340 : 260)
        case 1:
            return CGSize(width: width, height: 44)
        case 2:
            return CGSize(width: width, height: 98)
        default:
            return CGSize(width: width, height: 44)
        }
    }
}

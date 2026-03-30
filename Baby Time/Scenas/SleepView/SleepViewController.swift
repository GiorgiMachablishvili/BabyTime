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

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self

        view.register(SleepTimerCell.self, forCellWithReuseIdentifier: "SleepTimerCell")
        view.register(SleepHistoryTitleCell.self, forCellWithReuseIdentifier: "SleepHistoryTitleCell")
        view.register(SleepHistoryCell.self, forCellWithReuseIdentifier: "SleepHistoryCell")
        view.register(SleepDayHeaderCell.self, forCellWithReuseIdentifier: SleepDayHeaderCell.reuseId)
        return view
    }()

    // MARK: - Timer state
    private var timer: Timer?
    private var sleepStartDate: Date?
    private var sessions: [SleepSession] = []

    private enum SessionRow: Hashable {
        case header(String)
        case session(UUID)
    }
    private var sessionRows: [SessionRow] = []
    private var sessionById: [UUID: SleepSession] = [:]

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
        sessions = SleepSessionStore.load()
        rebuildSessionRows()

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
            self?.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }
        RunLoop.main.add(timer!, forMode: .common)

        collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }

    private func stopSleep() {
        guard let start = sleepStartDate else { return }

        timer?.invalidate()
        timer = nil

        let end = Date()
        sleepStartDate = nil

        let session = SleepSession(start: start, end: end)
        sessions.insert(session, at: 0)
        SleepSessionStore.save(sessions)
        rebuildSessionRows()

        collectionView.performBatchUpdates({
            collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
            collectionView.reloadSections(IndexSet(integer: 2))
        })
    }

    private func elapsedText() -> String {
        guard let start = sleepStartDate else { return "0:00" }
        let total = Int(Date().timeIntervalSince(start))
        let mins = total / 60
        let secs = total % 60
        return "\(mins):" + String(format: "%02d", secs)
    }

    private func deleteSleepSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        SleepSessionStore.save(sessions)
        rebuildSessionRows()
        collectionView.reloadSections(IndexSet(integer: 2))
    }

    private func rebuildSessionRows() {
        sessionById = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
        var rows: [SessionRow] = []
        var lastHeader: String?
        for s in sessions.sorted(by: { $0.end > $1.end }) {
            let header = dateFormatter.string(from: s.end)
            if header != lastHeader {
                rows.append(.header(header))
                lastHeader = header
            }
            rows.append(.session(s.id))
        }
        sessionRows = rows
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
        case 2: return sessionRows.count
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
            let row = sessionRows[indexPath.item]
            switch row {
            case .header(let title):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SleepDayHeaderCell.reuseId, for: indexPath) as! SleepDayHeaderCell
                cell.configure(title: title)
                return cell
            case .session(let id):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SleepHistoryCell", for: indexPath) as! SleepHistoryCell
                if let session = sessionById[id] {
                    let timeText = timeFormatter.string(from: session.end)
                    let durationSeconds = Int(session.end.timeIntervalSince(session.start))
                    let durationMinutes = max(1, durationSeconds / 60)
                    let statusText = "sleep time: \(durationMinutes) min"
                    cell.configure(statusText: statusText, timeText: timeText, dateText: "")
                    cell.onDelete = { [weak self] in
                        self?.deleteSleepSession(id: id)
                    }
                }
                return cell
            }

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
            return CGSize(width: width, height: 340)
        case 1:
            return CGSize(width: width, height: 44)
        case 2:
            switch sessionRows[indexPath.item] {
            case .header:
                return CGSize(width: collectionView.bounds.width, height: 44)
            case .session:
                return CGSize(width: width, height: 100)
            }
        default:
            return CGSize(width: width, height: 44)
        }
    }
}

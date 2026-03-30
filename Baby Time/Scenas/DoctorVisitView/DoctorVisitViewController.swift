import UIKit
import SnapKit

final class DoctorVisitViewController: UIViewController {

    private var visits: [VisitReminder] = []
    private let kind: VisitReminder.Kind = .doctorVisit

    private lazy var sectionHeaderView: VisitSectionHeaderView = {
        let view = VisitSectionHeaderView()
        view.onTapPlus = { [weak self] in
            self?.presentAddDoctorVisit()
        }
        view.onTapCalendar = { [weak self] in
            self?.presentCalendar()
        }
        return view
    }()

    private lazy var addDoctorVisitView: AddDoctorVisitView = {
        let view = AddDoctorVisitView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.addDoctorVisitView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.addDoctorVisitView.isHidden = true
            }
        }
        return view
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8 * Constraint.xCoeff
        layout.sectionInset = UIEdgeInsets(top: 8 * Constraint.xCoeff, left: 8 * Constraint.yCoeff, bottom: 8 * Constraint.xCoeff, right: 8 * Constraint.yCoeff)
        layout.estimatedItemSize = CGSize(width: 374 * Constraint.yCoeff, height: 88 * Constraint.xCoeff)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(VisitReminderCell.self, forCellWithReuseIdentifier: VisitReminderCell.reuseId)
        view.isScrollEnabled = true
        view.alwaysBounceVertical = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        loadVisits()
        setupUI()
        setupConstraints()
        configureViews()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadVisits()
        collectionView.reloadData()
        updateEmptyState()
    }

    private func loadVisits() {
        visits = VisitReminderStore.load(kind: kind)
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(emptyStateView)
        view.addSubview(collectionView)
        view.addSubview(addDoctorVisitView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }
        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10 * Constraint.xCoeff)
            make.leading.trailing.equalToSuperview().inset(24 * Constraint.yCoeff)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        addDoctorVisitView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Doctor Visit",
            subtitle: "Reminders & visits",
            showsPlusButton: true,
            plusColor: .growthViewColor,
            showsCalendarButton: true,
            calendarColor: .growthViewColor
        )
        emptyStateView.configure(
            icon: UIImage(systemName: "stethoscope"),
            iconTint: .growthViewColor.withAlphaComponent(0.95),
            circleColor: .growthViewColor.withAlphaComponent(0.40),
            title: "No doctor visits yet",
            subtitle: "Tap the + to add a visit or calendar for reminders"
        )
    }

    private func presentAddDoctorVisit() {
        addDoctorVisitView.isHidden = false
        addDoctorVisitView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        addDoctorVisitView.onTapSave = { [weak self] visitDate, hour, minute, note in
            guard let self else { return }
            let visit = VisitReminder(
                visitDate: visitDate,
                note: note,
                notifyDaysBefore: [1],
                kind: self.kind,
                hour: hour,
                minute: minute
            )
            self.saveVisit(visit)
        }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) {
            self.addDoctorVisitView.transform = .identity
        }
    }

    private func updateEmptyState() {
        let hasContent = !visits.isEmpty
        emptyStateView.isHidden = hasContent
        collectionView.isHidden = !hasContent
    }

    private func presentCalendar() {
        if #available(iOS 16.0, *) {
            let vc = VisitCalendarViewController()
            vc.kind = kind
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
            return
        }
        presentEdit(forDate: Date())
    }

    private func presentEdit(forDate: Date? = nil, visit: VisitReminder? = nil) {
        VisitReminderNotificationManager.requestAuthorization { [weak self] granted in
            guard let self else { return }
            if !granted {
                let alert = UIAlertController(title: "Notifications Off", message: "Enable notifications in Settings to get reminders.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            let vc = VisitEditViewController()
            vc.kind = self.kind
            vc.visit = visit
            vc.forDate = forDate
            vc.onSave = { [weak self] updated in
                self?.saveVisit(updated)
            }
            vc.onDelete = { [weak self] id in
                self?.deleteVisit(id: id)
            }
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
    }

    private func saveVisit(_ visit: VisitReminder) {
        if let idx = visits.firstIndex(where: { $0.id == visit.id }) {
            visits[idx] = visit
        } else {
            visits.append(visit)
        }
        visits.sort { $0.visitDayTimestamp < $1.visitDayTimestamp }
        VisitReminderStore.save(visits, kind: kind)
        VisitReminderNotificationManager.schedule(visit)
        collectionView.reloadData()
        updateEmptyState()
    }

    private func deleteVisit(id: UUID) {
        visits.removeAll { $0.id == id }
        VisitReminderStore.save(visits, kind: kind)
        VisitReminderNotificationManager.unschedule(visitId: id, kind: kind)
        collectionView.reloadData()
        updateEmptyState()
    }

    private func deleteVisitAtIndex(_ indexPath: IndexPath) {
        guard indexPath.item < visits.count else { return }
        let visit = visits[indexPath.item]
        visits.remove(at: indexPath.item)
        VisitReminderStore.save(visits, kind: kind)
        VisitReminderNotificationManager.unschedule(visitId: visit.id, kind: kind)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
        } completion: { [weak self] _ in
            self?.updateEmptyState()
        }
    }
}

extension DoctorVisitViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visits.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VisitReminderCell.reuseId, for: indexPath) as! VisitReminderCell
        let visit = visits[indexPath.item]
        cell.configure(visit: visit, accentColor: .growthViewColor)
        cell.onTap = { [weak self] in
            self?.presentEdit(visit: visit)
        }
        cell.onDelete = { [weak self] in
            self?.deleteVisitAtIndex(indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 16 * Constraint.yCoeff
        return CGSize(width: width, height: 88 * Constraint.xCoeff)
    }
}

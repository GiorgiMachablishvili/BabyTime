import UIKit
import SnapKit

class FeedingViewController: UIViewController {

    private var items: [FeedingViewCell.ViewModel] = []

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        view.onTapPlus = { [weak self] in
            guard let self else { return }
            feedingActionCardButtonPressed()
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
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.estimatedItemSize = CGSize(width: 374, height: 84)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(FeedingViewCell.self, forCellWithReuseIdentifier: "FeedingViewCell")
        cv.isHidden = true
        cv.isScrollEnabled = true
        cv.alwaysBounceVertical = true
        return cv
    }()

    private lazy var feedingView: FeedingView = {
        let view = FeedingView()
        view.isHidden = true
        view.onTapCloseButton = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.feedingView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: { _ in
                self.feedingView.isHidden = true
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .viewsBackGourdColor

        setupUI()
        setupConstraints()
        configureViews()

        emptyStateView.isHidden = !items.isEmpty
        collectionView.isHidden = items.isEmpty
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(emptyStateView)
        view.addSubview(collectionView)
        view.addSubview(feedingView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }

        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10) // small visual tweak
            make.leading.trailing.equalToSuperview().inset(24)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        feedingView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Feeding Log",
            subtitle: "Track your baby's meals",
            showsPlusButton: true,
            plusColor: .feedingViewColor
        )

        emptyStateView.configure(
            icon: UIImage(systemName: "fork.knife"),
            iconTint: .feedingViewColor.withAlphaComponent(0.95),
            circleColor: .feedingViewColor.withAlphaComponent(0.40),
            title: "No feedings yet",
            subtitle: "Tap the + button to log a feeding"
        )

        feedingView.onTapSave = { [weak self] type, volume, notes, time, date in
            guard let self = self else { return }
            let vmType: FeedingViewCell.ViewModel.FeedingType
            switch type {
            case .breast: vmType = .breast
            case .bottle: vmType = .bottle
            case .formula: vmType = .formula
            case .solid: vmType = .solid
            }
            let vm = FeedingViewCell.ViewModel(type: vmType, volumeText: volume, notesText: notes, timeText: time, dateText: date)
            self.items.insert(vm, at: 0)
            self.collectionView.reloadData()
            self.emptyStateView.isHidden = !self.items.isEmpty
            self.collectionView.isHidden = self.items.isEmpty
        }
    }

    @objc private func feedingActionCardButtonPressed() {
        feedingView.isHidden = false
        // Reset starting position off-screen
        feedingView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) {
            self.feedingView.transform = .identity
        }
    }

}

extension FeedingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeedingViewCell", for: indexPath) as! FeedingViewCell
        let vm = items[indexPath.item]
        cell.configure(with: vm)
        cell.onDelete = { [weak self] in
            self?.deleteItem(at: indexPath)
        }
        return cell
    }

    private func deleteItem(at indexPath: IndexPath) {
        guard indexPath.item < items.count else { return }
        items.remove(at: indexPath.item)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
        } completion: { [weak self] _ in
            self?.emptyStateView.isHidden = !(self?.items.isEmpty == false)
            self?.collectionView.isHidden = self?.items.isEmpty ?? true
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 16, height: 84)
    }
}

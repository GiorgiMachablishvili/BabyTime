

import UIKit
import SnapKit

final class SettingsViewController: UIViewController {

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        return view
    }()

    private enum Item: Int, CaseIterable {
        case babyProfile
        case notifications
        case exportData
        case darkMode

        var title: String {
            switch self {
            case .babyProfile: return "Baby Profile"
            case .notifications: return "Notifications"
            case .exportData: return "Export Data"
            case .darkMode: return "Dark Mode"
            }
        }

        var subtitle: String? {
            switch self {
            case .babyProfile: return nil
            case .notifications, .exportData, .darkMode: return "Coming soon"
            }
        }

        var iconName: String {
            switch self {
            case .babyProfile: return "person"
            case .notifications: return "bell"
            case .exportData: return "square.and.arrow.up"
            case .darkMode: return "moon"
            }
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 28, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self

        cv.register(BabyProfileCell.self, forCellWithReuseIdentifier: BabyProfileCell.reuseId)
        cv.register(SettingsRowCell.self, forCellWithReuseIdentifier: SettingsRowCell.reuseId)

        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .viewsBackGourdColor

        setupUI()
        setupConstraints()
        configureViews()
    }

    private func setupUI() {
        view.addSubview(sectionHeaderView)
        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        sectionHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(sectionHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Settings",
            subtitle: "Manage your app preferences",
            showsPlusButton: false
        )
    }
}

extension SettingsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Item.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = Item(rawValue: indexPath.item)!

        switch item {
        case .babyProfile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BabyProfileCell.reuseId,
                for: indexPath
            ) as! BabyProfileCell

            cell.configure(
                title: "Baby Profile",
                icon: UIImage(systemName: item.iconName)
            )

            cell.onTapSave = { [weak self] name, birthday, gender in
                // Here you can save to UserDefaults/CoreData
                print("Save Profile:", name ?? "-", birthday ?? "-", gender)
                self?.view.endEditing(true)
            }

            return cell

        case .notifications, .exportData, .darkMode:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SettingsRowCell.reuseId,
                for: indexPath
            ) as! SettingsRowCell

            cell.configure(
                icon: UIImage(systemName: item.iconName),
                title: item.title,
                subtitle: item.subtitle
            )
            return cell
        }
    }
}

extension SettingsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.bounds.width - 32 // 16 + 16 insets
        let item = Item(rawValue: indexPath.item)!

        switch item {
        case .babyProfile:
            return CGSize(width: width, height: 360)
        case .notifications, .exportData, .darkMode:
            return CGSize(width: width, height: 78)
        }
    }
}


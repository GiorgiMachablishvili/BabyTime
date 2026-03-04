import UIKit
import SnapKit

final class SettingsViewController: UIViewController {

    private var profileImage: UIImage?

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
            make.height.equalTo(130 * Constraint.xCoeff)
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

    private func showProfilePhotoOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.openImagePicker(sourceType: .camera)
        })
        alert.addAction(UIAlertAction(title: "Use Gallery", style: .default) { [weak self] _ in
            self?.openImagePicker(sourceType: .photoLibrary)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            let message = (sourceType == .camera) ? "Camera is not available." : "Photo library is not available."
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
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
                icon: UIImage(systemName: item.iconName),
                profileImage: profileImage
            )

            cell.onTapSave = { [weak self] name, birthday, gender in
                print("Save Profile:", name ?? "-", birthday ?? "-", gender)
                self?.view.endEditing(true)
            }

            cell.onTapProfilePhoto = { [weak self] in
                self?.showProfilePhotoOptions()
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

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        profileImage = image
        collectionView.reloadItems(at: [IndexPath(item: Item.babyProfile.rawValue, section: 0)])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


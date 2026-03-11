import UIKit
import SnapKit

final class VaccinationViewController: UIViewController {

    private lazy var backButton: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle(" Back", for: .normal)
        view.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        view.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vaccination"
        view.backgroundColor = .viewsBackGourdColor
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        view.addSubview(backButton)
    }

    private func setupConstraints() {
        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16 * Constraint.xCoeff)
            $0.leading.equalToSuperview().offset(20 * Constraint.yCoeff)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

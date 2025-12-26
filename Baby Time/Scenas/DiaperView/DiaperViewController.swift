

import UIKit
import SnapKit

class DiaperViewController: UIViewController {

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        return view
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
    }

    private func setupConstraints() {
        sectionHeaderView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120 * Constraint.xCoeff)
        }
    }

    private func configureViews() {
        sectionHeaderView.configure(
            title: "Diaper Log",
            subtitle: "Track diaper changes",
            showsPlusButton: true,
            plusColor: .diaperViewColor
        )
    }
}

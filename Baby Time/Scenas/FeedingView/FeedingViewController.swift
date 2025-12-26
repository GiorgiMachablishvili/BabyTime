

import UIKit
import SnapKit

class FeedingViewController: UIViewController {

    private lazy var sectionHeaderView: SectionHeaderView = {
        let view = SectionHeaderView()
        return view
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
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
        view.addSubview(emptyStateView)
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
    }

}

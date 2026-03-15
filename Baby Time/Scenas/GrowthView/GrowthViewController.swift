import UIKit
import SwiftUI

final class GrowthViewController: UIViewController {

    private let viewModel = GrowthComparisonViewModel()
    private var hostingController: UIHostingController<GrowthMainView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewsBackGourdColor
        embedSwiftUI()
    }

    private func embedSwiftUI() {
        let mainView = GrowthMainView(viewModel: viewModel)
        let host = UIHostingController(rootView: mainView)
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        hostingController = host
    }
}

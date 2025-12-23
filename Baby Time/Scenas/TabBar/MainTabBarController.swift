

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureAppearance()
    }

    private func setupTabs() {
        let home = createNav(
            vc: MainViewController(),
            title: "Home",
            image: "house"
        )

        let feeding = createNav(
            vc: FeedingViewController(),
            title: "Feeding",
            image: "fork.knife"
        )

        let sleep = createNav(
            vc: SleepViewController(),
            title: "Sleep",
            image: "moon"
        )

        let diaper = createNav(
            vc: DiaperViewController(),
            title: "Diaper",
            image: "figure.child.circle"
        )

        let settings = createNav(
            vc: SettingsViewController(),
            title: "Settings",
            image: "gear"
        )

        viewControllers = [home, feeding, sleep, diaper, settings]
    }

    private func createNav(vc: UIViewController, title: String, image: String) -> UINavigationController {
//        vc.title = title
        vc.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: UIImage(named: image)
        )
        return UINavigationController(rootViewController: vc)
    }

    private func configureAppearance() {
        tabBar.tintColor = .black
        tabBar.backgroundColor = .clear
    }
}


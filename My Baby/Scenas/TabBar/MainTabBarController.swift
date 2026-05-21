

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

        let feed = createNav(
            vc: FeedingViewController(),
            title: "Feed",
            image: "fork.knife"
        )

        let sleep = createNav(
            vc: SleepViewController(),
            title: "Sleep",
            image: "moon"
        )

        let diaper = createNav(
            vc: DiaperViewController(),
            title: "Diapers",
            image: "drop.fill"
        )

        let more = createNav(
            vc: SettingsViewController(),
            title: "More",
            image: "ellipsis"
        )

        viewControllers = [home, feed, sleep, diaper, more]
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


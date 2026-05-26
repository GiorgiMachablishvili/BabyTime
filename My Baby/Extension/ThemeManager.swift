import UIKit

// MARK: - ThemeManager

final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    private let key = "app_dark_mode_enabled"

    var isDarkMode: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            applyToAllWindows()
        }
    }

    /// Call once at launch (SceneDelegate) to restore saved preference.
    func applyToAllWindows() {
        let style: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

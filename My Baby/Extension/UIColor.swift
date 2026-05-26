import UIKit

// MARK: - Palette
// Light  → warm cream    Dark  → #1C1C19 (design "Neutral")
// Primary accent          → #C6B4FE (design "Primary")
// Secondary accent        → #34D399 (design "Secondary")

extension UIColor {

    // MARK: - Adaptive background (main app bg)
    static let viewsBackGourdColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexString: "#1C1C19")
            : UIColor(hexString: "#fffae7")
    }

    // MARK: - Adaptive card / field backgrounds
    /// Use on cards, modals, sheets
    static let cardBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexString: "#252522")
            : UIColor.white
    }

    /// Use on text fields, input areas
    static let fieldBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexString: "#2D2D2A")
            : UIColor(hexString: "#f5f5f5")
    }

    // MARK: - Brand / accent colours (design palette)
    /// Primary: #C6B4FE  — soft lavender purple
    static let brandPrimary   = UIColor(hexString: "#C6B4FE")
    /// Secondary: #34D399 — mint green
    static let brandSecondary = UIColor(hexString: "#34D399")
    /// Tertiary: #CACF66 — lime yellow
    static let brandTertiary  = UIColor(hexString: "#CACF66")

    // MARK: - Legacy (kept for backward compat)
    static let buttonGayColor        = UIColor(hexString: "#F2F2F2")
    static let pressButtonColor      = UIColor(hexString: "#e3ba91")
    static let pressButtonTitleColor = UIColor(hexString: "#969696")
    static let buttonTitleColor      = UIColor(hexString: "#525252")
    static let blackColor            = UIColor(hexString: "#000000")
    static let feedingViewColor      = UIColor(hexString: "#f0b7a5")
    static let sleepViewColor        = UIColor(hexString: "#e8b5f5")
    static let diaperViewColor       = UIColor(hexString: "#bdf0c2")
    static let growthViewColor       = UIColor(hexString: "#82dbed")
    static let labelWhiteColor       = UIColor(hexString: "#FFFFFF")
    static let orangeColor           = UIColor(hexString: "#F28C28")
}

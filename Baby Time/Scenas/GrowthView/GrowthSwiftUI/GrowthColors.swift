import SwiftUI

enum GrowthColors {
    static let background = Color(red: 1, green: 0.98, blue: 0.91) // #fffae7
    static let cardBackground = Color.white
    static let growthTeal = Color(red: 0.51, green: 0.86, blue: 0.93) // #82dbed
    static let textPrimary = Color(red: 0.32, green: 0.32, blue: 0.32)
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let accent = Color(red: 0.51, green: 0.86, blue: 0.93)

    /// Skin tone options for avatar (hex → RGB).
    static let skinTones: [Color] = [
        Color(red: 1, green: 0.88, blue: 0.74),   // #FFE0BD
        Color(red: 0.95, green: 0.76, blue: 0.49),
        Color(red: 0.88, green: 0.67, blue: 0.41),
        Color(red: 0.78, green: 0.53, blue: 0.26),
        Color(red: 0.55, green: 0.33, blue: 0.14),
        Color(red: 0.36, green: 0.2, blue: 0.09),
    ]
}

import ActivityKit
import Foundation

// Shared between the main app target and the SleepTimerWidget extension.
// In Xcode → select this file → File Inspector → Target Membership → tick both targets.

struct BreastTimerAttributes: ActivityAttributes {

    // Live-updating fields
    public struct ContentState: Codable, Hashable {
        /// The moment breastfeeding started – used by SwiftUI's `.timer` Text style for auto-counting
        var startTime: Date
        var side: String        // "L" or "R"
        var babyName: String
    }

    // Static fields (set once at start)
    var sessionID: String
}

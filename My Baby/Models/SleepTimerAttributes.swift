import ActivityKit
import Foundation

// Shared between the main app target and the SleepTimerWidget extension.
// In Xcode → select this file → File Inspector → Target Membership → tick both targets.

struct SleepTimerAttributes: ActivityAttributes {

    // Live-updating fields (can change while the activity runs)
    public struct ContentState: Codable, Hashable {
        /// The moment sleep started – used by SwiftUI's `.timer` Text style for auto-counting
        var startTime: Date
        var babyName: String
    }

    // Static fields (set once at start, never change)
    var sessionID: String          // for deduplication
}

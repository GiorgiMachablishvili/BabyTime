

import Foundation

struct SleepSession {
    let start: Date
    let end: Date
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

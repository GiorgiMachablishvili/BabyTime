import WidgetKit
import SwiftUI

@main
struct SleepTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepTimerLiveActivity()
        BreastTimerLiveActivity()
    }
}

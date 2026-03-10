import SwiftUI

@main
struct ExpenseTrackerApp: App {
    init() {
        Telemetry.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

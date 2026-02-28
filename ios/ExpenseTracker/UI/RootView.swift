import SwiftUI

/// Simple routing sample for MVP-0.
struct RootView: View {
    enum Route: Hashable {
        case settings
    }

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                store: LocalStore.shared.expenseStore,
                onOpenSettings: { path.append(.settings) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .settings:
                    SettingsView(
                        categoryStore: LocalStore.shared.categoryStore,
                        subscriptionStore: LocalStore.shared.subscriptionStore,
                        installmentStore: LocalStore.shared.installmentStore,
                        expenseStore: LocalStore.shared.expenseStore
                    )
                }
            }
        }
    }
}

#Preview {
    RootView()
}

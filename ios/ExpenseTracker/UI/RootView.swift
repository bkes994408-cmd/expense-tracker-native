import SwiftUI

/// Simple routing sample for MVP-0.
struct RootView: View {
    enum Route: Hashable {
        case settings
    }

    @State private var path: [Route] = []
    @StateObject private var authViewModel = AuthViewModel(service: LocalStore.shared.authService)

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                appContent
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
    }

    private var appContent: some View {
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
                        installmentStore: LocalStore.shared.installmentStore
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("登出") { authViewModel.logout() }
                }
            }
        }
    }
}

#Preview {
    RootView()
}

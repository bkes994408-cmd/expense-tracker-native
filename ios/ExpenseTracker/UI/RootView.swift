import SwiftUI

struct RootView: View {
    enum Route: Hashable {
        case add
    }

    @MainActor
    final class StoreHolder: ObservableObject {
        let repository: TransactionRepository?
        @Published var errorMessage: String?

        init() {
            do {
                self.repository = try LocalStore()
                self.errorMessage = nil
            } catch {
                self.repository = nil
                self.errorMessage = String(describing: error)
            }
        }
    }

    @StateObject private var holder = StoreHolder()
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            if let repository = holder.repository {
                HomeView(repository: repository) {
                    path.append(.add)
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .add:
                        AddTransactionView(repository: repository, onSaved: {})
                    }
                }
            } else {
                Text("Failed to open database")
                    .foregroundStyle(.secondary)
                    .navigationTitle("Home")
            }
        }
        .alert(
            "DB Error",
            isPresented: Binding(
                get: { holder.errorMessage != nil },
                set: { _ in holder.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(holder.errorMessage ?? "")
        }
    }
}

#Preview {
    RootView()
}

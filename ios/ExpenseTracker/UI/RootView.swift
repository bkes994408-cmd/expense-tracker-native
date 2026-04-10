import SwiftUI

struct RootView: View {
    @StateObject private var proEntitlementStore = ProEntitlementStore()
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack {
            HomeView(
                store: LocalStore.shared.expenseStore,
                budgetStore: LocalStore.shared.budgetStore,
                groupLedgerStore: LocalStore.shared.groupLedgerStore,
                categoryStore: LocalStore.shared.categoryStore,
                proEntitlementStore: proEntitlementStore,
                initialTab: .dashboard,
                onOpenSettings: { isSettingsPresented = true }
            )
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                SettingsView(
                    categoryStore: LocalStore.shared.categoryStore,
                    subscriptionStore: LocalStore.shared.subscriptionStore,
                    installmentStore: LocalStore.shared.installmentStore,
                    expenseStore: LocalStore.shared.expenseStore,
                    proEntitlementStore: proEntitlementStore
                )
            }
        }
        .task {
            LocalStore.shared.performInitialSyncPullIfNeeded()
        }
    }
}

#Preview {
    RootView()
}

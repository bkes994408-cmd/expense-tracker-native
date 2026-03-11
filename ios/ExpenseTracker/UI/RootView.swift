import SwiftUI
import Foundation

@MainActor
final class ProEntitlementStore: ObservableObject {
    enum Tier: String {
        case free
        case monthly
        case yearly
        case trial

        var isPro: Bool { self != .free }
    }

    @Published private(set) var tier: Tier
    @Published private(set) var source: String

    private let defaults: UserDefaults
    private let tierKey = "pro.entitlement.tier"
    private let sourceKey = "pro.entitlement.source"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.tier = Tier(rawValue: defaults.string(forKey: tierKey) ?? "") ?? .free
        self.source = defaults.string(forKey: sourceKey) ?? "none"
    }

    var isPro: Bool { tier.isPro }

    func startTrial() { update(tier: .trial, source: "paywall_trial") }
    func subscribeMonthly() { update(tier: .monthly, source: "paywall_monthly") }
    func subscribeYearly() { update(tier: .yearly, source: "paywall_yearly") }
    func restorePurchase() { if tier == .free { update(tier: .monthly, source: "restore_purchase") } }
    func resetToFreeForDebug() { update(tier: .free, source: "debug_reset") }

    private func update(tier: Tier, source: String) {
        self.tier = tier
        self.source = source
        defaults.set(tier.rawValue, forKey: tierKey)
        defaults.set(source, forKey: sourceKey)
    }
}

/// Simple routing sample for MVP-0.
struct RootView: View {
    enum Route: Hashable {
        case settings
    }

    @State private var path: [Route] = []
    @StateObject private var proEntitlementStore = ProEntitlementStore()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                store: LocalStore.shared.expenseStore,
                budgetStore: LocalStore.shared.budgetStore,
                proEntitlementStore: proEntitlementStore,
                onOpenSettings: { path.append(.settings) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .settings:
                    SettingsView(
                        categoryStore: LocalStore.shared.categoryStore,
                        subscriptionStore: LocalStore.shared.subscriptionStore,
                        installmentStore: LocalStore.shared.installmentStore,
                        expenseStore: LocalStore.shared.expenseStore,
                        proEntitlementStore: proEntitlementStore
                    )
                }
            }
        }
    }
}

#Preview {
    RootView()
}

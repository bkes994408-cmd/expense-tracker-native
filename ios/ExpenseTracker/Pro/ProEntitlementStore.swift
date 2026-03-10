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
    @Published private(set) var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private let purchaseService: InAppPurchaseService
    private let tierKey = "pro.entitlement.tier"
    private let sourceKey = "pro.entitlement.source"

    init(
        defaults: UserDefaults = .standard,
        purchaseService: InAppPurchaseService = StoreKitPurchaseService()
    ) {
        self.defaults = defaults
        self.purchaseService = purchaseService
        self.tier = Tier(rawValue: defaults.string(forKey: tierKey) ?? "") ?? .free
        self.source = defaults.string(forKey: sourceKey) ?? "none"
    }

    var isPro: Bool { tier.isPro }

    func startTrial() async {
        await runPurchase(source: "paywall_trial") {
            try await purchaseService.purchase(plan: .trial)
        }
    }

    func subscribeMonthly() async {
        await runPurchase(source: "paywall_monthly") {
            try await purchaseService.purchase(plan: .monthly)
        }
    }

    func subscribeYearly() async {
        await runPurchase(source: "paywall_yearly") {
            try await purchaseService.purchase(plan: .yearly)
        }
    }

    func restorePurchase() async {
        await runPurchase(source: "restore_purchase") {
            try await purchaseService.restore() ?? .free
        }
    }

    func resetToFreeForDebug() {
        update(tier: .free, source: "debug_reset")
    }

    private func runPurchase(source: String, action: @escaping () async throws -> Tier) async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        do {
            let purchasedTier = try await action()
            update(tier: purchasedTier, source: source)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isProcessing = false
    }

    private func update(tier: Tier, source: String) {
        self.tier = tier
        self.source = source
        defaults.set(tier.rawValue, forKey: tierKey)
        defaults.set(source, forKey: sourceKey)
    }
}

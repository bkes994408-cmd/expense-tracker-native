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

    enum ProFeature {
        case advancedReportMultiMonth
        case budgetUnlimitedCategories
        case budgetCopyLastMonth
        case reportPdfExport
    }

    struct SubscriptionStatus {
        let tier: Tier
        let source: String
        let lastUpdatedAt: Date?

        var isActive: Bool { tier.isPro }
        var permissionSummary: String {
            isActive ? "Pro 已啟用" : "Free（僅基礎功能）"
        }
    }

    @Published private(set) var tier: Tier
    @Published private(set) var source: String
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private let purchaseService: InAppPurchaseService
    private let tierKey = "pro.entitlement.tier"
    private let sourceKey = "pro.entitlement.source"
    private let updatedAtKey = "pro.entitlement.updatedAt"

    init(
        defaults: UserDefaults = .standard,
        purchaseService: InAppPurchaseService = StoreKitPurchaseService()
    ) {
        self.defaults = defaults
        self.purchaseService = purchaseService
        self.tier = Tier(rawValue: defaults.string(forKey: tierKey) ?? "") ?? .free
        self.source = defaults.string(forKey: sourceKey) ?? "none"
        self.lastUpdatedAt = defaults.object(forKey: updatedAtKey) as? Date
    }

    var isPro: Bool { tier.isPro }

    var subscriptionStatus: SubscriptionStatus {
        SubscriptionStatus(tier: tier, source: source, lastUpdatedAt: lastUpdatedAt)
    }

    func hasAccess(to feature: ProFeature) -> Bool {
        switch feature {
        case .advancedReportMultiMonth,
             .budgetUnlimitedCategories,
             .budgetCopyLastMonth,
             .reportPdfExport:
            return isPro
        }
    }

    func startTrial() async {
        await runPurchase(source: "paywall_trial") {
            try await self.purchaseService.purchase(plan: .trial)
        }
    }

    func subscribeMonthly() async {
        await runPurchase(source: "paywall_monthly") {
            try await self.purchaseService.purchase(plan: .monthly)
        }
    }

    func subscribeYearly() async {
        await runPurchase(source: "paywall_yearly") {
            try await self.purchaseService.purchase(plan: .yearly)
        }
    }

    func restorePurchase() async {
        await runPurchase(source: "restore_purchase") {
            try await self.purchaseService.restore() ?? .free
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
        self.lastUpdatedAt = Date()
        defaults.set(tier.rawValue, forKey: tierKey)
        defaults.set(source, forKey: sourceKey)
        defaults.set(lastUpdatedAt, forKey: updatedAtKey)
    }
}

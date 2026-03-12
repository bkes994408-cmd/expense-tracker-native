import Foundation

@MainActor
final class ProEntitlementStore: ObservableObject {
    enum Tier: String {
        case free
        case monthly
        case yearly
        case trial
    }

    enum Feature {
        case advancedReports
        case pdfExport
        case unlimitedBudgets
        case rolloverBudget
    }

    enum SubscriptionState {
        case free
        case active
        case expired
    }

    @Published private(set) var tier: Tier
    @Published private(set) var source: String
    @Published private(set) var trialExpireAt: Date?
    @Published private(set) var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private let purchaseService: InAppPurchaseService
    private let nowProvider: () -> Date
    private let tierKey = "pro.entitlement.tier"
    private let sourceKey = "pro.entitlement.source"
    private let trialExpireKey = "pro.entitlement.trial.expireAt"

    init(
        defaults: UserDefaults = .standard,
        purchaseService: InAppPurchaseService = StoreKitPurchaseService(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.purchaseService = purchaseService
        self.nowProvider = nowProvider
        self.tier = Tier(rawValue: defaults.string(forKey: tierKey) ?? "") ?? .free
        self.source = defaults.string(forKey: sourceKey) ?? "none"
        self.trialExpireAt = defaults.object(forKey: trialExpireKey) as? Date
    }

    var subscriptionState: SubscriptionState {
        switch tier {
        case .free:
            return .free
        case .monthly, .yearly:
            return .active
        case .trial:
            guard let trialExpireAt else { return .expired }
            return nowProvider() < trialExpireAt ? .active : .expired
        }
    }

    var statusText: String {
        switch subscriptionState {
        case .free: return "Free"
        case .active:
            switch tier {
            case .trial: return "Trial"
            case .monthly: return "Pro（月付）"
            case .yearly: return "Pro（年付）"
            case .free: return "Free"
            }
        case .expired: return "已過期"
        }
    }

    var isPro: Bool { subscriptionState == .active }

    func canAccess(_ feature: Feature) -> Bool {
        switch feature {
        case .advancedReports, .pdfExport, .unlimitedBudgets, .rolloverBudget:
            return isPro
        }
    }

    func startTrial() async {
        await runPurchase(source: "paywall_trial") {
            try await self.purchaseService.purchase(plan: .trial)
        } afterSuccess: { purchasedTier in
            self.update(
                tier: purchasedTier,
                source: "paywall_trial",
                trialExpireAtOverride: purchasedTier == .trial
                    ? Calendar.current.date(byAdding: .day, value: 7, to: self.nowProvider())
                    : nil
            )
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
        } afterSuccess: { restoredTier in
            let restoredTrialExpiry: Date?
            if restoredTier == .trial {
                restoredTrialExpiry = self.trialExpireAt ?? self.nowProvider()
            } else {
                restoredTrialExpiry = nil
            }
            self.update(
                tier: restoredTier,
                source: "restore_purchase",
                trialExpireAtOverride: restoredTrialExpiry
            )
        }
    }

    func resetToFreeForDebug() {
        update(tier: .free, source: "debug_reset", trialExpireAtOverride: nil)
    }

    private func runPurchase(
        source: String,
        action: @escaping () async throws -> Tier,
        afterSuccess: ((Tier) -> Void)? = nil
    ) async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        do {
            let purchasedTier = try await action()
            if let afterSuccess {
                afterSuccess(purchasedTier)
            } else {
                update(tier: purchasedTier, source: source, trialExpireAtOverride: nil)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isProcessing = false
    }

    private func update(tier: Tier, source: String, trialExpireAtOverride: Date?) {
        self.tier = tier
        self.source = source
        self.trialExpireAt = tier == .trial ? trialExpireAtOverride : nil

        defaults.set(tier.rawValue, forKey: tierKey)
        defaults.set(source, forKey: sourceKey)
        defaults.set(self.trialExpireAt, forKey: trialExpireKey)
    }
}

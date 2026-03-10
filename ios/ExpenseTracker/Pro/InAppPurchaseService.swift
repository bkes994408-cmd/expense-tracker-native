import Foundation
import StoreKit

enum ProPlan {
    case trial
    case monthly
    case yearly
}

protocol InAppPurchaseService {
    func purchase(plan: ProPlan) async throws -> ProEntitlementStore.Tier
    func restore() async throws -> ProEntitlementStore.Tier?
}

enum IAPError: LocalizedError {
    case productNotFound
    case userCancelled
    case unverified

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "找不到可購買的商品，請稍後再試。"
        case .userCancelled:
            return "你已取消購買。"
        case .unverified:
            return "交易驗證失敗，請稍後再試。"
        }
    }
}

struct StoreKitPurchaseService: InAppPurchaseService {
    static let monthlyProductId = "com.bkes994408.expensetracker.pro.monthly"
    static let yearlyProductId = "com.bkes994408.expensetracker.pro.yearly"

    func purchase(plan: ProPlan) async throws -> ProEntitlementStore.Tier {
        let productId: String = switch plan {
        case .trial, .yearly: Self.yearlyProductId
        case .monthly: Self.monthlyProductId
        }

        let products = try await Product.products(for: [productId])
        guard let product = products.first else { throw IAPError.productNotFound }
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw IAPError.unverified }
            await transaction.finish()
            return mapProductIdToTier(transaction.productID)
        case .userCancelled, .pending:
            throw IAPError.userCancelled
        @unknown default:
            throw IAPError.unverified
        }
    }

    func restore() async throws -> ProEntitlementStore.Tier? {
        try await AppStore.sync()
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            return mapProductIdToTier(transaction.productID)
        }
        return nil
    }

    private func mapProductIdToTier(_ productId: String) -> ProEntitlementStore.Tier {
        if productId == Self.monthlyProductId { return .monthly }
        if productId == Self.yearlyProductId { return .yearly }
        return .free
    }
}

struct MockInAppPurchaseService: InAppPurchaseService {
    var purchaseResult: Result<ProEntitlementStore.Tier, Error> = .success(.monthly)
    var restoreResult: Result<ProEntitlementStore.Tier?, Error> = .success(nil)

    func purchase(plan: ProPlan) async throws -> ProEntitlementStore.Tier {
        try purchaseResult.get()
    }

    func restore() async throws -> ProEntitlementStore.Tier? {
        try restoreResult.get()
    }
}

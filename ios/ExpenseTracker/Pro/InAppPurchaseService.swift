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

enum IAPError: LocalizedError, Equatable {
    case productNotFound
    case unknownProduct
    case userCancelled
    case pending
    case unverified

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "找不到可購買的商品，請稍後再試。"
        case .unknownProduct:
            return "收到未知商品，請聯繫客服協助處理。"
        case .userCancelled:
            return "你已取消購買。"
        case .pending:
            return "付款正在等待處理中，完成後會自動更新。"
        case .unverified:
            return "交易驗證失敗，請稍後再試。"
        }
    }
}

struct StoreKitPurchaseService: InAppPurchaseService {
    static let trialProductId = "com.bkes994408.expensetracker.pro.trial"
    static let monthlyProductId = "com.bkes994408.expensetracker.pro.monthly"
    static let yearlyProductId = "com.bkes994408.expensetracker.pro.yearly"

    private var supportedProductIds: Set<String> {
        [Self.trialProductId, Self.monthlyProductId, Self.yearlyProductId]
    }

    func purchase(plan: ProPlan) async throws -> ProEntitlementStore.Tier {
        let productId: String = switch plan {
        case .trial: Self.trialProductId
        case .monthly: Self.monthlyProductId
        case .yearly: Self.yearlyProductId
        }

        let products = try await Product.products(for: [productId])
        guard let product = products.first(where: { $0.id == productId }) else { throw IAPError.productNotFound }
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw IAPError.unverified }
            await transaction.finish()
            return try mapProductIdToTier(transaction.productID)
        case .userCancelled:
            throw IAPError.userCancelled
        case .pending:
            throw IAPError.pending
        @unknown default:
            throw IAPError.unverified
        }
    }

    func restore() async throws -> ProEntitlementStore.Tier? {
        try await AppStore.sync()

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard supportedProductIds.contains(transaction.productID) else { continue }
            return try mapProductIdToTier(transaction.productID)
        }

        return nil
    }

    // trial entitlement 僅代表「獨立 trial SKU」。
    // 若是 yearly SKU 的 introductory offer（例如免費試用），entitlement 仍視為 .yearly。
    func mapProductIdToTier(_ productId: String) throws -> ProEntitlementStore.Tier {
        switch productId {
        case Self.trialProductId:
            return .trial
        case Self.monthlyProductId:
            return .monthly
        case Self.yearlyProductId:
            return .yearly
        default:
            throw IAPError.unknownProduct
        }
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

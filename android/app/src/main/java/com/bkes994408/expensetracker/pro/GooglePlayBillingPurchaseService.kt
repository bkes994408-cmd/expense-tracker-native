package com.bkes994408.expensetracker.pro

/**
 * Google Play Billing 的 domain adapter。
 *
 * 這層只處理：
 * 1) Plan <-> ProductId 映射
 * 2) Billing 結果 -> ProTier 映射
 * 3) restore 決策（多筆購買時取最高 tier，未知 productId 會忽略）
 *
 * 真正的 BillingClient 呼叫放在 [GooglePlayBillingGateway]（可替換）。
 */
class GooglePlayBillingPurchaseService(
    private val gateway: GooglePlayBillingGateway,
) : ProPurchaseService {

    override suspend fun purchase(plan: ProPlan): Result<ProTier> {
        val productId = when (plan) {
            ProPlan.TRIAL -> ProductIds.TRIAL
            ProPlan.MONTHLY -> ProductIds.MONTHLY
            ProPlan.YEARLY -> ProductIds.YEARLY
        }

        return gateway.launchPurchase(productId)
            .mapCatching { purchasedProductId -> mapProductIdToTier(purchasedProductId) }
    }

    override suspend fun restore(): Result<ProTier?> {
        return gateway.queryActivePurchases()
            .mapCatching { productIds ->
                val tiers = productIds.mapNotNull { productId ->
                    runCatching { mapProductIdToTier(productId) }.getOrNull()
                }
                tiers.maxByOrNull { it.priority }
            }
    }

    internal fun mapProductIdToTier(productId: String): ProTier {
        return when (productId) {
            ProductIds.TRIAL -> ProTier.TRIAL
            ProductIds.MONTHLY -> ProTier.MONTHLY
            ProductIds.YEARLY -> ProTier.YEARLY
            else -> throw IllegalArgumentException("unknown product: $productId")
        }
    }

    private val ProTier.priority: Int
        get() = when (this) {
            ProTier.FREE -> 0
            ProTier.TRIAL -> 1
            ProTier.MONTHLY -> 2
            ProTier.YEARLY -> 3
        }
}

interface GooglePlayBillingGateway {
    fun launchPurchase(productId: String): Result<String>
    fun queryActivePurchases(): Result<List<String>>
}

object ProductIds {
    const val TRIAL = "com.bkes994408.expensetracker.pro.trial"
    const val MONTHLY = "com.bkes994408.expensetracker.pro.monthly"
    const val YEARLY = "com.bkes994408.expensetracker.pro.yearly"
}

/**
 * 預設 fallback：尚未接上真實 BillingClient 時，明確回傳錯誤。
 */
class UnconfiguredGooglePlayBillingGateway : GooglePlayBillingGateway {
    override fun launchPurchase(productId: String): Result<String> {
        return Result.failure(IllegalStateException("Google Play Billing gateway is not configured"))
    }

    override fun queryActivePurchases(): Result<List<String>> {
        return Result.failure(IllegalStateException("Google Play Billing gateway is not configured"))
    }
}

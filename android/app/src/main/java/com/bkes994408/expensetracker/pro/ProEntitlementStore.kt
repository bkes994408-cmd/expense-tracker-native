package com.bkes994408.expensetracker.pro

import android.content.Context

interface EntitlementStorage {
    fun readTierName(): String?
    fun writeTierName(value: String)
}

private class SharedPrefsEntitlementStorage(context: Context) : EntitlementStorage {
    private val prefs = context.getSharedPreferences("pro_entitlement", Context.MODE_PRIVATE)

    override fun readTierName(): String? = prefs.getString(KEY_TIER, ProTier.FREE.name)
    override fun writeTierName(value: String) {
        prefs.edit().putString(KEY_TIER, value).apply()
    }

    private companion object {
        private const val KEY_TIER = "tier"
    }
}

enum class ProTier {
    FREE,
    MONTHLY,
    YEARLY,
    TRIAL,
}

class ProEntitlementStore(
    private val storage: EntitlementStorage,
    private val purchaseService: ProPurchaseService,
) {
    constructor(
        context: Context,
        purchaseService: ProPurchaseService = MockProPurchaseService(),
    ) : this(SharedPrefsEntitlementStorage(context), purchaseService)

    var tier: ProTier
        get() = runCatching { ProTier.valueOf(storage.readTierName() ?: ProTier.FREE.name) }
            .getOrDefault(ProTier.FREE)
        private set(value) {
            storage.writeTierName(value.name)
        }

    var lastError: String? = null
        private set

    val isPro: Boolean
        get() = tier != ProTier.FREE

    fun startTrial() = updateFromResult(purchaseService.purchase(ProPlan.TRIAL))
    fun subscribeMonthly() = updateFromResult(purchaseService.purchase(ProPlan.MONTHLY))
    fun subscribeYearly() = updateFromResult(purchaseService.purchase(ProPlan.YEARLY))

    fun restorePurchase() {
        purchaseService.restore()
            .onSuccess {
                tier = it ?: ProTier.FREE
                lastError = null
            }
            .onFailure {
                lastError = it.message
            }
    }

    fun resetToFreeForDebug() {
        tier = ProTier.FREE
        lastError = null
    }

    private fun updateFromResult(result: Result<ProTier>) {
        result.onSuccess {
            tier = it
            lastError = null
        }.onFailure {
            lastError = it.message
        }
    }
}

package com.bkes994408.expensetracker.pro

import android.content.Context

enum class ProFeature {
    ADVANCED_REPORT_MULTI_MONTH,
    BUDGET_UNLIMITED_CATEGORIES,
    BUDGET_COPY_LAST_MONTH,
    REPORT_PDF_EXPORT,
}

data class SubscriptionStatus(
    val tier: ProTier,
    val source: String,
    val lastUpdatedAtMillis: Long?,
) {
    val isActive: Boolean get() = tier != ProTier.FREE
    val permissionSummary: String get() = if (isActive) "Pro 已啟用" else "Free（僅基礎功能）"
}

interface EntitlementStorage {
    fun readTierName(): String?
    fun writeTierName(value: String)
    fun readSource(): String?
    fun writeSource(value: String)
    fun readUpdatedAtMillis(): Long?
    fun writeUpdatedAtMillis(value: Long)
}

private class SharedPrefsEntitlementStorage(context: Context) : EntitlementStorage {
    private val prefs = context.getSharedPreferences("pro_entitlement", Context.MODE_PRIVATE)

    override fun readTierName(): String? = prefs.getString(KEY_TIER, ProTier.FREE.name)
    override fun writeTierName(value: String) {
        prefs.edit().putString(KEY_TIER, value).apply()
    }

    override fun readSource(): String? = prefs.getString(KEY_SOURCE, "none")
    override fun writeSource(value: String) {
        prefs.edit().putString(KEY_SOURCE, value).apply()
    }

    override fun readUpdatedAtMillis(): Long? =
        if (prefs.contains(KEY_UPDATED_AT)) prefs.getLong(KEY_UPDATED_AT, 0L) else null

    override fun writeUpdatedAtMillis(value: Long) {
        prefs.edit().putLong(KEY_UPDATED_AT, value).apply()
    }

    private companion object {
        private const val KEY_TIER = "tier"
        private const val KEY_SOURCE = "source"
        private const val KEY_UPDATED_AT = "updated_at"
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

    val source: String
        get() = storage.readSource() ?: "none"

    val lastUpdatedAtMillis: Long?
        get() = storage.readUpdatedAtMillis()

    val status: SubscriptionStatus
        get() = SubscriptionStatus(
            tier = tier,
            source = source,
            lastUpdatedAtMillis = lastUpdatedAtMillis,
        )

    var lastError: String? = null
        private set

    val isPro: Boolean
        get() = tier != ProTier.FREE

    fun hasAccess(feature: ProFeature): Boolean {
        return when (feature) {
            ProFeature.ADVANCED_REPORT_MULTI_MONTH,
            ProFeature.BUDGET_UNLIMITED_CATEGORIES,
            ProFeature.BUDGET_COPY_LAST_MONTH,
            ProFeature.REPORT_PDF_EXPORT,
            -> isPro
        }
    }

    fun startTrial() = updateFromResult(source = "paywall_trial", result = purchaseService.purchase(ProPlan.TRIAL))
    fun subscribeMonthly() = updateFromResult(source = "paywall_monthly", result = purchaseService.purchase(ProPlan.MONTHLY))
    fun subscribeYearly() = updateFromResult(source = "paywall_yearly", result = purchaseService.purchase(ProPlan.YEARLY))

    fun restorePurchase() {
        purchaseService.restore()
            .onSuccess {
                persist(tier = it ?: ProTier.FREE, source = "restore_purchase")
                lastError = null
            }
            .onFailure {
                lastError = it.message
            }
    }

    fun resetToFreeForDebug() {
        persist(tier = ProTier.FREE, source = "debug_reset")
        lastError = null
    }

    private fun updateFromResult(source: String, result: Result<ProTier>) {
        result.onSuccess {
            persist(tier = it, source = source)
            lastError = null
        }.onFailure {
            lastError = it.message
        }
    }

    private fun persist(tier: ProTier, source: String) {
        this.tier = tier
        storage.writeSource(source)
        storage.writeUpdatedAtMillis(System.currentTimeMillis())
    }
}

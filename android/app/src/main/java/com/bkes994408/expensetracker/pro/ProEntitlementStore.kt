package com.bkes994408.expensetracker.pro

import android.content.Context

enum class ProFeature {
    ADVANCED_REPORTS,
    PDF_EXPORT,
    UNLIMITED_BUDGETS,
    ROLLOVER_BUDGET,
}

enum class SubscriptionState {
    FREE,
    ACTIVE,
    EXPIRED,
}

interface EntitlementStorage {
    fun readTierName(): String?
    fun writeTierName(value: String)
    fun readTrialExpireAtMillis(): Long?
    fun writeTrialExpireAtMillis(value: Long?)
}

private class SharedPrefsEntitlementStorage(context: Context) : EntitlementStorage {
    private val prefs = context.getSharedPreferences("pro_entitlement", Context.MODE_PRIVATE)

    override fun readTierName(): String? = prefs.getString(KEY_TIER, ProTier.FREE.name)

    override fun writeTierName(value: String) {
        prefs.edit().putString(KEY_TIER, value).apply()
    }

    override fun readTrialExpireAtMillis(): Long? {
        if (!prefs.contains(KEY_TRIAL_EXPIRE_AT)) return null
        return prefs.getLong(KEY_TRIAL_EXPIRE_AT, 0L)
    }

    override fun writeTrialExpireAtMillis(value: Long?) {
        prefs.edit().apply {
            if (value == null) remove(KEY_TRIAL_EXPIRE_AT) else putLong(KEY_TRIAL_EXPIRE_AT, value)
        }.apply()
    }

    private companion object {
        private const val KEY_TIER = "tier"
        private const val KEY_TRIAL_EXPIRE_AT = "trial_expire_at"
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
    private val nowProvider: () -> Long = { System.currentTimeMillis() },
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

    val trialExpireAtMillis: Long?
        get() = storage.readTrialExpireAtMillis()

    val subscriptionState: SubscriptionState
        get() = when (tier) {
            ProTier.FREE -> SubscriptionState.FREE
            ProTier.TRIAL -> {
                val expiresAt = trialExpireAtMillis
                if (expiresAt != null && nowProvider() >= expiresAt) SubscriptionState.EXPIRED else SubscriptionState.ACTIVE
            }
            ProTier.MONTHLY, ProTier.YEARLY -> SubscriptionState.ACTIVE
        }

    val statusLabel: String
        get() = when (subscriptionState) {
            SubscriptionState.FREE -> "Free"
            SubscriptionState.ACTIVE -> when (tier) {
                ProTier.TRIAL -> "Trial"
                ProTier.MONTHLY -> "Pro Monthly"
                ProTier.YEARLY -> "Pro Yearly"
                ProTier.FREE -> "Free"
            }
            SubscriptionState.EXPIRED -> "Expired"
        }

    var lastError: String? = null
        private set

    val isPro: Boolean
        get() = subscriptionState == SubscriptionState.ACTIVE

    fun canAccess(feature: ProFeature): Boolean {
        return when (feature) {
            ProFeature.ADVANCED_REPORTS,
            ProFeature.PDF_EXPORT,
            ProFeature.UNLIMITED_BUDGETS,
            ProFeature.ROLLOVER_BUDGET,
            -> isPro
        }
    }

    fun startTrial() = updateFromResult(purchaseService.purchase(ProPlan.TRIAL), activateTrial = true)
    fun subscribeMonthly() = updateFromResult(purchaseService.purchase(ProPlan.MONTHLY))
    fun subscribeYearly() = updateFromResult(purchaseService.purchase(ProPlan.YEARLY))

    fun restorePurchase() {
        purchaseService.restore()
            .onSuccess {
                if (it == null) {
                    applyTier(ProTier.FREE)
                } else {
                    applyTier(it)
                }
                lastError = null
            }
            .onFailure {
                lastError = it.message
            }
    }

    fun resetToFreeForDebug() {
        applyTier(ProTier.FREE)
        lastError = null
    }

    private fun updateFromResult(result: Result<ProTier>, activateTrial: Boolean = false) {
        result.onSuccess {
            applyTier(it)
            if (activateTrial && it == ProTier.TRIAL) {
                storage.writeTrialExpireAtMillis(nowProvider() + TRIAL_DURATION_MS)
            }
            lastError = null
        }.onFailure {
            lastError = it.message
        }
    }

    private fun applyTier(newTier: ProTier) {
        tier = newTier
        if (newTier != ProTier.TRIAL) {
            storage.writeTrialExpireAtMillis(null)
        }
    }

    private companion object {
        private const val TRIAL_DURATION_MS = 7L * 24L * 60L * 60L * 1000L
    }
}

package com.bkes994408.expensetracker.pro

import android.content.Context

enum class ProTier {
    FREE,
    MONTHLY,
    YEARLY,
    TRIAL,
}

class ProEntitlementStore(context: Context) {
    private val prefs = context.getSharedPreferences("pro_entitlement", Context.MODE_PRIVATE)

    var tier: ProTier
        get() = runCatching { ProTier.valueOf(prefs.getString(KEY_TIER, ProTier.FREE.name) ?: ProTier.FREE.name) }
            .getOrDefault(ProTier.FREE)
        private set(value) {
            prefs.edit().putString(KEY_TIER, value.name).apply()
        }

    val isPro: Boolean
        get() = tier != ProTier.FREE

    fun startTrial() {
        tier = ProTier.TRIAL
    }

    fun subscribeMonthly() {
        tier = ProTier.MONTHLY
    }

    fun subscribeYearly() {
        tier = ProTier.YEARLY
    }

    fun restorePurchase() {
        if (tier == ProTier.FREE) {
            tier = ProTier.MONTHLY
        }
    }

    fun resetToFreeForDebug() {
        tier = ProTier.FREE
    }

    private companion object {
        private const val KEY_TIER = "tier"
    }
}

package com.bkes994408.expensetracker.pro

data class RetentionStrategy(
    val headline: String,
    val cta: String,
    val offerCode: String,
)

fun ProEntitlementStore.retentionStrategy(nowMillis: Long = System.currentTimeMillis()): RetentionStrategy? {
    return when (tier) {
        ProTier.MONTHLY -> RetentionStrategy(
            headline = "改年付，立即省下 2 個月費用",
            cta = "升級年付",
            offerCode = "annual_save_2m",
        )
        ProTier.TRIAL -> {
            val expiresAt = trialExpireAtMillis
            if (expiresAt == null) {
                RetentionStrategy("試用已到期，限時回流優惠中", "查看優惠", "trial_winback_40")
            } else {
                val daysLeft = ((expiresAt - nowMillis) / (24L * 60L * 60L * 1000L)).toInt()
                when {
                    daysLeft <= 0 -> RetentionStrategy("你的 Pro 試用已結束", "立即續訂", "trial_winback_40")
                    daysLeft <= 2 -> RetentionStrategy("試用剩 $daysLeft 天，續訂可保留進階功能", "立即續訂", "trial_last48h")
                    else -> null
                }
            }
        }
        ProTier.FREE, ProTier.YEARLY -> null
    }
}

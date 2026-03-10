package com.bkes994408.expensetracker.pro

enum class ProPlan {
    TRIAL,
    MONTHLY,
    YEARLY,
}

interface ProPurchaseService {
    fun purchase(plan: ProPlan): Result<ProTier>
    fun restore(): Result<ProTier?>
}

class MockProPurchaseService(
    private val purchaseResult: Result<ProTier> = Result.success(ProTier.MONTHLY),
    private val restoreResult: Result<ProTier?> = Result.success(null),
) : ProPurchaseService {
    override fun purchase(plan: ProPlan): Result<ProTier> = purchaseResult
    override fun restore(): Result<ProTier?> = restoreResult
}

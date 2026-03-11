package com.bkes994408.expensetracker.pro

object BudgetCopyPolicy {
    private const val FREE_CATEGORY_LIMIT = 2

    fun requiresPaywall(
        isPro: Boolean,
        currentMonthCategories: List<String>,
        copiedCategories: List<String>,
    ): Boolean {
        if (isPro) return false
        val totalUniqueCategories = (currentMonthCategories + copiedCategories).toSet().size
        return totalUniqueCategories > FREE_CATEGORY_LIMIT
    }
}

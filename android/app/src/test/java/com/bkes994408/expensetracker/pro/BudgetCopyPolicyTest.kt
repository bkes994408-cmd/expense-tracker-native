package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BudgetCopyPolicyTest {
    @Test
    fun requiresPaywall_freePlan_whenCopyWouldExceedCategoryLimit() {
        val requiresPaywall = BudgetCopyPolicy.requiresPaywall(
            isPro = false,
            currentMonthCategories = emptyList(),
            copiedCategories = listOf("Food", "Transport", "Fun"),
        )

        assertTrue(requiresPaywall)
    }

    @Test
    fun requiresPaywall_freePlan_whenMergedCategoriesWithinLimit_returnsFalse() {
        val requiresPaywall = BudgetCopyPolicy.requiresPaywall(
            isPro = false,
            currentMonthCategories = listOf("Food"),
            copiedCategories = listOf("Food", "Transport"),
        )

        assertFalse(requiresPaywall)
    }
}

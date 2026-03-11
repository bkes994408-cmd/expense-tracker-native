package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BudgetProgressCalculatorTest {
    @Test
    fun build_returnsWarningAndOverspentStatus() {
        val plans = listOf(
            BudgetPlan(id = 1, monthKey = "2026-03", categoryName = "Food", amount = 1000.0, carryOverMode = CarryOverMode.NONE),
            BudgetPlan(id = 2, monthKey = "2026-03", categoryName = "Transport", amount = 500.0, carryOverMode = CarryOverMode.NONE),
        )

        val progress = BudgetProgressCalculator.build(
            plans,
            spendingByCategory = mapOf("Food" to 850.0, "Transport" to 650.0),
        )

        assertEquals(BudgetStatus.WARNING, progress[0].status)
        assertEquals(BudgetStatus.OVERSPENT, progress[1].status)
        assertTrue(progress[1].remaining < 0)
    }
}

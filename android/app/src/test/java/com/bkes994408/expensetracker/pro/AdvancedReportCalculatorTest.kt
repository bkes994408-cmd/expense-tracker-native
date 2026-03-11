package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.domain.Expense
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal

class AdvancedReportCalculatorTest {
    @Test
    fun freeTierFallsBackToOneMonthAverage() {
        val report = AdvancedReportCalculator.build(
            expenses = listOf(
                Expense(title = "Salary", amount = BigDecimal("10000")),
                Expense(title = "Food", amount = BigDecimal("-3000")),
            ),
            range = ReportRange.SIX_MONTHS,
            isPro = false,
        )

        assertEquals(BigDecimal("10000.00"), report.averageIncome)
        assertEquals(BigDecimal("3000.00"), report.averageExpense)
        assertEquals(BigDecimal("7000.00"), report.averageNet)
    }

    @Test
    fun proTierUsesSelectedRangeForAverages() {
        val report = AdvancedReportCalculator.build(
            expenses = listOf(
                Expense(title = "Salary", amount = BigDecimal("9000")),
                Expense(title = "Food", amount = BigDecimal("-3000")),
            ),
            range = ReportRange.THREE_MONTHS,
            isPro = true,
        )

        assertEquals(BigDecimal("3000.00"), report.averageIncome)
        assertEquals(BigDecimal("1000.00"), report.averageExpense)
        assertEquals(BigDecimal("2000.00"), report.averageNet)
    }
}

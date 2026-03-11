package com.bkes994408.expensetracker.ui

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.pro.AdvancedReportCalculator
import com.bkes994408.expensetracker.pro.ReportRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.temporal.ChronoUnit

class HomeReportIntegrationTest {
    private val now: Instant = Instant.parse("2026-03-11T09:00:00Z")

    @Test
    fun rangeSwitchingUsesLiveDataAndRespectsFreeProGating() {
        val repository = MutableExpenseRepository(
            mutableListOf(
                Expense(title = "Salary", amount = BigDecimal("12000"), createdAt = now.minus(3, ChronoUnit.DAYS)),
                Expense(title = "Food", amount = BigDecimal("-2000"), createdAt = now.minus(2, ChronoUnit.DAYS)),
                Expense(title = "Prev Month Income", amount = BigDecimal("6000"), createdAt = now.minus(40, ChronoUnit.DAYS)),
            )
        )

        val freeSwitchResult = HomeReportController.nextRange(ReportRange.ONE_MONTH, isPro = false)
        assertTrue(freeSwitchResult is RangeSelectionResult.PaywallRequired)

        val proSwitchResult = HomeReportController.nextRange(ReportRange.ONE_MONTH, isPro = true)
        assertEquals(ReportRange.THREE_MONTHS, (proSwitchResult as RangeSelectionResult.RangeSelected).range)

        val oneMonth = AdvancedReportCalculator.build(repository.sampleSync(), ReportRange.ONE_MONTH, isPro = true, now = now)
        assertEquals(BigDecimal("12000.00"), oneMonth.averageIncome)

        repository.items.add(
            Expense(title = "New Income", amount = BigDecimal("3000"), createdAt = now.minus(1, ChronoUnit.DAYS))
        )

        val threeMonths = AdvancedReportCalculator.build(repository.sampleSync(), ReportRange.THREE_MONTHS, isPro = true, now = now)
        assertEquals(BigDecimal("7000.00"), threeMonths.averageIncome)
        assertEquals(BigDecimal("666.67"), threeMonths.averageExpense)
    }
}

private class MutableExpenseRepository(
    val items: MutableList<Expense>,
) : ExpenseRepository {
    override suspend fun sample(): List<Expense> = items.toList()

    fun sampleSync(): List<Expense> = items.toList()
}

package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.domain.Expense
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.temporal.ChronoUnit

class AdvancedReportCalculatorTest {
    private val now: Instant = Instant.parse("2026-03-11T09:00:00Z")

    @Test
    fun freeTierFallsBackToOneMonthAverage() {
        val report = AdvancedReportCalculator.build(
            expenses = listOf(
                Expense(title = "Salary", amount = BigDecimal("10000"), createdAt = now.minus(5, ChronoUnit.DAYS)),
                Expense(title = "Food", amount = BigDecimal("-3000"), createdAt = now.minus(3, ChronoUnit.DAYS)),
                Expense(title = "Old Salary", amount = BigDecimal("20000"), createdAt = now.minus(45, ChronoUnit.DAYS)),
            ),
            range = ReportRange.SIX_MONTHS,
            isPro = false,
            now = now,
        )

        assertEquals(BigDecimal("10000.00"), report.averageIncome)
        assertEquals(BigDecimal("3000.00"), report.averageExpense)
        assertEquals(BigDecimal("7000.00"), report.averageNet)
    }

    @Test
    fun proTierUsesSelectedRangeAndCreatedAtWindow() {
        val report = AdvancedReportCalculator.build(
            expenses = listOf(
                Expense(title = "Current Salary", amount = BigDecimal("9000"), createdAt = now.minus(5, ChronoUnit.DAYS)),
                Expense(title = "Current Food", amount = BigDecimal("-3000"), createdAt = now.minus(2, ChronoUnit.DAYS)),
                Expense(title = "Prev Month", amount = BigDecimal("3000"), createdAt = now.minus(40, ChronoUnit.DAYS)),
                Expense(title = "Out of 3M", amount = BigDecimal("9999"), createdAt = now.minus(120, ChronoUnit.DAYS)),
            ),
            range = ReportRange.THREE_MONTHS,
            isPro = true,
            now = now,
        )

        assertEquals(BigDecimal("4000.00"), report.averageIncome)
        assertEquals(BigDecimal("1000.00"), report.averageExpense)
        assertEquals(BigDecimal("3000.00"), report.averageNet)
    }
}

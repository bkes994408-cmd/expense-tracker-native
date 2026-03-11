package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.domain.Expense
import java.math.BigDecimal
import java.math.RoundingMode

enum class ReportRange(val months: Int) {
    ONE_MONTH(1),
    THREE_MONTHS(3),
    SIX_MONTHS(6),
    TWELVE_MONTHS(12),
}

data class AdvancedReport(
    val averageIncome: BigDecimal,
    val averageExpense: BigDecimal,
    val averageNet: BigDecimal,
)

object AdvancedReportCalculator {
    fun build(expenses: List<Expense>, range: ReportRange, isPro: Boolean): AdvancedReport {
        val monthCount = if (isPro) range.months else 1
        val income = expenses.map { it.amount }.filter { it > BigDecimal.ZERO }.fold(BigDecimal.ZERO, BigDecimal::add)
        val expense = expenses.map { it.amount }.filter { it < BigDecimal.ZERO }.fold(BigDecimal.ZERO) { acc, value -> acc + value.abs() }
        val net = income - expense
        val divisor = BigDecimal(monthCount)

        return AdvancedReport(
            averageIncome = income.divide(divisor, 2, RoundingMode.HALF_UP),
            averageExpense = expense.divide(divisor, 2, RoundingMode.HALF_UP),
            averageNet = net.divide(divisor, 2, RoundingMode.HALF_UP),
        )
    }
}

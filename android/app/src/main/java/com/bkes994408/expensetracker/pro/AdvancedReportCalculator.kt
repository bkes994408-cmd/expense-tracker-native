package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.domain.Expense
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime

enum class ReportRange(val months: Int) {
    ONE_MONTH(1),
    THREE_MONTHS(3),
    SIX_MONTHS(6),
    TWELVE_MONTHS(12),
}

data class TrendPoint(
    val monthLabel: String,
    val income: BigDecimal,
    val expense: BigDecimal,
    val net: BigDecimal,
)

data class PieSlice(
    val label: String,
    val value: BigDecimal,
)

data class AdvancedReport(
    val averageIncome: BigDecimal,
    val averageExpense: BigDecimal,
    val averageNet: BigDecimal,
    val monthlyTrend: List<TrendPoint>,
    val momDelta: BigDecimal?,
    val yoyDelta: BigDecimal?,
    val pieSlices: List<PieSlice>,
)

object AdvancedReportCalculator {
    fun build(
        expenses: List<Expense>,
        range: ReportRange,
        isPro: Boolean,
        now: Instant = Instant.now(),
    ): AdvancedReport {
        val monthCount = if (isPro) range.months else 1
        val zone = ZoneId.systemDefault()
        val nowMonth = YearMonth.from(ZonedDateTime.ofInstant(now, zone))

        val months = (monthCount - 1 downTo 0).map { nowMonth.minusMonths(it.toLong()) }
        val monthStats = months.map { month ->
            val stats = monthStatsFor(expenses, month, zone)
            TrendPoint(
                monthLabel = month.toString(),
                income = stats.income,
                expense = stats.expense,
                net = stats.net,
            )
        }

        val divisor = BigDecimal(monthCount)
        val totalIncome = monthStats.fold(BigDecimal.ZERO) { acc, point -> acc + point.income }
        val totalExpense = monthStats.fold(BigDecimal.ZERO) { acc, point -> acc + point.expense }
        val totalNet = monthStats.fold(BigDecimal.ZERO) { acc, point -> acc + point.net }

        val currentMonthNet = monthStats.lastOrNull()?.net ?: BigDecimal.ZERO
        val previousMonthNet = monthStatsFor(expenses, nowMonth.minusMonths(1), zone).net
        val previousYearNet = monthStatsFor(expenses, nowMonth.minusYears(1), zone).net

        val pieSlices = listOf(
            PieSlice("收入", totalIncome),
            PieSlice("支出", totalExpense),
        ).filter { it.value > BigDecimal.ZERO }

        return AdvancedReport(
            averageIncome = totalIncome.divide(divisor, 2, RoundingMode.HALF_UP),
            averageExpense = totalExpense.divide(divisor, 2, RoundingMode.HALF_UP),
            averageNet = totalNet.divide(divisor, 2, RoundingMode.HALF_UP),
            monthlyTrend = monthStats,
            momDelta = computeDeltaOrNull(currentMonthNet, previousMonthNet),
            yoyDelta = computeDeltaOrNull(currentMonthNet, previousYearNet),
            pieSlices = pieSlices,
        )
    }

    private fun computeDeltaOrNull(current: BigDecimal, baseline: BigDecimal): BigDecimal? {
        if (baseline == BigDecimal.ZERO && current == BigDecimal.ZERO) return null
        return current - baseline
    }

    private data class MonthStats(
        val income: BigDecimal,
        val expense: BigDecimal,
    ) {
        val net: BigDecimal get() = income - expense
    }

    private fun monthStatsFor(expenses: List<Expense>, month: YearMonth, zone: ZoneId): MonthStats {
        val startInclusive = month.atDay(1).atStartOfDay(zone).toInstant()
        val endExclusive = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant()
        val rangedExpenses = expenses.filter { it.createdAt >= startInclusive && it.createdAt < endExclusive }

        val income = rangedExpenses
            .map { it.amount }
            .filter { it > BigDecimal.ZERO }
            .fold(BigDecimal.ZERO, BigDecimal::add)
        val expense = rangedExpenses
            .map { it.amount }
            .filter { it < BigDecimal.ZERO }
            .fold(BigDecimal.ZERO) { acc, value -> acc + value.abs() }

        return MonthStats(income = income, expense = expense)
    }
}

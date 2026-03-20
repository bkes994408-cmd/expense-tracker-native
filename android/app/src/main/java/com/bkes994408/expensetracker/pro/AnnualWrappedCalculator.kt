package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.domain.Expense
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.ZoneId

data class AnnualWrappedReport(
    val year: Int,
    val totalIncome: BigDecimal,
    val totalExpense: BigDecimal,
    val totalNet: BigDecimal,
    val savingRatePercent: BigDecimal,
    val topExpenseCategory: String?,
    val bestMonthLabel: String?,
    val toughestMonthLabel: String?,
)

object AnnualWrappedCalculator {
    fun build(
        expenses: List<Expense>,
        year: Int,
        zoneId: ZoneId = ZoneId.systemDefault(),
    ): AnnualWrappedReport? {
        val yearly = expenses.filter { it.createdAt.atZone(zoneId).year == year }
        if (yearly.isEmpty()) return null

        val totalIncome = yearly.filter { it.amount > BigDecimal.ZERO }
            .fold(BigDecimal.ZERO) { acc, item -> acc + item.amount }
        val totalExpense = yearly.filter { it.amount < BigDecimal.ZERO }
            .fold(BigDecimal.ZERO) { acc, item -> acc + item.amount.abs() }
        val totalNet = totalIncome - totalExpense
        val savingRate = if (totalIncome == BigDecimal.ZERO) {
            BigDecimal.ZERO
        } else {
            totalNet.divide(totalIncome, 4, RoundingMode.HALF_UP).multiply(BigDecimal(100))
        }

        val topCategory = yearly.filter { it.amount < BigDecimal.ZERO }
            .groupBy { classifyExpense(it.title) }
            .mapValues { (_, values) -> values.fold(BigDecimal.ZERO) { acc, e -> acc + e.amount.abs() } }
            .maxByOrNull { it.value }
            ?.key

        val monthNet = yearly.groupBy { it.createdAt.atZone(zoneId).let { z -> "%04d-%02d".format(z.year, z.monthValue) } }
            .mapValues { (_, values) -> values.fold(BigDecimal.ZERO) { acc, e -> acc + e.amount } }

        val best = monthNet.maxByOrNull { it.value }?.key
        val tough = monthNet.minByOrNull { it.value }?.key

        return AnnualWrappedReport(
            year = year,
            totalIncome = totalIncome,
            totalExpense = totalExpense,
            totalNet = totalNet,
            savingRatePercent = savingRate,
            topExpenseCategory = topCategory,
            bestMonthLabel = best,
            toughestMonthLabel = tough,
        )
    }

    private fun classifyExpense(title: String): String {
        val lowered = title.lowercase()
        return when {
            lowered.contains("food") || lowered.contains("lunch") || lowered.contains("dinner") -> "餐飲"
            lowered.contains("uber") || lowered.contains("taxi") || lowered.contains("metro") -> "交通"
            lowered.contains("rent") -> "居住"
            else -> "其他"
        }
    }
}

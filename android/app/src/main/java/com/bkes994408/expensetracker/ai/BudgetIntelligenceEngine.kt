package com.bkes994408.expensetracker.ai

import com.bkes994408.expensetracker.db.ExpenseLedger
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import kotlin.math.max

object BudgetIntelligenceEngine {
    data class BudgetDraft(
        val category: String,
        val suggestedBudget: BigDecimal,
        val baseline: BigDecimal,
        val trend: BigDecimal,
    )

    data class OverspendForecast(
        val category: String,
        val budget: BigDecimal,
        val currentSpent: BigDecimal,
        val projectedMonthSpend: BigDecimal,
        val riskScore: BigDecimal,
    )

    fun buildDrafts(entries: List<ExpenseLedger.Entry>, now: LocalDate = LocalDate.now()): List<BudgetDraft> {
        val history = monthBuckets(entries, now)
        return history.mapNotNull { (category, monthlyValues) ->
            if (monthlyValues.isEmpty()) return@mapNotNull null
            val weightedAverage = weightedAverage(monthlyValues)
            val trend = momentum(monthlyValues)
            val suggestion = weightedAverage.multiply(BigDecimal("1.05")).add(trend)
                .max(BigDecimal("300"))
                .setScale(2, RoundingMode.HALF_UP)

            BudgetDraft(
                category = category,
                suggestedBudget = suggestion,
                baseline = weightedAverage.setScale(2, RoundingMode.HALF_UP),
                trend = trend.setScale(2, RoundingMode.HALF_UP),
            )
        }.sortedByDescending { it.suggestedBudget }
    }

    fun forecastOverspend(
        entries: List<ExpenseLedger.Entry>,
        drafts: List<BudgetDraft>,
        now: LocalDate = LocalDate.now(),
    ): List<OverspendForecast> {
        if (drafts.isEmpty()) return emptyList()

        val spentThisMonth = entries
            .filter { it.amount < BigDecimal.ZERO }
            .filter { it.createdAt.atZone(java.time.ZoneId.systemDefault()).toLocalDate().let { d -> d.year == now.year && d.month == now.month } }
            .groupBy { it.category }
            .mapValues { (_, v) -> v.fold(BigDecimal.ZERO) { acc, e -> acc + e.amount.abs() } }

        val daysInMonth = now.lengthOfMonth().toBigDecimal()
        val elapsed = max(1, now.dayOfMonth).toBigDecimal()

        return drafts.mapNotNull { draft ->
            val current = spentThisMonth[draft.category] ?: BigDecimal.ZERO
            if (draft.suggestedBudget <= BigDecimal.ZERO) return@mapNotNull null

            val projected = if (current == BigDecimal.ZERO) {
                BigDecimal.ZERO
            } else {
                current.divide(elapsed, 6, RoundingMode.HALF_UP)
                    .multiply(daysInMonth)
                    .setScale(2, RoundingMode.HALF_UP)
            }

            val risk = if (draft.suggestedBudget == BigDecimal.ZERO) {
                BigDecimal.ZERO
            } else {
                projected.divide(draft.suggestedBudget, 4, RoundingMode.HALF_UP)
            }

            if (risk < BigDecimal("0.8")) return@mapNotNull null

            OverspendForecast(
                category = draft.category,
                budget = draft.suggestedBudget,
                currentSpent = current.setScale(2, RoundingMode.HALF_UP),
                projectedMonthSpend = projected,
                riskScore = risk,
            )
        }.sortedByDescending { it.riskScore }
    }

    private fun monthBuckets(entries: List<ExpenseLedger.Entry>, now: LocalDate): Map<String, List<BigDecimal>> {
        val zone = java.time.ZoneId.systemDefault()
        val currentMonthStart = now.withDayOfMonth(1)
        val lookbackStart = currentMonthStart.minusMonths(6)

        val grouped = entries
            .filter { it.amount < BigDecimal.ZERO }
            .filter {
                val date = it.createdAt.atZone(zone).toLocalDate()
                !date.isBefore(lookbackStart) && date.isBefore(currentMonthStart)
            }
            .groupBy { it.category }

        return grouped.mapValues { (_, values) ->
            val byMonth = values.groupBy { it.createdAt.atZone(zone).toLocalDate().withDayOfMonth(1) }
            (0 until 6).map { index ->
                val month = currentMonthStart.minusMonths((6 - index).toLong())
                byMonth[month]?.fold(BigDecimal.ZERO) { acc, e -> acc + e.amount.abs() } ?: BigDecimal.ZERO
            }
        }
    }

    private fun weightedAverage(values: List<BigDecimal>): BigDecimal {
        if (values.isEmpty()) return BigDecimal.ZERO
        val weights = listOf(1, 2, 3, 4, 5, 6)
        val weightedSum = values.zip(weights).fold(BigDecimal.ZERO) { acc, pair ->
            acc + pair.first.multiply(BigDecimal(pair.second))
        }
        return weightedSum.divide(BigDecimal(weights.sum()), 6, RoundingMode.HALF_UP)
    }

    private fun momentum(values: List<BigDecimal>): BigDecimal {
        if (values.size < 2) return BigDecimal.ZERO
        val latest = values.last()
        val previous = values[values.size - 2]
        return latest.subtract(previous).multiply(BigDecimal("0.30"))
    }
}

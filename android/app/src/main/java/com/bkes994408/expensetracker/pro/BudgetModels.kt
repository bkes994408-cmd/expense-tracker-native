package com.bkes994408.expensetracker.pro

import kotlin.math.max

enum class CarryOverMode {
    NONE,
    ROLLOVER,
}

data class BudgetPlan(
    val id: Long,
    val monthKey: String,
    val categoryName: String,
    val amount: Double,
    val carryOverMode: CarryOverMode,
)

enum class BudgetStatus {
    HEALTHY,
    WARNING,
    OVERSPENT,
}

data class BudgetProgress(
    val categoryName: String,
    val spent: Double,
    val budget: Double,
) {
    val remaining: Double = budget - spent
    val ratio: Double = if (budget <= 0.0) 0.0 else max(0.0, spent / budget)
    val status: BudgetStatus = when {
        ratio > 1.0 -> BudgetStatus.OVERSPENT
        ratio >= 0.8 -> BudgetStatus.WARNING
        else -> BudgetStatus.HEALTHY
    }
}

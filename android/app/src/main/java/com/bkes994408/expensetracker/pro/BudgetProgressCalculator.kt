package com.bkes994408.expensetracker.pro

object BudgetProgressCalculator {
    fun build(plans: List<BudgetPlan>, spendingByCategory: Map<String, Double>): List<BudgetProgress> {
        return plans.map {
            BudgetProgress(
                categoryName = it.categoryName,
                spent = spendingByCategory[it.categoryName] ?: 0.0,
                budget = it.amount,
            )
        }
    }
}

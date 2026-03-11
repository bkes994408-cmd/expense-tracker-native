package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense

class InMemoryExpenseStore(
    initialExpenses: List<Expense> = emptyList(),
) : ExpenseStore {
    private val expenses = initialExpenses.toMutableList()

    override suspend fun readAll(): List<Expense> = expenses.toList()

    fun replaceAll(items: List<Expense>) {
        expenses.clear()
        expenses.addAll(items)
    }
}

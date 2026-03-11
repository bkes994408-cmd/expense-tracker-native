package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseRepository
class ExpenseRepositoryImpl(
    private val expenseStore: ExpenseStore,
) : ExpenseRepository {
    override suspend fun fetchExpenses(): List<Expense> {
        return expenseStore.readAll()
    }
}

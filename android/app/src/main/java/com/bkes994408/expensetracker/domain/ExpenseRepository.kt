package com.bkes994408.expensetracker.domain

interface ExpenseRepository {
    suspend fun sample(): List<Expense>
}

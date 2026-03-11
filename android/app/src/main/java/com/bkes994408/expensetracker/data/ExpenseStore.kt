package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense

interface ExpenseStore {
    suspend fun readAll(): List<Expense>
}

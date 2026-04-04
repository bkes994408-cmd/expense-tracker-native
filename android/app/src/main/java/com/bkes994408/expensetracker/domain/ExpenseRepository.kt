package com.bkes994408.expensetracker.domain

import java.util.UUID

interface ExpenseRepository {
    suspend fun fetchExpenses(): List<Expense>
    suspend fun fetchCategories(): List<ExpenseCategory>

    suspend fun addExpense(expense: Expense)
    suspend fun updateExpense(expense: Expense)
    suspend fun deleteExpense(id: UUID)

    suspend fun addCategory(category: ExpenseCategory)
    suspend fun updateCategory(category: ExpenseCategory)
    suspend fun deleteCategory(id: UUID)

    suspend fun syncFromCloud()
}

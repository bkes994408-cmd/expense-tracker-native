package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import java.util.UUID

interface ExpenseStore {
    suspend fun readAll(): List<Expense>
    suspend fun writeAll(expenses: List<Expense>)

    suspend fun readAllCategories(): List<ExpenseCategory>
    suspend fun writeAllCategories(categories: List<ExpenseCategory>)

    suspend fun upsertExpense(expense: Expense)
    suspend fun deleteExpense(id: UUID)

    suspend fun upsertCategory(category: ExpenseCategory)
    suspend fun deleteCategory(id: UUID)
}

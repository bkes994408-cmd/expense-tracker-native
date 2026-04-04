package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import java.util.UUID

class InMemoryExpenseStore(
    initialExpenses: List<Expense> = emptyList(),
    initialCategories: List<ExpenseCategory> = emptyList(),
) : ExpenseStore {
    private val expenses = initialExpenses.toMutableList()
    private val categories = initialCategories.toMutableList()

    override suspend fun readAll(): List<Expense> = expenses.toList()

    override suspend fun writeAll(expenses: List<Expense>) {
        this.expenses.clear()
        this.expenses.addAll(expenses)
    }

    override suspend fun readAllCategories(): List<ExpenseCategory> = categories.toList()

    override suspend fun writeAllCategories(categories: List<ExpenseCategory>) {
        this.categories.clear()
        this.categories.addAll(categories)
    }

    override suspend fun upsertExpense(expense: Expense) {
        val index = expenses.indexOfFirst { it.id == expense.id }
        if (index >= 0) {
            expenses[index] = expense
        } else {
            expenses.add(expense)
        }
    }

    override suspend fun deleteExpense(id: UUID) {
        expenses.removeAll { it.id == id }
    }

    override suspend fun upsertCategory(category: ExpenseCategory) {
        val index = categories.indexOfFirst { it.id == category.id }
        if (index >= 0) {
            categories[index] = category
        } else {
            categories.add(category)
        }
    }

    override suspend fun deleteCategory(id: UUID) {
        categories.removeAll { it.id == id }
    }

    fun replaceAll(items: List<Expense>) {
        expenses.clear()
        expenses.addAll(items)
    }
}

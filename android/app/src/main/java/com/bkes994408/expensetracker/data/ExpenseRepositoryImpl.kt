package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.network.ApiClient
import java.math.BigDecimal

class ExpenseRepositoryImpl(
    private val apiClient: ApiClient,
) : ExpenseRepository {
    override suspend fun sample(): List<Expense> {
        val status = if (apiClient.ping()) "online" else "offline"
        return listOf(Expense(title = "Coffee ($status)", amount = BigDecimal("120")))
    }
}

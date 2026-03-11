package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.network.ApiClient
import java.math.BigDecimal
import java.time.Instant
import java.time.temporal.ChronoUnit

class ExpenseRepositoryImpl(
    private val apiClient: ApiClient,
) : ExpenseRepository {
    override suspend fun sample(): List<Expense> {
        val status = if (apiClient.ping()) "online" else "offline"
        val now = Instant.now()
        return listOf(
            Expense(title = "Salary ($status)", amount = BigDecimal("42000"), createdAt = now.minus(5, ChronoUnit.DAYS)),
            Expense(title = "Food", amount = BigDecimal("-8500"), createdAt = now.minus(4, ChronoUnit.DAYS)),
            Expense(title = "Transport", amount = BigDecimal("-3200"), createdAt = now.minus(35, ChronoUnit.DAYS)),
            Expense(title = "Freelance", amount = BigDecimal("18000"), createdAt = now.minus(62, ChronoUnit.DAYS)),
        )
    }
}

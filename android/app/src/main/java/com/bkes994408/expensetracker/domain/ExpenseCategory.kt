package com.bkes994408.expensetracker.domain

import java.time.Instant
import java.util.UUID

data class ExpenseCategory(
    val id: UUID = UUID.randomUUID(),
    val name: String,
    val updatedAt: Instant = Instant.now(),
)

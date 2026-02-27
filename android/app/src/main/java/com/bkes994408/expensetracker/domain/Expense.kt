package com.bkes994408.expensetracker.domain

import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

data class Expense(
    val id: UUID = UUID.randomUUID(),
    val title: String,
    val amount: BigDecimal,
    val createdAt: Instant = Instant.now(),
)

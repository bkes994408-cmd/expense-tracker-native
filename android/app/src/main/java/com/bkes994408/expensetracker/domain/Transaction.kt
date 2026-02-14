package com.bkes994408.expensetracker.domain

data class Transaction(
    val id: Long,
    val amountCents: Long,
    val note: String,
    val occurredAtEpochMillis: Long,
)

package com.bkes994408.expensetrackernative.domain

interface TransactionRepository {
    suspend fun getTransactions(): List<Transaction>
}

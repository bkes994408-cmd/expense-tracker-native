package com.bkes994408.expensetrackernative.data

import com.bkes994408.expensetrackernative.domain.Transaction
import com.bkes994408.expensetrackernative.domain.TransactionRepository
import com.bkes994408.expensetrackernative.network.NetworkClient

class TransactionRepositoryImpl(
    private val networkClient: NetworkClient,
) : TransactionRepository {

    override suspend fun getTransactions(): List<Transaction> {
        networkClient.get("/transactions")
        return listOf(
            Transaction(id = "1", amount = 120.0, note = "Lunch"),
            Transaction(id = "2", amount = 350.0, note = "Transport"),
        )
    }
}

package com.bkes994408.expensetrackernative.domain

class GetTransactionsUseCase(
    private val repository: TransactionRepository,
) {
    suspend operator fun invoke(): List<Transaction> = repository.getTransactions()
}

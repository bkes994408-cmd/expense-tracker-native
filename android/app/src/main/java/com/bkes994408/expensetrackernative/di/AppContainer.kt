package com.bkes994408.expensetrackernative.di

import com.bkes994408.expensetrackernative.data.TransactionRepositoryImpl
import com.bkes994408.expensetrackernative.domain.GetTransactionsUseCase
import com.bkes994408.expensetrackernative.network.StubNetworkClient

object AppContainer {
    private val networkClient = StubNetworkClient()
    private val transactionRepository = TransactionRepositoryImpl(networkClient)

    val getTransactionsUseCase = GetTransactionsUseCase(transactionRepository)
}

package com.bkes994408.expensetracker.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bkes994408.expensetracker.domain.AddTransactionUseCase
import com.bkes994408.expensetracker.domain.DeleteTransactionUseCase
import com.bkes994408.expensetracker.domain.ObserveTransactionsUseCase
import com.bkes994408.expensetracker.domain.Transaction
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AppViewModel(
    private val observeTransactions: ObserveTransactionsUseCase,
    private val addTransaction: AddTransactionUseCase,
    private val deleteTransaction: DeleteTransactionUseCase,
) : ViewModel() {

    val transactions: StateFlow<List<Transaction>> = observeTransactions()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    fun clearError() {
        _errorMessage.value = null
    }

    fun add(amountCents: Long, note: String, occurredAtEpochMillis: Long, onResult: (Boolean) -> Unit = {}) {
        viewModelScope.launch {
            try {
                addTransaction(
                    amountCents = amountCents,
                    note = note,
                    occurredAtEpochMillis = occurredAtEpochMillis,
                )
                _errorMessage.value = null
                onResult(true)
            } catch (t: Throwable) {
                _errorMessage.value = t.message ?: "Failed to add transaction"
                onResult(false)
            }
        }
    }

    fun delete(id: Long) {
        viewModelScope.launch {
            try {
                deleteTransaction(id)
                _errorMessage.value = null
            } catch (t: Throwable) {
                _errorMessage.value = t.message ?: "Failed to delete transaction"
            }
        }
    }
}

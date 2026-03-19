package com.bkes994408.expensetracker.ui

import androidx.lifecycle.ViewModel
import com.bkes994408.expensetracker.db.ExpenseLedger
import java.math.BigDecimal
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class HomeViewModel(
    private val ledger: ExpenseLedger,
) : ViewModel() {
    val entries: StateFlow<List<ExpenseLedger.Entry>> = ledger.entries

    private val _titleInput = MutableStateFlow("")
    val titleInput: StateFlow<String> = _titleInput

    private val _amountInput = MutableStateFlow("")
    val amountInput: StateFlow<String> = _amountInput

    fun onTitleChanged(value: String) { _titleInput.value = value }
    fun onAmountChanged(value: String) { _amountInput.value = value }

    fun addExpense() {
        val title = _titleInput.value.trim()
        val amount = _amountInput.value.toBigDecimalOrNull() ?: return
        if (title.isBlank() || amount <= BigDecimal.ZERO) return

        ledger.addExpense(title = title, amount = amount.negate())
        _titleInput.value = ""
        _amountInput.value = ""
    }

    fun monthlySummary(): BigDecimal = ledger.currentMonthExpenseTotal()
    fun suggestions(): List<ExpenseLedger.Suggestion> = ledger.suggestBudgets()
    fun alerts(): List<ExpenseLedger.Alert> = ledger.detectOverspend()
}

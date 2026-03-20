package com.bkes994408.expensetracker.ui

import androidx.lifecycle.ViewModel
import com.bkes994408.expensetracker.db.ExpenseLedger
import com.bkes994408.expensetracker.ai.OnDeviceCategoryClassifier
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

    private val _predictedCategory = MutableStateFlow<OnDeviceCategoryClassifier.Prediction?>(null)
    val predictedCategory: StateFlow<OnDeviceCategoryClassifier.Prediction?> = _predictedCategory

    fun onTitleChanged(value: String) {
        _titleInput.value = value
        _predictedCategory.value = value.trim().takeIf { it.isNotEmpty() }?.let(ledger::predictCategory)
    }
    fun onAmountChanged(value: String) { _amountInput.value = value }

    fun addExpense() {
        val title = _titleInput.value.trim()
        val amount = _amountInput.value.toBigDecimalOrNull() ?: return
        if (title.isBlank() || amount <= BigDecimal.ZERO) return

        val predicted = _predictedCategory.value ?: ledger.predictCategory(title)
        ledger.addExpense(title = title, amount = amount.negate(), category = predicted.category)
        _titleInput.value = ""
        _amountInput.value = ""
        _predictedCategory.value = null
    }

    fun monthlySummary(): BigDecimal = ledger.currentMonthExpenseTotal()
    fun suggestions(): List<ExpenseLedger.Suggestion> = ledger.suggestBudgets()
    fun alerts(): List<ExpenseLedger.Alert> = ledger.detectOverspend()
}

package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import java.math.BigDecimal
import java.math.RoundingMode

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddTransactionScreen(
    onBack: () -> Unit,
    onSave: (amountCents: Long, note: String, occurredAtEpochMillis: Long) -> Unit,
    externalErrorMessage: String?,
    onClearExternalError: () -> Unit,
) {
    var amountText by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var localError by remember { mutableStateOf<String?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(),
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = amountText,
                onValueChange = {
                    amountText = it
                    localError = null
                    onClearExternalError()
                },
                label = { Text("Amount (e.g. 12.34)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
            )

            OutlinedTextField(
                value = note,
                onValueChange = {
                    note = it
                    onClearExternalError()
                },
                label = { Text("Note") },
                singleLine = true,
            )

            val shownError = localError ?: externalErrorMessage
            if (shownError != null) {
                Text(shownError, color = MaterialTheme.colorScheme.error)
            }

            Button(
                enabled = amountText.isNotBlank(),
                onClick = {
                    val cents = parseAmountToCents(amountText)
                    if (cents == null) {
                        localError = "Please enter a valid amount"
                        return@Button
                    }
                    if (cents == 0L) {
                        localError = "Amount must not be zero"
                        return@Button
                    }
                    localError = null
                    val now = System.currentTimeMillis()
                    onSave(cents, note, now)
                }
            ) {
                Text("Save")
            }
        }
    }
}

private fun parseAmountToCents(text: String): Long? {
    return try {
        val normalized = text.trim().replace(',', '.')
        if (normalized.isBlank()) return null
        val parsed = BigDecimal(normalized)
        parsed
            .movePointRight(2)
            .setScale(0, RoundingMode.HALF_UP)
            .longValueExact()
    } catch (_: Throwable) {
        null
    }
}

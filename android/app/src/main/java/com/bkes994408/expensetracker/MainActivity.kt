package com.bkes994408.expensetracker

import android.os.Bundle
import androidx.core.view.doOnPreDraw
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.telemetry.AnalyticsEvent
import com.bkes994408.expensetracker.telemetry.Telemetry

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.doOnPreDraw {
            Telemetry.markFirstFrameDrawn()
        }
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    ExpenseTrackerScreen()
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun ExpenseTrackerScreen() {
    val expenses = remember { mutableStateListOf<Int>() }
    var amountInput by remember { mutableStateOf("") }
    val monthlyTotal by remember(expenses) { derivedStateOf { expenses.sum() } }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = stringResource(R.string.monthly_overview, monthlyTotal),
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.testTag("monthly_total")
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = amountInput,
                onValueChange = { amountInput = it },
                label = { Text(stringResource(R.string.amount)) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier
                    .weight(1f)
                    .testTag("amount_input")
            )

            Button(
                onClick = {
                    val amount = amountInput.toIntOrNull()
                    if (amount == null) {
                        Telemetry.track(AnalyticsEvent.EXPENSE_ADD_INVALID)
                        return@Button
                    }
                    expenses.add(amount)
                    Telemetry.track(AnalyticsEvent.EXPENSE_ADDED, mapOf("amount" to amount.toString()))
                    amountInput = ""
                },
                modifier = Modifier.testTag("add_expense_button")
            ) {
                Text(stringResource(R.string.add_expense))
            }
        }
    }
}

package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.domain.Transaction
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: AppViewModel,
    onAdd: () -> Unit,
) {
    val list by viewModel.transactions.collectAsState()
    val error by viewModel.errorMessage.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Transactions") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = onAdd) {
                Icon(Icons.Filled.Add, contentDescription = "Add")
            }
        }
    ) { innerPadding ->
        if (list.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center,
            ) {
                Text("No transactions yet", style = MaterialTheme.typography.bodyLarge)
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    if (error != null) {
                        Text(
                            text = error!!,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
                items(items = list, key = { it.id }) { item ->
                    TransactionRow(
                        item = item,
                        onDelete = { viewModel.delete(item.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun TransactionRow(
    item: Transaction,
    onDelete: () -> Unit,
) {
    val amount = BigDecimal.valueOf(item.amountCents, 2)
    val currency = NumberFormat.getCurrencyInstance().format(amount)
    val dateText = Date(item.occurredAtEpochMillis).toString()

    androidx.compose.material3.Card {
        Box(modifier = Modifier.padding(16.dp)) {
            androidx.compose.foundation.layout.Column(
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(currency, style = MaterialTheme.typography.titleMedium)
                if (item.note.isNotBlank()) {
                    Text(item.note, style = MaterialTheme.typography.bodyMedium)
                }
                Text(dateText, style = MaterialTheme.typography.bodySmall)
            }

            IconButton(
                onClick = onDelete,
                modifier = Modifier.align(Alignment.TopEnd)
            ) {
                Icon(Icons.Filled.Delete, contentDescription = "Delete")
            }
        }
    }
}

package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.Button
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bkes994408.expensetracker.category.CategoryViewModel
import com.bkes994408.expensetracker.db.LocalStore
import com.bkes994408.expensetracker.pro.ProEntitlementStore

@Composable
fun SettingsScreen(
    proEntitlementStore: ProEntitlementStore,
) {
    val context = LocalContext.current
    val repository = LocalStore.getInstance(context).categoryRepository
    val viewModel: CategoryViewModel = viewModel(factory = CategoryViewModel.factory(repository))

    val categories by viewModel.categories.collectAsState()
    val nameInput by viewModel.nameInput.collectAsState()
    var entitlementVersion by remember { mutableStateOf(0) }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(text = "Pro tier: ${proEntitlementStore.tier.name}")
        if (proEntitlementStore.isPro) {
            Button(onClick = {
                proEntitlementStore.resetToFreeForDebug()
                entitlementVersion++
            }) {
                Text("Reset to FREE (Debug)")
            }
        }

        Text(text = "Category Management")

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                modifier = Modifier.weight(1f),
                value = nameInput,
                onValueChange = viewModel::onNameChanged,
                label = { Text("New category") },
                singleLine = true,
            )
            Button(onClick = viewModel::addCategory) {
                Text("Add")
            }
        }

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            itemsIndexed(categories, key = { _, item -> item.id }) { index, item ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(text = item.name)
                    Row {
                        IconButton(onClick = { viewModel.moveUp(item.id) }, enabled = index > 0) {
                            Text("↑")
                        }
                        IconButton(onClick = { viewModel.moveDown(item.id) }, enabled = index < categories.lastIndex) {
                            Text("↓")
                        }
                        IconButton(onClick = { viewModel.archive(item.id) }) {
                            Text("Archive")
                        }
                    }
                }
            }
        }

        Text(text = "Version: 0.0.1")
    }

    entitlementVersion
}

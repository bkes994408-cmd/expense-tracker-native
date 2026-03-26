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
    val localStore = LocalStore.getInstance(context)
    val viewModel: CategoryViewModel = viewModel(factory = CategoryViewModel.factory(localStore.categoryRepository))

    val categories by viewModel.categories.collectAsState()
    val nameInput by viewModel.nameInput.collectAsState()
    var entitlementVersion by remember { mutableStateOf(0) }
    val isPro = remember(entitlementVersion) { proEntitlementStore.isPro }
    val statusLabel = remember(entitlementVersion) { proEntitlementStore.statusLabel }

    var importInput by remember { mutableStateOf("") }
    var statusText by remember { mutableStateOf<String?>(null) }
    var exportText by remember { mutableStateOf("") }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item { Text(text = "Pro tier: $statusLabel") }
        if (isPro) {
            item {
                Button(onClick = {
                    proEntitlementStore.resetToFreeForDebug()
                    entitlementVersion++
                }) {
                    Text("Reset to FREE (Debug)")
                }
            }
        }

        item { Text(text = "Category Management") }
        item {
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
        }

        itemsIndexed(categories, key = { _, item -> item.id }) { index, item ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(text = item.name)
                Row {
                    IconButton(onClick = { viewModel.moveUp(item.id) }, enabled = index > 0) { Text("↑") }
                    IconButton(onClick = { viewModel.moveDown(item.id) }, enabled = index < categories.lastIndex) { Text("↓") }
                    IconButton(onClick = { viewModel.archive(item.id) }) { Text("Archive") }
                }
            }
        }

        item { Text("帳務導出（增強）") }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = {
                    exportText = localStore.expenseLedger.exportCsv()
                    statusText = "CSV 匯出完成"
                }) { Text("匯出 CSV") }
                Button(onClick = {
                    exportText = localStore.expenseLedger.exportJson()
                    statusText = "JSON 匯出完成"
                }) { Text("匯出 JSON") }
            }
        }

        item { Text("帳務導入（CSV / JSON 文字貼上）") }
        item {
            OutlinedTextField(
                modifier = Modifier.fillMaxWidth(),
                value = importInput,
                onValueChange = { importInput = it },
                minLines = 5,
                label = { Text("貼上資料") },
            )
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = {
                    val (ok, skip) = localStore.expenseLedger.importCsv(importInput)
                    statusText = "CSV 導入完成：成功 $ok，略過 $skip"
                }) { Text("導入 CSV") }
                Button(onClick = {
                    val (ok, skip) = localStore.expenseLedger.importJson(importInput)
                    statusText = "JSON 導入完成：成功 $ok，略過 $skip"
                }) { Text("導入 JSON") }
            }
        }

        if (exportText.isNotBlank()) {
            item {
                OutlinedTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = exportText,
                    onValueChange = {},
                    minLines = 5,
                    label = { Text("最近匯出內容") },
                )
            }
        }

        statusText?.let { text -> item { Text(text = text) } }
        item { Text(text = "Version: 0.0.1") }
    }
}

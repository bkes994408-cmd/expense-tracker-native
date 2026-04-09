package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
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
    var notifyEnabled by remember { mutableStateOf(true) }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Settings", style = MaterialTheme.typography.headlineSmall)
                Text("方案：$statusLabel", style = MaterialTheme.typography.bodyMedium, color = androidx.compose.ui.graphics.Color(0xFF6E778A))
            }
        }

        item {
            ReplicaSectionCard(title = "設定 / Pro", subtitle = "方案狀態與授權") {
                ReplicaListRow(title = "目前方案", subtitle = if (isPro) "已解鎖 Pro 功能" else "免費方案", trailing = statusLabel)
                if (isPro) {
                    Button(onClick = {
                        proEntitlementStore.resetToFreeForDebug()
                        entitlementVersion++
                    }) {
                        Text("Reset to FREE (Debug)")
                    }
                } else {
                    ReplicaStateBox(title = "Info", message = "升級 Pro 以解鎖進階報表與更多預算能力")
                }
            }
        }

        item {
            ReplicaSectionCard(title = "設定 / Category", subtitle = "分類管理") {
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
                    Button(onClick = viewModel::addCategory) { Text("Add") }
                }

                if (categories.isEmpty()) {
                    ReplicaStateBox(title = "Empty", message = "尚無分類，請先新增至少一個分類。")
                } else {
                    categories.forEachIndexed { index, item ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            ReplicaListRow(
                                title = item.name,
                                subtitle = "排序 ${index + 1}",
                                trailing = if (index == 0) "Top" else null,
                            )
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Button(onClick = { viewModel.moveUp(item.id) }, enabled = index > 0) { Text("↑") }
                            Button(onClick = { viewModel.moveDown(item.id) }, enabled = index < categories.lastIndex) { Text("↓") }
                            Button(onClick = { viewModel.archive(item.id) }) { Text("封存") }
                        }
                    }
                }
            }
        }

        item {
            ReplicaSectionCard(title = "設定 / 偏好", subtitle = "通知與顯示") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("提醒通知", style = MaterialTheme.typography.titleSmall)
                        Text("付款與帳單提醒", style = MaterialTheme.typography.bodySmall, color = androidx.compose.ui.graphics.Color(0xFF727C90))
                    }
                    Switch(checked = notifyEnabled, onCheckedChange = { notifyEnabled = it })
                }
            }
        }

        item {
            ReplicaSectionCard(title = "設定 / 匯入匯出", subtitle = "Transaction / Recurring Data") {
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

                OutlinedTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = importInput,
                    onValueChange = { importInput = it },
                    minLines = 5,
                    label = { Text("貼上 CSV / JSON") },
                )

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

                if (exportText.isNotBlank()) {
                    ReplicaStateBox(title = "最近匯出內容", message = exportText.take(260))
                }
            }
        }

        statusText?.let { text ->
            item {
                ReplicaStateBox(title = "狀態", message = text)
            }
        }

        item {
            ReplicaSectionCard(title = "Edge States") {
                ReplicaStateBox(title = "Loading", message = "同步設定中，請稍候...")
                ReplicaStateBox(title = "Error", message = "匯入資料解析失敗，請確認欄位與分隔符。")
                ReplicaListRow(
                    title = "Long text",
                    subtitle = "這是一段很長的設定說明，用於驗證 Android / iOS 在 cell 換行、高度與分組間距的一致性。",
                    trailing = "v0.0.1",
                )
            }
        }
    }
}

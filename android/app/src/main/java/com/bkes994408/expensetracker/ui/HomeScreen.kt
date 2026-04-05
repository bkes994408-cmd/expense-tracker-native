package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.BorderStroke
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.pro.ProEntitlementStore

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun HomeScreen(
    homeViewModel: HomeViewModel,
    proEntitlementStore: ProEntitlementStore,
    expenseRepository: ExpenseRepository,
    selectedTab: MainTab,
    onTabSelected: (MainTab) -> Unit,
    onFabClick: () -> Unit,
) {
    val entries by homeViewModel.entries.collectAsState()
    val titleInput by homeViewModel.titleInput.collectAsState()
    val amountInput by homeViewModel.amountInput.collectAsState()
    val predictedCategory by homeViewModel.predictedCategory.collectAsState()

    val monthlyExpense = homeViewModel.monthlySummary()
    val monthlyIncome = entries.filter { it.amount > java.math.BigDecimal.ZERO }
        .fold(java.math.BigDecimal.ZERO) { acc, entry -> acc + entry.amount }
    val monthlyNet = monthlyIncome + monthlyExpense

    var transactionFilter by remember { mutableStateOf("全部") }

    Scaffold(
        containerColor = Color(0xFFF4F6FB),
        floatingActionButton = {
            FloatingActionButton(
                onClick = onFabClick,
                containerColor = Color(0xFF2E2A73),
                contentColor = Color.White,
                elevation = FloatingActionButtonDefaults.elevation(defaultElevation = 12.dp),
            ) {
                Icon(Icons.Default.Add, contentDescription = "新增")
            }
        },
        bottomBar = {
            NavigationBar(
                containerColor = Color.White,
                tonalElevation = 4.dp,
            ) {
                NavigationBarItem(
                    selected = selectedTab == MainTab.Dashboard,
                    onClick = { onTabSelected(MainTab.Dashboard) },
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("Home") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Transactions,
                    onClick = { onTabSelected(MainTab.Transactions) },
                    icon = { Text("交") },
                    label = { Text("交易") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Reports,
                    onClick = { onTabSelected(MainTab.Reports) },
                    icon = { Text("報") },
                    label = { Text("報表") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Settings,
                    onClick = { onTabSelected(MainTab.Settings) },
                    icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                    label = { Text("設定") },
                )
            }
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text("Good evening", color = Color(0xFF677084), style = MaterialTheme.typography.bodyMedium)
                        Text("Bruce", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    }
                    Text("${proEntitlementStore.statusLabel} 方案", color = Color(0xFF8D95A5))
                }
            }

            item {
                Card(
                    shape = RoundedCornerShape(28.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                    elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(12.dp, RoundedCornerShape(28.dp), clip = false),
                ) {
                    Box(
                        modifier = Modifier
                            .background(
                                brush = Brush.linearGradient(
                                    listOf(Color(0xFF2A2F7D), Color(0xFF655BDF)),
                                ),
                            )
                            .padding(20.dp),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Text("Total Balance", color = Color(0xFFDCE0FF))
                            Text(
                                "NT$ $monthlyNet",
                                color = Color.White,
                                style = MaterialTheme.typography.headlineLarge,
                                fontWeight = FontWeight.ExtraBold,
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                                Column {
                                    Text("Income", color = Color(0xFFCFD4FF), style = MaterialTheme.typography.labelMedium)
                                    Text("$monthlyIncome", color = Color.White, fontWeight = FontWeight.SemiBold)
                                }
                                Column {
                                    Text("Expense", color = Color(0xFFCFD4FF), style = MaterialTheme.typography.labelMedium)
                                    Text("$monthlyExpense", color = Color.White, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                    }
                }
            }

            item {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    CompactStatCard("交易", entries.size.toString(), Modifier.weight(1.35f), emphasized = true)
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        CompactStatCard("預警", homeViewModel.alerts().size.toString(), emphasized = false)
                        CompactStatCard("建議", homeViewModel.suggestions().size.toString(), emphasized = false)
                    }
                }
            }

            item {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf(
                        MainTab.Dashboard to "Dashboard",
                        MainTab.Transactions to "Transactions",
                        MainTab.Reports to "Reports",
                    ).forEach { (tab, label) ->
                        FilterChip(
                            selected = selectedTab == tab,
                            onClick = { onTabSelected(tab) },
                            label = { Text(label) },
                            border = BorderStroke(1.dp, if (selectedTab == tab) Color(0xFF4A4FB4) else Color(0xFFD7DDED)),
                        )
                    }
                }
            }

            when (selectedTab) {
                MainTab.Dashboard -> {
                    item {
                        SectionCard("摘要") {
                            Text("本月支出：$monthlyExpense", fontWeight = FontWeight.SemiBold)
                            Text("最近新增 ${entries.takeLast(7).size} 筆交易", color = Color(0xFF6A7385))
                        }
                    }
                    item {
                        SectionCard("最近交易") {
                            if (entries.isEmpty()) {
                                Text("尚無資料", color = Color(0xFF7D8798))
                            } else {
                                entries.takeLast(5).reversed().forEach { entry ->
                                    TransactionRow(
                                        title = entry.title,
                                        subtitle = entry.category,
                                        amount = entry.amount.toPlainString(),
                                    )
                                }
                            }
                        }
                    }
                }

                MainTab.Transactions -> {
                    item {
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            listOf("全部", "固定支出", "最近7天", "Recurring").forEach { chip ->
                                FilterChip(
                                    selected = transactionFilter == chip,
                                    onClick = { transactionFilter = chip },
                                    label = { Text(chip) },
                                    border = BorderStroke(
                                        1.dp,
                                        if (transactionFilter == chip) Color(0xFF3D46A8) else Color(0xFFD7DDED),
                                    ),
                                )
                            }
                        }
                    }

                    item {
                        SectionCard("新增交易") {
                            OutlinedTextField(
                                modifier = Modifier.fillMaxWidth(),
                                value = titleInput,
                                onValueChange = homeViewModel::onTitleChanged,
                                label = { Text("項目") },
                                singleLine = true,
                            )
                            OutlinedTextField(
                                modifier = Modifier.fillMaxWidth(),
                                value = amountInput,
                                onValueChange = homeViewModel::onAmountChanged,
                                label = { Text("金額") },
                                singleLine = true,
                            )
                            predictedCategory?.let {
                                Text("AI 建議分類：${it.category}")
                            }
                            androidx.compose.material3.Button(onClick = homeViewModel::addExpense) {
                                Text("新增")
                            }
                        }
                    }

                    item {
                        SectionCard("交易列表") {
                            if (entries.isEmpty()) {
                                Text("尚無資料", color = Color(0xFF7D8798))
                            } else {
                                entries.takeLast(20).reversed().forEach { entry ->
                                    TransactionRow(
                                        title = entry.title,
                                        subtitle = entry.category,
                                        amount = entry.amount.toPlainString(),
                                    )
                                }
                            }
                        }
                    }

                    item {
                        SectionCard("Recurring") {
                            if (entries.isEmpty()) {
                                Text("尚無固定交易", color = Color(0xFF7D8798))
                            } else {
                                entries.takeLast(3).reversed().forEach { entry ->
                                    TransactionRow(
                                        title = entry.title,
                                        subtitle = "每月 · ${entry.category}",
                                        amount = entry.amount.toPlainString(),
                                    )
                                }
                            }
                        }
                    }
                }

                MainTab.Reports -> {
                    item {
                        SectionCard("Reports") {
                            Text("Sprint 1 聚焦 Home / Transactions，此處先保留既有功能。", color = Color(0xFF687287))
                        }
                    }
                }

                MainTab.Settings -> Unit
            }
        }
    }

    // 先保留 repository 參數，避免 Sprint 1 破壞既有相依注入。
    @Suppress("UNUSED_VARIABLE")
    val ignoreRepository = expenseRepository
}

@Composable
private fun CompactStatCard(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
    emphasized: Boolean = false,
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(if (emphasized) 22.dp else 18.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = if (emphasized) 6.dp else 2.dp),
    ) {
        Column(modifier = Modifier.padding(horizontal = 14.dp, vertical = if (emphasized) 18.dp else 12.dp)) {
            Text(title, color = Color(0xFF7B8393), style = MaterialTheme.typography.labelMedium)
            Text(
                value,
                style = if (emphasized) MaterialTheme.typography.headlineSmall else MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (emphasized) Color(0xFF2E2A73) else Color.Unspecified,
            )
        }
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            content()
        }
    }
}

@Composable
private fun TransactionRow(title: String, subtitle: String, amount: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(Color(0xFFF7F8FF))
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Color(0xFFE1E6FF)),
            contentAlignment = Alignment.Center,
        ) {
            Text(title.take(1), color = Color(0xFF2F3B91), fontWeight = FontWeight.Bold)
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyLarge)
            Text(subtitle, color = Color(0xFF7A8392), style = MaterialTheme.typography.bodySmall)
        }
        Text(
            text = if (amount.startsWith("-")) amount else "+$amount",
            color = if (amount.startsWith("-")) Color(0xFFE25353) else Color(0xFF2CA66A),
            fontWeight = FontWeight.ExtraBold,
            style = MaterialTheme.typography.titleMedium,
        )
    }
}

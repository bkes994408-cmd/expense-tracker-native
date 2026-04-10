package com.bkes994408.expensetracker.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.PressInteraction
import androidx.compose.foundation.interaction.collectIsPressedAsState
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
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.pro.ProEntitlementStore

private val AppBackground = Color(0xFFF4F6FB)
private val SubtleBorder = Color(0xFFE4E8F4)
private val IconBubble = Color(0xFFE6EBFF)
private val HeroStart = Color(0xFF1E255F)
private val HeroMiddle = Color(0xFF3E43A8)
private val HeroEnd = Color(0xFF6A5FF0)

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
    var reportRange by remember { mutableStateOf("1M") }

    Scaffold(
        containerColor = AppBackground,
        floatingActionButton = {
            FloatingActionButton(
                onClick = onFabClick,
                shape = CircleShape,
                containerColor = Color(0xFF2E2A73),
                contentColor = Color.White,
                elevation = FloatingActionButtonDefaults.elevation(defaultElevation = 10.dp),
            ) {
                Icon(Icons.Default.Add, contentDescription = "新增")
            }
        },
        bottomBar = {
            NavigationBar(
                containerColor = Color.White.copy(alpha = 0.96f),
                tonalElevation = 0.dp,
            ) {
                NavigationBarItem(
                    selected = selectedTab == MainTab.Dashboard,
                    onClick = { onTabSelected(MainTab.Dashboard) },
                    colors = navItemColors(),
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("Home") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Transactions,
                    onClick = { onTabSelected(MainTab.Transactions) },
                    colors = navItemColors(),
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("交易") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Reports,
                    onClick = { onTabSelected(MainTab.Reports) },
                    colors = navItemColors(),
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text("報表") },
                )
                NavigationBarItem(
                    selected = selectedTab == MainTab.Settings,
                    onClick = { onTabSelected(MainTab.Settings) },
                    colors = navItemColors(),
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
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 26.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
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
                    shape = RoundedCornerShape(30.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                    elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(18.dp, RoundedCornerShape(30.dp), clip = false),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                brush = Brush.linearGradient(
                                    listOf(HeroStart, HeroMiddle, HeroEnd),
                                ),
                            )
                            .padding(horizontal = 24.dp, vertical = 24.dp),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text("Total Balance", color = Color(0xFFDCE0FF), style = MaterialTheme.typography.titleSmall)
                            Text(
                                "NT$ $monthlyNet",
                                color = Color.White,
                                style = MaterialTheme.typography.headlineLarge,
                                fontWeight = FontWeight.ExtraBold,
                            )
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Column {
                                    Text("Income", color = Color(0xFFCFD4FF), style = MaterialTheme.typography.labelMedium)
                                    Text(
                                        "$monthlyIncome",
                                        color = Color.White,
                                        fontWeight = FontWeight.SemiBold,
                                        style = MaterialTheme.typography.titleMedium,
                                    )
                                }
                                Column {
                                    Text("Expense", color = Color(0xFFCFD4FF), style = MaterialTheme.typography.labelMedium)
                                    Text(
                                        "$monthlyExpense",
                                        color = Color.White,
                                        fontWeight = FontWeight.SemiBold,
                                        style = MaterialTheme.typography.titleMedium,
                                    )
                                }
                            }
                        }
                    }
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    CompactStatCard("交易", entries.size.toString(), Modifier.weight(1.35f), emphasized = true)
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        CompactStatCard("預警", homeViewModel.alerts().size.toString(), Modifier.fillMaxWidth(), emphasized = false)
                        CompactStatCard("建議", homeViewModel.suggestions().size.toString(), Modifier.fillMaxWidth(), emphasized = false)
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
                            shape = RoundedCornerShape(20.dp),
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = Color(0xFF3E43A8),
                                selectedLabelColor = Color.White,
                            ),
                            border = BorderStroke(1.dp, if (selectedTab == tab) Color(0xFF3E43A8) else SubtleBorder),
                        )
                    }
                }
            }

            when (selectedTab) {
                MainTab.Dashboard -> {
                    item {
                        SectionCard("摘要") {
                            Text("本月支出", color = Color(0xFF7D8798), style = MaterialTheme.typography.labelLarge)
                            Text("$monthlyExpense", fontWeight = FontWeight.ExtraBold, style = MaterialTheme.typography.headlineSmall)
                            Text("最近新增 ${entries.takeLast(7).size} 筆交易", color = Color(0xFF6A7385))
                        }
                    }
                    item {
                        SectionCard("最近交易") {
                            if (entries.isEmpty()) {
                                EmptyState(text = "尚無資料")
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
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            listOf("全部", "固定支出", "最近7天", "Recurring").forEach { chip ->
                                FilterChip(
                                    selected = transactionFilter == chip,
                                    onClick = { transactionFilter = chip },
                                    label = { Text(chip) },
                                    shape = RoundedCornerShape(20.dp),
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = Color(0xFF3E43A8),
                                        selectedLabelColor = Color.White,
                                    ),
                                    border = BorderStroke(
                                        1.dp,
                                        if (transactionFilter == chip) Color(0xFF3E43A8) else SubtleBorder,
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
                                shape = RoundedCornerShape(14.dp),
                            )
                            OutlinedTextField(
                                modifier = Modifier.fillMaxWidth(),
                                value = amountInput,
                                onValueChange = homeViewModel::onAmountChanged,
                                label = { Text("金額") },
                                singleLine = true,
                                shape = RoundedCornerShape(14.dp),
                            )
                            predictedCategory?.let {
                                Text("AI 建議分類：${it.category}", color = Color(0xFF505B71))
                            }
                            Button(onClick = homeViewModel::addExpense, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp)) {
                                Text("新增")
                            }
                        }
                    }

                    item {
                        SectionCard("交易列表") {
                            if (entries.isEmpty()) {
                                EmptyState(text = "尚無資料")
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
                                EmptyState(text = "尚無固定交易")
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
                        SectionCard("Reports", "Prototype parity Sprint 4") {
                            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                listOf("1M", "3M", "6M", "12M").forEach { chip ->
                                    FilterChip(
                                        selected = reportRange == chip,
                                        onClick = { reportRange = chip },
                                        label = { Text(chip) },
                                        shape = RoundedCornerShape(20.dp),
                                        colors = FilterChipDefaults.filterChipColors(
                                            selectedContainerColor = Color(0xFF3E43A8),
                                            selectedLabelColor = Color.White,
                                        ),
                                        border = BorderStroke(1.dp, if (reportRange == chip) Color(0xFF3E43A8) else SubtleBorder),
                                    )
                                }
                            }
                        }
                    }

                    item {
                        SectionCard("摘要") {
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                                CompactStatCard("平均收入", monthlyIncome.toPlainString(), Modifier.weight(1f))
                                CompactStatCard("平均支出", monthlyExpense.toPlainString(), Modifier.weight(1f))
                            }
                            val topCategory = entries.groupBy { it.category }.maxByOrNull { it.value.size }
                            ReplicaListRow(
                                title = "最多交易分類",
                                subtitle = topCategory?.key ?: "尚無資料",
                                trailing = topCategory?.value?.size?.toString() ?: "0",
                            )
                        }
                    }

                    item {
                        SectionCard("圖表與洞察") {
                            if (entries.isEmpty()) {
                                EmptyState(text = "尚無資料，新增交易後即可生成趨勢圖")
                            } else {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalAlignment = Alignment.Bottom,
                                ) {
                                    listOf(0.35f, 0.62f, 0.48f, 0.78f, 0.55f).forEach { ratio ->
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .height((96 * ratio).dp)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(Color(0xFFDCE3FF)),
                                        )
                                    }
                                }
                                ReplicaStateBox(
                                    title = "Insight",
                                    message = "本月淨額 ${monthlyNet.toPlainString()}，較上月變化待接入實際趨勢資料。",
                                )
                            }
                        }
                    }

                    item {
                        SectionCard("Edge States") {
                            ReplicaEdgeStates(
                                loadingMessage = "正在整理跨月份資料，請稍候...",
                                emptyMessage = "目前區間沒有可視化資料，請切換月份或新增交易。",
                                errorMessage = "報表資料暫時不可用，請稍後重試或檢查匯入資料格式。",
                                longTextMessage = "這是一段很長的設定說明文字，用於驗證 Android 與 iOS 在 row 高度、字重層級、換行間距是否維持一致。",
                                denseContentHint = "當資料密度較高時，優先保留標題與金額資訊，其餘內容以省略號收斂。",
                            )
                        }
                    }
                }

                MainTab.Settings -> Unit
            }
        }
    }

    @Suppress("UNUSED_VARIABLE")
    val ignoreRepository = expenseRepository
}

@Composable
private fun navItemColors() = NavigationBarItemDefaults.colors(
    selectedIconColor = Color(0xFF343B9D),
    selectedTextColor = Color(0xFF343B9D),
    indicatorColor = Color(0xFFE8ECFF),
    unselectedIconColor = Color(0xFF8A93A6),
    unselectedTextColor = Color(0xFF8A93A6),
)

@Composable
private fun CompactStatCard(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
    emphasized: Boolean = false,
) {
    Card(
        modifier = modifier.border(1.dp, SubtleBorder, RoundedCornerShape(if (emphasized) 22.dp else 18.dp)),
        shape = RoundedCornerShape(if (emphasized) 22.dp else 18.dp),
        colors = CardDefaults.cardColors(containerColor = ReplicaTokens.cardSurface),
        elevation = CardDefaults.cardElevation(defaultElevation = if (emphasized) 9.dp else 2.dp),
    ) {
        Column(modifier = Modifier.padding(horizontal = 14.dp, vertical = if (emphasized) 18.dp else 12.dp)) {
            Text(title, color = Color(0xFF7B8393), style = MaterialTheme.typography.labelMedium)
            Text(
                value,
                style = if (emphasized) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = if (emphasized) Color(0xFF2E2A73) else Color(0xFF212640),
            )
        }
    }
}

@Composable
private fun SectionCard(title: String, subtitle: String? = null, content: @Composable ColumnScope.() -> Unit) {
    ReplicaSectionCard(title = title, subtitle = subtitle) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            content()
        }
    }
}

@Composable
private fun EmptyState(text: String) {
    ReplicaStateBox(title = "Empty", message = text)
}

@Composable
private fun TransactionRow(title: String, subtitle: String, amount: String) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.985f else 1f, label = "rowScale")
    val bg by animateColorAsState(if (pressed) Color(0xFFEFF3FF) else Color(0xFFF7F8FF), label = "rowBg")

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(18.dp))
            .pointerInput(interaction) {
                detectTapGestures(
                    onPress = { offset ->
                        val press = PressInteraction.Press(offset)
                        interaction.emit(press)
                        if (tryAwaitRelease()) {
                            interaction.emit(PressInteraction.Release(press))
                        } else {
                            interaction.emit(PressInteraction.Cancel(press))
                        }
                    },
                )
            }
            .background(bg)
            .border(1.dp, Color(0xFFE7EBF8), RoundedCornerShape(18.dp))
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(IconBubble),
            contentAlignment = Alignment.Center,
        ) {
            Text(title.take(1), color = Color(0xFF2F3B91), fontWeight = FontWeight.Bold)
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(2.dp))
            Text(subtitle, color = Color(0xFF7A8392), style = MaterialTheme.typography.bodySmall)
        }
        Text(
            text = if (amount.startsWith("-")) amount else "+$amount",
            color = if (amount.startsWith("-")) Color(0xFFE25353) else Color(0xFF2CA66A),
            fontWeight = FontWeight.ExtraBold,
            style = MaterialTheme.typography.titleLarge,
        )
    }
}

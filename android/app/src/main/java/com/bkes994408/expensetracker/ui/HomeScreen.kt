package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.pro.AdvancedReport
import com.bkes994408.expensetracker.pro.AdvancedReportCalculator
import com.bkes994408.expensetracker.pro.ProEntitlementStore
import com.bkes994408.expensetracker.pro.ProFeature
import com.bkes994408.expensetracker.pro.ReportRange
import com.bkes994408.expensetracker.pro.TrendPoint
import java.math.BigDecimal
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
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

    val monthlySummary = homeViewModel.monthlySummary()
    val suggestions = homeViewModel.suggestions()
    val alerts = homeViewModel.alerts()

    var paywallTrigger by remember { mutableStateOf<String?>(null) }
    var entitlementVersion by remember { mutableStateOf(0) }
    var selectedRange by remember { mutableStateOf(ReportRange.ONE_MONTH) }

    val reportRanges = remember { ReportRange.values().toList() }

    val report by produceState(
        initialValue = AdvancedReport(
            averageIncome = BigDecimal.ZERO,
            averageExpense = BigDecimal.ZERO,
            averageNet = BigDecimal.ZERO,
            monthlyTrend = emptyList(),
            momDelta = null,
            yoyDelta = null,
            pieSlices = emptyList(),
        ),
        selectedRange,
        entitlementVersion,
    ) {
        val expenses = runCatching { expenseRepository.fetchExpenses() }.getOrDefault(emptyList())
        value = AdvancedReportCalculator.build(
            expenses,
            selectedRange,
            proEntitlementStore.canAccess(ProFeature.ADVANCED_REPORTS),
        )
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onFabClick) {
                Icon(Icons.Default.Add, contentDescription = "Add")
            }
        },
        bottomBar = {
            NavigationBar {
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
                    selected = false,
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
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item { Text("Expense Tracker", style = MaterialTheme.typography.headlineSmall) }

            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("本月總覽", style = MaterialTheme.typography.titleMedium)
                        Text("方案：${proEntitlementStore.statusLabel}")
                        Text("本月支出：$monthlySummary", style = MaterialTheme.typography.headlineSmall)
                    }
                }
            }

            when (selectedTab) {
                MainTab.Dashboard -> {
                    item {
                        SectionCard("預算提醒") {
                            if (alerts.isEmpty()) {
                                Text("目前無預警", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            } else {
                                alerts.forEach {
                                    val prefix = if (it.danger) "🚨" else "⚠️"
                                    Text("$prefix ${it.category}：${it.spent} / ${it.budget}")
                                }
                            }
                        }
                    }

                    item {
                        SectionCard("AI 建議") {
                            if (suggestions.isEmpty()) {
                                Text("資料不足，請先累積支出", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            } else {
                                suggestions.take(3).forEach {
                                    Text("${it.category}：建議 ${it.suggestedBudget}（基準 ${it.averageSpend}）")
                                }
                            }
                        }
                    }
                }

                MainTab.Transactions -> {
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
                                label = { Text("支出金額") },
                                singleLine = true,
                            )
                            predictedCategory?.let {
                                Text("AI 分類：${it.category}（${(it.confidence * 100).roundToInt()}%）")
                            }
                            Button(onClick = homeViewModel::addExpense) { Text("新增支出") }
                        }
                    }

                    item {
                        SectionCard("最近交易") {
                            if (entries.isEmpty()) {
                                Text("尚無資料", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            } else {
                                entries.takeLast(10).reversed().forEach {
                                    Text("• [${it.category}] ${it.title} ${it.amount}")
                                }
                            }
                        }
                    }
                }

                MainTab.Reports -> {
                    item {
                        SectionCard("區間") {
                            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                                reportRanges.forEachIndexed { index: Int, range: ReportRange ->
                                    SegmentedButton(
                                        selected = selectedRange == range,
                                        onClick = {
                                            if (range.months > 1 && !proEntitlementStore.canAccess(ProFeature.ADVANCED_REPORTS)) {
                                                paywallTrigger = "advanced_report_3m"
                                            } else {
                                                selectedRange = range
                                            }
                                        },
                                        shape = androidx.compose.material3.SegmentedButtonDefaults.itemShape(
                                            index = index,
                                            count = reportRanges.size,
                                        ),
                                    ) { Text("${range.months}M") }
                                }
                            }
                        }
                    }

                    item {
                        SectionCard("趨勢摘要") {
                            Text("平均月收入：${report.averageIncome}")
                            Text("平均月支出：${report.averageExpense}")
                            Text("平均月淨額：${report.averageNet}")
                            Text("MoM：${report.momDelta?.toPlainString() ?: "暫無"}")
                            Text("YoY：${report.yoyDelta?.toPlainString() ?: "暫無"}")
                        }
                    }

                    if (report.monthlyTrend.isNotEmpty()) {
                        item {
                            SectionCard("趨勢圖") { TrendChart(report.monthlyTrend) }
                        }
                    }

                    if (report.pieSlices.isNotEmpty()) {
                        item {
                            SectionCard("收支占比") { PieChart(report = report) }
                        }
                    }
                }

                MainTab.Settings -> Unit
            }

            item {
                Button(onClick = {
                    openProFeature("budget_limit", ProFeature.UNLIMITED_BUDGETS, proEntitlementStore) { paywallTrigger = it }
                }) { Text("建立第 3 個分類預算（示範）") }
            }
        }
    }

    paywallTrigger?.let { trigger ->
        PaywallDialog(
            trigger = trigger,
            proEntitlementStore = proEntitlementStore,
            onDismiss = { paywallTrigger = null },
            onEntitlementChanged = { entitlementVersion++ },
        )
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp), content = content)
    }
}

@Composable
private fun TrendChart(points: List<TrendPoint>) {
    val maxValue = points.maxOfOrNull { maxOf(it.income, it.expense, it.net) } ?: BigDecimal.ONE
    val safeMax = if (maxValue <= BigDecimal.ZERO) BigDecimal.ONE else maxValue

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp),
    ) {
        if (points.size <= 1) return@Canvas

        val stepX = size.width / (points.size - 1)
        val chartHeight = size.height - 24f

        fun yFor(value: BigDecimal): Float {
            val ratio = value.toFloat() / safeMax.toFloat()
            return chartHeight - (chartHeight * ratio)
        }

        fun drawSeries(values: List<BigDecimal>, color: Color) {
            values.zipWithNext().forEachIndexed { index, pair ->
                val start = Offset(index * stepX, yFor(pair.first))
                val end = Offset((index + 1) * stepX, yFor(pair.second))
                drawLine(color = color, start = start, end = end, strokeWidth = 4f, cap = StrokeCap.Round)
            }
        }

        drawSeries(points.map { it.income }, Color(0xFF1E88E5))
        drawSeries(points.map { it.expense }, Color(0xFFE53935))
        drawSeries(points.map { it.net }, Color(0xFF43A047))
    }

    Spacer(Modifier.height(8.dp))
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("🔵 收入")
        Text("🔴 支出")
        Text("🟢 淨額")
    }
}

@Composable
private fun PieChart(report: AdvancedReport) {
    val total = report.pieSlices.fold(BigDecimal.ZERO) { acc, slice -> acc + slice.value }
    if (total <= BigDecimal.ZERO) return

    Canvas(modifier = Modifier.size(180.dp)) {
        var startAngle = -90f
        report.pieSlices.forEachIndexed { index, slice ->
            val sweep = (slice.value.toFloat() / total.toFloat()) * 360f
            drawArc(
                color = chartColor(index),
                startAngle = startAngle,
                sweepAngle = sweep,
                useCenter = false,
                topLeft = Offset(12f, 12f),
                size = Size(size.width - 24f, size.height - 24f),
                style = Stroke(width = 30f),
            )
            startAngle += sweep
        }
    }
}

private fun chartColor(index: Int): Color {
    val palette = listOf(Color(0xFF1E88E5), Color(0xFFE53935), Color(0xFF43A047), Color(0xFFFDD835))
    return palette[index % palette.size]
}

private fun openProFeature(
    trigger: String,
    feature: ProFeature,
    proEntitlementStore: ProEntitlementStore,
    onPaywallNeeded: (String) -> Unit,
) {
    if (!proEntitlementStore.canAccess(feature)) {
        onPaywallNeeded(trigger)
    }
}

package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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

@Composable
fun HomeScreen(
    homeViewModel: HomeViewModel,
    onOpenSettings: () -> Unit,
    proEntitlementStore: ProEntitlementStore,
    expenseRepository: ExpenseRepository,
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

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.Start,
    ) {
        item { Text(text = "Expense Tracker") }
        item { Text(text = "目前方案：${proEntitlementStore.statusLabel}") }
        item { Text(text = "本月支出：$${monthlySummary}") }

        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
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
                    Text("AI 分類：${it.category}（信心 ${(it.confidence * 100).roundToInt()}%）")
                }
                Button(onClick = homeViewModel::addExpense) { Text("新增支出") }
                Button(onClick = onOpenSettings) { Text("Go to Settings") }
            }
        }

        item { Text("預算智能建議") }
        if (suggestions.isEmpty()) {
            item { Text("資料不足，請先累積過往支出") }
        } else {
            items(suggestions.take(3)) {
                Text("${it.category}: 建議 ${it.suggestedBudget}（基準 ${it.averageSpend}，趨勢 ${it.trend}）")
            }
        }

        item { Text("超支預警") }
        if (alerts.isEmpty()) {
            item { Text("目前無預警") }
        } else {
            items(alerts) {
                val prefix = if (it.danger) "🚨" else "⚠️"
                Text("$prefix ${it.category}：${it.spent} / ${it.budget}")
            }
        }

        item {
            Button(onClick = {
                openProFeature("budget_limit", ProFeature.UNLIMITED_BUDGETS, proEntitlementStore) { paywallTrigger = it }
            }) {
                Text(text = "建立第 3 個分類預算（示範）")
            }
        }

        item { Text(text = "進階報表：區間 ${selectedRange.months}M") }
        item {
            Button(onClick = {
                when (val result = HomeReportController.nextRange(
                    selectedRange,
                    proEntitlementStore.canAccess(ProFeature.ADVANCED_REPORTS),
                )) {
                    is RangeSelectionResult.RangeSelected -> selectedRange = result.range
                    is RangeSelectionResult.PaywallRequired -> paywallTrigger = result.trigger
                }
            }) {
                Text(text = "切換報表區間")
            }
        }
        item { Text(text = "平均月收入：${report.averageIncome}") }
        item { Text(text = "平均月支出：${report.averageExpense}") }
        item { Text(text = "平均月淨額：${report.averageNet}") }

        item {
            Text(
                text = "MoM（本月淨額較上月）：${report.momDelta?.toPlainString() ?: "暫無"}",
                style = MaterialTheme.typography.bodyMedium,
            )
        }
        item {
            Text(
                text = "YoY（本月淨額較去年同月）：${report.yoyDelta?.toPlainString() ?: "暫無"}",
                style = MaterialTheme.typography.bodyMedium,
            )
        }

        if (report.monthlyTrend.isNotEmpty()) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("趨勢圖分析")
                    TrendChart(report.monthlyTrend)
                    report.monthlyTrend.forEach { point ->
                        Text("${point.monthLabel} 收${point.income} / 支${point.expense} / 淨${point.net}")
                    }
                }
            }
        }

        if (report.pieSlices.isNotEmpty()) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("圓餅圖分析（收入/支出占比）")
                    PieChart(report = report)
                    report.pieSlices.forEachIndexed { index, slice ->
                        val percent = piePercent(report, slice.value)
                        Text("${chartColorName(index)} ${slice.label}：${slice.value}（${percent}%）")
                    }
                }
            }
        }

        item {
            Button(onClick = {
                openProFeature("report_pdf_export", ProFeature.PDF_EXPORT, proEntitlementStore) { paywallTrigger = it }
            }) {
                Text(text = "匯出 PDF 報表（示範）")
            }
        }

        item { Text("最近帳目（${entries.size}）") }
        items(entries.takeLast(5).reversed()) {
            Text("• [${it.category}] ${it.title} ${it.amount}")
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

private fun chartColorName(index: Int): String = when (index % 4) {
    0 -> "🔵"
    1 -> "🔴"
    2 -> "🟢"
    else -> "🟡"
}

private fun piePercent(report: AdvancedReport, value: BigDecimal): Int {
    val total = report.pieSlices.fold(BigDecimal.ZERO) { acc, slice -> acc + slice.value }
    if (total == BigDecimal.ZERO) return 0
    return ((value.toDouble() / total.toDouble()) * 100).roundToInt()
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

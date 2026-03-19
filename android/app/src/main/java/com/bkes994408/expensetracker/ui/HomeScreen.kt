package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
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
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.domain.ExpenseRepository
import com.bkes994408.expensetracker.pro.AdvancedReport
import com.bkes994408.expensetracker.pro.AdvancedReportCalculator
import com.bkes994408.expensetracker.pro.ProEntitlementStore
import com.bkes994408.expensetracker.pro.ProFeature
import com.bkes994408.expensetracker.pro.ReportRange
import java.math.BigDecimal

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

    val monthlySummary = homeViewModel.monthlySummary()
    val suggestions = homeViewModel.suggestions()
    val alerts = homeViewModel.alerts()

    var paywallTrigger by remember { mutableStateOf<String?>(null) }
    var entitlementVersion by remember { mutableStateOf(0) }
    var selectedRange by remember { mutableStateOf(ReportRange.ONE_MONTH) }

    val report by produceState(
        initialValue = AdvancedReport(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO),
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
                Button(onClick = homeViewModel::addExpense) { Text("新增支出") }
                Button(onClick = onOpenSettings) { Text("Go to Settings") }
            }
        }

        item { Text("預算智能建議") }
        if (suggestions.isEmpty()) {
            item { Text("資料不足，請先累積過往支出") }
        } else {
            items(suggestions.take(3)) {
                Text("${it.category}: 建議 ${it.suggestedBudget}（近 3 月平均 ${it.averageSpend}）")
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
            Button(onClick = {
                openProFeature("report_pdf_export", ProFeature.PDF_EXPORT, proEntitlementStore) { paywallTrigger = it }
            }) {
                Text(text = "匯出 PDF 報表（示範）")
            }
        }

        item { Text("最近帳目（${entries.size}）") }
        items(entries.takeLast(5).reversed()) {
            Text("• ${it.title} ${it.amount}")
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

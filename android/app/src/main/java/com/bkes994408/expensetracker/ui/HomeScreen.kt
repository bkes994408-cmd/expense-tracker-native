package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import com.bkes994408.expensetracker.pro.ReportRange
import java.math.BigDecimal

@Composable
fun HomeScreen(
    onOpenSettings: () -> Unit,
    proEntitlementStore: ProEntitlementStore,
    expenseRepository: ExpenseRepository,
) {
    var paywallTrigger by remember { mutableStateOf<String?>(null) }
    var entitlementVersion by remember { mutableStateOf(0) }
    var selectedRange by remember { mutableStateOf(ReportRange.ONE_MONTH) }

    val report by produceState(
        initialValue = AdvancedReport(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO),
        selectedRange,
        entitlementVersion,
    ) {
        val expenses = runCatching { expenseRepository.fetchExpenses() }.getOrDefault(emptyList())
        value = AdvancedReportCalculator.build(expenses, selectedRange, proEntitlementStore.isPro)
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = "Expense Tracker")
        Text(text = "目前方案：${proEntitlementStore.tier.name}")

        Button(onClick = { openProFeature("budget_limit", proEntitlementStore) { paywallTrigger = it } }) {
            Text(text = "建立第 3 個分類預算（示範）")
        }

        Text(text = "進階報表：區間 ${selectedRange.months}M")
        Button(onClick = {
            when (val result = HomeReportController.nextRange(selectedRange, proEntitlementStore.isPro)) {
                is RangeSelectionResult.RangeSelected -> selectedRange = result.range
                is RangeSelectionResult.PaywallRequired -> paywallTrigger = result.trigger
            }
        }) {
            Text(text = "切換報表區間")
        }
        Text(text = "平均月收入：${report.averageIncome}")
        Text(text = "平均月支出：${report.averageExpense}")
        Text(text = "平均月淨額：${report.averageNet}")

        Button(onClick = { openProFeature("report_pdf_export", proEntitlementStore) { paywallTrigger = it } }) {
            Text(text = "匯出 PDF 報表（示範）")
        }

        Button(onClick = onOpenSettings) {
            Text(text = "Go to Settings")
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

    entitlementVersion
}

private fun openProFeature(
    trigger: String,
    proEntitlementStore: ProEntitlementStore,
    onPaywallNeeded: (String) -> Unit,
) {
    if (!proEntitlementStore.isPro) {
        onPaywallNeeded(trigger)
    }
}

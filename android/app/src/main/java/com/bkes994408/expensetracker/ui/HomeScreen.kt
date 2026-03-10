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
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.pro.ProEntitlementStore

@Composable
fun HomeScreen(
    onOpenSettings: () -> Unit,
    proEntitlementStore: ProEntitlementStore,
) {
    var paywallTrigger by remember { mutableStateOf<String?>(null) }
    var entitlementVersion by remember { mutableStateOf(0) }

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
        Button(onClick = { openProFeature("advanced_report_3m", proEntitlementStore) { paywallTrigger = it } }) {
            Text(text = "查看 3 個月以上趨勢圖（示範）")
        }
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

    // Keep state read in composition to update UI text when entitlement changed.
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

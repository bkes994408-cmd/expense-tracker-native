package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bkes994408.expensetracker.pro.PaywallExperience
import com.bkes994408.expensetracker.pro.ProEntitlementStore
import com.bkes994408.expensetracker.telemetry.AnalyticsEvent
import com.bkes994408.expensetracker.telemetry.Telemetry

@Composable
fun PaywallDialog(
    trigger: String,
    proEntitlementStore: ProEntitlementStore,
    onDismiss: () -> Unit,
    onEntitlementChanged: () -> Unit,
) {
    val content = PaywallExperience.content(trigger)
    LaunchedEffect(trigger) {
        Telemetry.track(AnalyticsEvent.PRO_PAYWALL_VIEWED, mapOf("trigger" to trigger))
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(content.headline) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(content.subheadline)
                Text("觸發來源：$trigger")
                Text(content.recommendedPlanLabel)
                Text("• 可建立不限數量分類預算")
                Text("• 可查看 3/6/12 個月趨勢")
                Text("• 可匯出 PDF 進階報表")
                proEntitlementStore.lastError?.let { Text("錯誤：$it") }
            }
        },
        confirmButton = {
            Column(
                modifier = Modifier.fillMaxWidth().padding(bottom = 4.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Button(onClick = {
                    Telemetry.track(AnalyticsEvent.PRO_PAYWALL_CTA_TAPPED, mapOf("trigger" to trigger, "cta" to "trial"))
                    proEntitlementStore.startTrial()
                    onEntitlementChanged()
                    if (proEntitlementStore.isPro) onDismiss()
                }) { Text("開始 7 天免費試用") }
                Button(onClick = {
                    Telemetry.track(AnalyticsEvent.PRO_PAYWALL_CTA_TAPPED, mapOf("trigger" to trigger, "cta" to "monthly"))
                    proEntitlementStore.subscribeMonthly()
                    onEntitlementChanged()
                    if (proEntitlementStore.isPro) onDismiss()
                }) { Text("月付 NT$90") }
                Button(onClick = {
                    Telemetry.track(AnalyticsEvent.PRO_PAYWALL_CTA_TAPPED, mapOf("trigger" to trigger, "cta" to "yearly"))
                    proEntitlementStore.subscribeYearly()
                    onEntitlementChanged()
                    if (proEntitlementStore.isPro) onDismiss()
                }) { Text("年付 NT$790") }
                TextButton(onClick = {
                    Telemetry.track(AnalyticsEvent.PRO_PAYWALL_CTA_TAPPED, mapOf("trigger" to trigger, "cta" to "restore"))
                    proEntitlementStore.restorePurchase()
                    onEntitlementChanged()
                    if (proEntitlementStore.isPro) onDismiss()
                }) { Text("恢復購買") }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("關閉")
            }
        },
    )
}

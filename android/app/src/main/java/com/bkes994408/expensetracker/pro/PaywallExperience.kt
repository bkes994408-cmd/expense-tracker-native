package com.bkes994408.expensetracker.pro

data class PaywallExperienceContent(
    val headline: String,
    val subheadline: String,
    val recommendedPlanLabel: String,
)

object PaywallExperience {
    fun content(trigger: String): PaywallExperienceContent {
        return when (trigger) {
            "budget_limit", "budget_limit_copy_last_month" -> PaywallExperienceContent(
                headline = "解鎖不限分類預算",
                subheadline = "避免預算斷點，讓每個分類都能被追蹤。",
                recommendedPlanLabel = "建議年付方案（最省）",
            )
            "advanced_report_3m" -> PaywallExperienceContent(
                headline = "解鎖長區間趨勢分析",
                subheadline = "一次看懂 3/6/12 個月收支變化與風險。",
                recommendedPlanLabel = "建議月付方案（先用先升級）",
            )
            "report_pdf_export" -> PaywallExperienceContent(
                headline = "解鎖 PDF 專業報表",
                subheadline = "快速匯出可分享報表，回顧與對帳更省時。",
                recommendedPlanLabel = "建議年付方案（含完整報表能力）",
            )
            else -> PaywallExperienceContent(
                headline = "升級 Pro，解鎖進階理財能力",
                subheadline = "升級後可使用完整預算、分析與報表功能。",
                recommendedPlanLabel = "月付或年付皆可",
            )
        }
    }
}

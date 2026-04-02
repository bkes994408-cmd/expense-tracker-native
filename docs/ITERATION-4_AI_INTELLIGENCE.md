# Iteration-4 AI 智能應用（iOS + Android）

## 已完成範圍

### 1) 基於歷史消費的 AI 預算建議
- Android：新增 `BudgetIntelligenceEngine`，採用 **6 個月加權平均 + 動能趨勢**（最新月相對前月）計算建議預算。
- iOS：新增 `ExpenseAIIntelligence.buildBudgetDraft`，同樣採用加權平均與趨勢修正，輸出 `BudgetDraftSuggestion`。

### 2) On-device ML 自動分類（Core ML / TFLite-ready）
- Android：新增 `OnDeviceCategoryClassifier` 抽象與 `HybridCategoryClassifier`，流程為 **TFLite（預留）→ Keyword fallback**。
- iOS：新增 `OnDeviceExpenseCategorizing` 與 `HybridOnDeviceExpenseCategorizer`，流程為 **Core ML（若模型存在）→ Keyword fallback**。
- iOS `ExpenseListViewModel` 新增自動分類流程：新增支出時先做分類預測，若分類不存在會自動建立分類並寫入 categoryId。
- Android `HomeViewModel` 新增輸入即時分類預測，新增帳目時帶入預測分類。

### 3) 超支預測與自動化預算草案生成
- Android：`forecastOverspend` 依當月已過天數推估月底支出（spend pace projection），超過 80% 風險即告警。
- iOS：`ExpenseAIIntelligence.forecastOverspend` 同樣以月度支出速度推估，產生 `OverspendForecast`。

## 主要檔案
- Android
  - `android/app/src/main/java/com/bkes994408/expensetracker/ai/OnDeviceCategoryClassifier.kt`
  - `android/app/src/main/java/com/bkes994408/expensetracker/ai/BudgetIntelligenceEngine.kt`
  - `android/app/src/main/java/com/bkes994408/expensetracker/db/ExpenseLedger.kt`
  - `android/app/src/main/java/com/bkes994408/expensetracker/ui/HomeViewModel.kt`
  - `android/app/src/main/java/com/bkes994408/expensetracker/ui/HomeScreen.kt`
  - `android/app/src/test/java/com/bkes994408/expensetracker/db/ExpenseLedgerAiTest.kt`
- iOS
  - `ios/ExpenseTracker/Expense/ExpenseAIIntelligence.swift`
  - `ios/ExpenseTracker/Expense/ExpenseListViewModel.swift`
  - `ios/ExpenseTracker/UI/HomeView.swift`
  - `ios/ExpenseTracker/UI/RootView.swift`
  - `ios/ExpenseTrackerTests/Expense/ExpenseAIIntelligenceTests.swift`

## 驗證
- Android 單元測試新增：`ExpenseLedgerAiTest`
- 注意：目前此環境執行 Gradle 測試遭遇本機 Java/Gradle 版本解析錯誤：`IllegalArgumentException: 25.0.2`，需在 CI 或本機修正 Java/Gradle 設定後重跑。

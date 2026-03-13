# Sprint Result - MVP-6（進階報表與數據分析功能收斂）

日期：2026-03-13

## 完成項目（DoD 對照）

1. **Android 進階報表功能補強完成**
   - `HomeScreen` 以 `ExpenseRepository.fetchExpenses()` 讀取持久化帳目資料，交由 `AdvancedReportCalculator` 計算 1M/3M/6M/12M 區間平均收入、支出、淨額。
   - `HomeReportController` 完整管理區間切換與 Free/Pro gating（Free 只能 1M，切到 3M+ 觸發 paywall）。
   - UI 層清理不必要狀態讀取 hack，維持功能一致並降低 Compose warning。

2. **資料來源與邏輯正確性驗證**
   - `FileExpenseStore`：驗證檔案不存在時回傳空清單、存在時正確讀取 persisted JSON。
   - `ExpenseRepositoryImpl`：驗證 repository 直接回傳持久化資料來源內容。
   - `AdvancedReportCalculator`：驗證 createdAt 區間過濾與 Pro/Free 月區間差異。

3. **測試補強與回歸**
   - 新增 `HomeReportControllerTest`，覆蓋：
     - Free 由 1M 切換時必定觸發 `advanced_report_3m` paywall。
     - Pro 可完整循環 1M→3M→6M→12M→1M。
   - 既有整合測試 `HomeReportIntegrationTest` 持續覆蓋資料異動後報表更新與 gating 行為。

4. **Roadmap 與文件證據更新**
   - `docs/ROADMAP.md`：MVP-6「進階報表與數據分析功能」已勾選完成。
   - 本文件作為本輪 Android 補強與 DoD 達成證據。

## 測試指令與結果

> 執行環境注意：需使用 Android Studio JBR（Java 21）與本機 Android SDK。

```bash
cd android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
./gradlew app:testDebugUnitTest \
  --tests "*AdvancedReportCalculatorTest" \
  --tests "*HomeReportIntegrationTest" \
  --tests "*HomeReportControllerTest" \
  --tests "*FileExpenseStoreTest" \
  --tests "*ExpenseRepositoryImplTest" \
  --tests "*ProEntitlementStoreTest"
```

結果：**BUILD SUCCESSFUL**。

## 已知限制

- 進階報表目前為平均值摘要（income/expense/net）；尚未加入更細維度圖表（例如 category-level trend chart）與匯出視覺化報表。
- 單元測試執行對 JDK 版本敏感；若使用系統預設 Java 25，Gradle Kotlin DSL 會因版本解析問題失敗（需切換 Java 21）。

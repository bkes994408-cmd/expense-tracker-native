# Sprint Result - MVP-7（Web Report Center Free/Pro 權限切片）

日期：2026-03-22

## 完成項目（safe vertical slice）

1. **Web 報表中心方案權限對齊**
   - 新增 `web/src/lib/entitlement.ts`，統一 `Free/Pro` 區間權限判斷。
   - `App.tsx` 新增方案切換（Free / Pro），預設 Free。
   - Free 僅允許 `1M`，`3M / 6M / 12M` 在下拉選單中標記 `（Pro）` 並鎖定。
   - 由 Pro 切回 Free 時自動回落 `1M`，避免保留不可用區間。

2. **測試補強**
   - `web/src/__tests__/app.test.tsx` 新增案例：
     - 預設 Free 狀態顯示提示文案，且 3M option disabled。
     - 切到 Pro 後可選 3M，摘要數值正確更新。

3. **文件更新**
   - `docs/ROADMAP.md`：Iteration-7 的 Web 報表中心項目標記為已完成（含 Free/Pro gating）。
   - `docs/WEB_REPORT_CENTER_MVP.md`：補充 entitlement gating 行為與後續 TODO 調整。

## 驗證指令與結果

```bash
cd web
npm test
npm run build
```

結果：測試全綠、build 成功。

---

# Sprint Result - Iteration-6（成長與變現優化）

日期：2026-03-20

## 完成項目（usable increment）

1. **年度財務回顧（Wrapped）**
   - iOS 新增 `AnnualWrappedReportBuilder`；Android 新增 `AnnualWrappedCalculator`。
   - 產出年度收入/支出/淨額、儲蓄率、支出最高分類、最佳/艱困月份。

2. **歷史快照備份與還原（Snapshot）**
   - iOS 新增 `ExpenseSnapshotService`，支援 JSON 匯出與還原。
   - Android 新增 `ExpenseSnapshotManager`，可將 `ExpenseLedger` 完整快照並一鍵還原。

3. **訂閱挽留與續訂策略（Retention Strategy）**
   - iOS 新增 `RetentionStrategy`（trial 最後 48h / trial 到期 winback / monthly 轉年付）。
   - Android 新增 `retentionStrategy()` 擴充，輸出 headline/cta/offer code。

4. **測試**
   - iOS：`Iteration6FeatureTests`（Wrapped、Snapshot round-trip、Retention offer）。
   - Android：`Iteration6FeatureTest`（Wrapped、Snapshot restore、Retention offer）。

# Sprint Result - MVP-7（進階視覺化報表與圖表）

日期：2026-03-14

## 完成項目（usable increment）

1. **iOS 進階圖表視覺化（本輪 scope）**
   - `HomeView` 進階報表區塊新增 `Charts` 圖表渲染。
   - 新增「圖表類型」切換：`折線圖` / `長條圖`。
   - 新增「資料篩選」選項：`全部` / `僅收入` / `僅支出` / `僅淨額`。
   - 既有區間選擇（1M/3M/6M/12M）與 Free/Pro gating 保持不變。

2. **測試補強**
   - `BudgetViewModelTests` 新增：
     - `testAdvancedReportMetricFilterKeepsOnlyIncomeSeries`
     - `testAdvancedReportMetricFilterAllContainsThreeSeriesPerMonth`
   - 驗證自定義篩選會產生正確的圖表 series。

3. **跨平台 scope 說明**
   - **本輪僅 iOS 落地**（UI 與視覺化邏輯）。
   - Android 本輪未改動，維持 MVP-6 的摘要報表呈現。

---

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

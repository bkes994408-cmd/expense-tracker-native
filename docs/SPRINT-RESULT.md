# Sprint Result - Iteration-7（跨平台擴展）

日期：2026-03-20

## 完成項目（usable increment）

1. **Web 報表中心（React + TypeScript）**
   - 新增 `web-report-center/`（Vite + React + TS）。
   - 提供月總覽（收入/支出/淨額/筆數）、報表篩選（全部/僅收入/僅支出/僅淨額）、CSV 匯出。
   - 實作 Web Pro gating 展示（Free 顯示鎖定提示，Pro 顯示進階報表可用）。

2. **Desktop 快速輸入工具（Tauri Menu Bar）**
   - 新增 `desktop-quick-entry/`，包含 `web/` 前端與 `src-tauri/` shell。
   - Rust 端建立 tray menu（顯示視窗/離開）與 `quick_add_expense` command。
   - 前端快速輸入表單可呼叫 command，完成 Menu Bar 快速記帳基礎流程。

3. **跨裝置雲端同步架構基礎（SyncMutation / SyncCursor / SyncTransport）**
   - 新增 `shared/cloud-sync/` TypeScript 模組。
   - 建立 `SyncMutation`、`SyncCursor`、`SyncTransport` 協議型別。
   - 實作 `InMemorySyncStateStore`、`InMemorySyncTransport`、`SyncEngine`（stage mutation + push/pull + cursor 更新）。
   - 新增 `tests/syncEngine.test.ts` 驗證同步主流程。

## 測試與驗證

```bash
# sync 架構單元測試
cd shared/cloud-sync
npm install
npm test

# Web 報表中心 build
cd ../../web-report-center
npm install
npm run build

# Desktop quick entry 前端 build
cd ../desktop-quick-entry/web
npm install
npm run build
```

結果：三組指令皆成功（build/test 綠燈）。

## 已知限制

- `desktop-quick-entry/src-tauri` 尚未在本機執行 `cargo check`（環境缺少 cargo）。
- `quick_add_expense` 目前先記錄 payload，下一步需串接 `SyncMutation` enqueue 與本地 store。
- Web 報表中心目前使用 seed data，下一步需接入實際 API / Sync pull 結果。

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

---

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

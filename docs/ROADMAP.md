# Roadmap / MVP Checklist（記帳APP：原生 iOS + Android）

> 目標：先達成「可用 MVP」+ 完整功能測試基礎，再談進階同步/效能。

## MVP-0：專案初始化（門檻）
- [x] iOS 專案建立（Xcode / Swift）可編譯執行
- [x] Android 專案建立（Gradle / Kotlin）可編譯執行
- [x] 基礎架構：網路層、資料層（本機 DB）、Domain 層、UI 層
- [x] CI：iOS build + Android build（GitHub Actions）

## MVP-1：核心功能（離線優先）
- [x] 帳目 CRUD（第一階段：新增/列表/刪除，更新接口已預留）
- [x] 分類管理（第一階段：新增/列表，封存/排序保留介面並可擴充）
- [x] 帳目列表篩選/搜尋（第一階段：標題搜尋）
- [x] 每月總覽（收入/支出/分類彙總）
- [x] 訂閱管理（週期、下次扣款、提醒）
- [x] 分期管理（期數/每期/剩餘/本月應繳）
- [x] 匯出（CSV，iOS 端最小可用：產生 CSV + ShareLink 匯出）

## MVP-2：雲端同步（後續可拆）
- [x] Auth（註冊/登入，先以本地 Mock 流程完成骨架）
- [x] Delta sync（mutations + cursor 資料模型骨架）
- [x] 衝突偵測與處理（version/updatedAt）

## MVP-3：完整功能測試（必備）
- [x] iOS：至少 1 條 UI 測試（新增帳目→月總覽數字變更）
- [x] Android：至少 1 條 UI 測試（同流程）
- [x] 同步（若有）：至少 1 條 integration 測試（兩端資料一致）
- [x] 安全：Keychain/Keystore、TLS、log 脫敏

## MVP-4：上架準備
- [x] 隱私政策/資料刪除流程
- [x] Crash/analytics（可選）
- [x] Release checklist
- [x] 應用程式效能優化 (啟動時間、記憶體使用)
- [x] 多語言支援

## MVP-5：用戶體驗與增長
- [x] 使用者回饋系統 (App 內建)
- [x] Pro 版本功能規劃 (如預算、進階報表)
- [x] 付費牆機制 (Paywall) 實作
- [ ] Web/Desktop 版本規劃 (跨平台擴展)

## MVP-6：Pro 功能實作與變現
- [ ] 應用程式內購買 (In-App Purchase) 整合與測試
- [x] Pro 預算系統 (Advanced Budgeting System) 開發
- [ ] 進階報表與數據分析功能（iOS 完成；Android 已串接持久化帳目資料來源，持續補強）
- [ ] 用戶訂閱狀態與權限管理
- [ ] Pro 功能用戶體驗優化與市場策略

## 驗證證據（本輪）
- CSV 匯出：`HomeView` 新增「匯出CSV」按鈕，呼叫 `ExpenseListViewModel.exportCSV()`，並透過 `ShareLink` 匯出。
- 測試：`ExpenseListViewModelTests.testExportCSVIncludesHeaderAndEscapedTitle` 驗證欄位標頭與 CSV escape。
- Auth：`AuthView` + `AuthViewModel` + `MockAuthService`（本地註冊/登入/登出流程）。
- Sync：`SyncMutation` / `SyncCursor` / `InMemorySyncStateStore` 骨架。
- iOS UI 測試：`ios/ExpenseTrackerUITests/ExpenseTrackerUITests.swift`（`testAddExpenseUpdatesMonthlyOverview`），透過 launch arguments 跳過 Auth 並使用 in-memory DB 驗證「新增帳目→支出數字更新」。
- Android UI 測試：`android/app/src/androidTest/java/com/bkes994408/expensetracker/ExpenseFlowUiTest.kt`（`addExpense_updatesMonthlyOverviewTotal`），驗證「新增帳目→月總覽更新」。
- 隱私政策：新增 `docs/PRIVACY_POLICY.md`。
- 資料刪除流程：新增 `docs/DATA_DELETION_PROCESS.md`（含使用者刪除路徑、申請管道、SLA）。
- Crash/analytics：新增 iOS `Telemetry`（含 uncaught exception handler）與 Android `Telemetry` + `ExpenseTrackerApplication`（含全域 crash handler），並記錄核心事件；文件見 `docs/CRASH_ANALYTICS.md`。
- Release checklist：新增 `docs/RELEASE_CHECKLIST.md`，涵蓋 scope、測試、資安與隱私、iOS/Android 上架、回滾與發佈後監控。
- 效能優化：iOS `LocalStore` 改為 lazy 初始化（延後 DB / store 建立），並新增 app 啟動耗時 telemetry；Android 新增首幀啟動耗時 telemetry 與 Compose 月總覽 `derivedStateOf` 計算，降低重組時重算成本。
- 多語言支援：Android 新增 `values/strings.xml` + `values-zh-rTW/strings.xml` 並將 UI 改為 `stringResource`；iOS 新增 `L10n` 字典式本地化，覆蓋 Home/Settings/Auth 與訂閱提醒文案，依系統語系切換中英文字串。
- 使用者回饋系統：iOS `SettingsView` 新增 App 內回饋輸入區塊與 `mailto:` 送出流程（含失敗提示）；Android `SettingsScreen` 新增回饋欄位與 Email Intent 寄送（含多語系字串與無 Email App 提示）。
- Pro 版本功能規劃：新增 `docs/PRO_FEATURE_PLAN.md`，定義預算與進階報表兩大 Pro 功能包、分階段上線策略、KPI 與 A/B 實驗、權限牆（paywall）觸發點、跨平台落地需求與風險控管。
- 付費牆機制（Paywall）實作：iOS/Android 新增 `ProEntitlementStore`（本機快取方案狀態），並在三個高意圖入口（第 3 個分類預算、3 個月以上趨勢圖、PDF 報表匯出）加入 paywall 觸發；iOS 新增 `PaywallView`、Android 新增 `PaywallDialog`，支援試用/訂閱/恢復購買與 Debug 重置。
- Pro 預算系統（Advanced Budgeting）開發：iOS 新增 `BudgetPlan` / `BudgetProgress` / `BudgetStore` / `GRDBBudgetStore` 與 `BudgetViewModel`，支援每月分類預算設定、上月快速複製、80% 警示與超支狀態計算；`HomeView` 加入 Pro 預算 UI，Free 方案限制每月 2 個分類預算，超出時觸發 paywall。
- 測試補強：新增 iOS `BudgetViewModelTests`（覆蓋預算進度計算與上月複製）、Android `BudgetProgressCalculatorTest`（覆蓋 warning/overspent 規則）與 `BudgetProgressCalculator` domain helper。
- 進階報表與數據分析：iOS `HomeView` 新增 `AdvancedReportViewModel` 與 1/3/6/12 月趨勢摘要、MoM 分類變化分析（Top growth/decline）；Android `HomeScreen` 透過 `ExpenseRepository.fetchExpenses()` 讀取持久化帳目資料（`FileExpenseStore` / `expenses.json`），再由 `AdvancedReportCalculator` 依 `createdAt` 進行區間過濾與平均值摘要，並沿用 paywall 觸發（Free 限 1M）。`FileExpenseStore` 在首次啟動且檔案不存在時會回傳空清單，不再寫入示範資料。
- 測試：iOS `BudgetViewModelTests` 新增進階報表權限與 MoM 分析語義案例（無成長/下降時回傳 nil）；Android 新增 `AdvancedReportCalculatorTest`（createdAt 區間）、`HomeReportIntegrationTest`（區間切換、資料變化、Free/Pro gating）、`FileExpenseStoreTest`（檔案存在/不存在與讀取一致性）與 `ExpenseRepositoryImplTest`（repository 讀取持久化資料來源）。

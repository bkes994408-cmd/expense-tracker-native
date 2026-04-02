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
- [x] Web/Desktop 版本規劃 (跨平台擴展)

## MVP-6：Pro 功能實作與變現
- [x] 應用程式內購買 (In-App Purchase) 整合與測試
- [x] Pro 預算系統 (Advanced Budgeting System) 開發
- [x] 進階報表與數據分析功能（iOS + Android 均完成；Android 已補齊持久化資料來源、區間分析與測試 DoD）
- [x] 用戶訂閱狀態與權限管理
- [x] Pro 功能用戶體驗優化與市場策略

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
- MVP-7（iOS 增量）：`HomeView` 進階報表新增 `Charts` 視覺化，支援「折線圖 / 長條圖」切換，並加入「資料篩選（全部 / 僅收入 / 僅支出 / 僅淨額）」自定義選項；沿用既有 1/3/6/12 月區間與 Free/Pro gating。Android 本輪未變更，維持上一版摘要報表 UI。
- 測試：iOS `BudgetViewModelTests` 新增進階報表權限與 MoM 分析語義案例（無成長/下降時回傳 nil）；Android 新增 `AdvancedReportCalculatorTest`（createdAt 區間）、`HomeReportIntegrationTest`（區間切換、資料變化、Free/Pro gating）、`FileExpenseStoreTest`（檔案存在/不存在與讀取一致性）與 `ExpenseRepositoryImplTest`（repository 讀取持久化資料來源）。
- Web/Desktop 規劃：新增 `docs/WEB_DESKTOP_PLAN.md`，定義 Web 與 Desktop 分階段範圍、技術路線（React + TypeScript + Tauri）、DoD、風險與緩解，以及 CI/測試策略，作為跨平台擴展實作藍圖。
- 用戶訂閱狀態與權限管理：iOS/Android `ProEntitlementStore` 新增 `subscriptionState`（free/active/expired）、trial 到期時間持久化、`statusText/statusLabel` 與 `canAccess(feature)` 權限檢查；Home/Settings 畫面與 Pro 功能入口（報表、PDF、預算）改以 feature-level gating。另統一 restore 規則：restore 到 trial 不會重置 7 天試用、若缺少 trial 到期資訊則視為已過期，避免 iOS 延長試用與 Android trial 永久有效風險。iOS 同步 wrapper 改為純 async 呼叫，移除主執行緒 semaphore deadlock 風險。新增測試：iOS `ProEntitlementStoreTests.testTrialExpiryRevokesProAccess` / `testRestoreTrialDoesNotExtendExistingTrialWindow` / `testRestoreTrialWithoutStoredExpiryIsImmediatelyExpired`、Android `ProEntitlementStoreTest.trialExpires_changesStateToExpiredAndRevokesFeature` / `restoreTrial_preservesExistingTrialExpiry` / `restoreTrial_withoutStoredExpiry_isImmediatelyExpired`。
- Pro 功能用戶體驗優化與市場策略：新增 iOS/Android `PaywallExperience`，依 trigger（`budget_limit` / `advanced_report_3m` / `report_pdf_export`）動態調整 paywall headline/subheadline/推薦方案；paywall 新增事件追蹤 `pro_paywall_viewed`、`pro_paywall_cta_tapped`；新增測試 iOS `PaywallExperienceTests`、Android `PaywallExperienceTest`；策略文件見 `docs/PRO_UX_MARKET_STRATEGY.md`。
- IAP 整合：Android 新增 `GooglePlayBillingProPurchaseService` + `GooglePlayBillingClient`（Billing v7），完成商品對應（trial/monthly/yearly）、購買結果處理（success/cancelled/pending）與 restore 流程（query purchases + acknowledge）；`RootNavHost` 改為注入實際 Billing service 給 `ProEntitlementStore`。新增測試 `GooglePlayBillingProPurchaseServiceTest`（monthly mapping、pending error、restore unknown product、restore yearly）。
- 家庭/群組帳本：iOS 新增 `GroupLedgerStore` / `GRDBGroupLedgerStore`（`group_ledgers`, `group_members`, `shared_expenses`, `shared_expense_splits`）與 `GroupLedgerViewModel`；`HomeView` 新增「家庭/群組帳本」區塊，支援建立帳本、加入成員、共享支出與平均分攤、成員淨額（paid-owed）結算檢視。
- Iteration-7 / Web 報表中心（MVP Slice）：新增 `web/`（React + TypeScript + Recharts）與大螢幕報表控制列（1/3/6/12M、all/income/expense/net、line/bar）及趨勢圖；測試覆蓋 `reportCalculator` 與 `App` 互動行為。詳見 `docs/WEB_REPORT_CENTER_MVP.md`。

### Iteration-NEXT（MVP-7 剩餘兩項）
- [x] 帳目導入/導出增強（Android 對齊 iOS，支援 OFX/QIF/CSV）
- [x] 預算智能建議 v1（基於歷史消費做 category budget baseline）
- [x] 超支預警（rule + threshold）
- [x] iOS/Android 行為對齊測試
- [x] 文件補完：iOS/Android scope 一致化

**DoD**
- iOS/Android 兩端功能 parity（至少核心路徑）
- 各 1 條 UI/integration test
- CI（build + build-test）全綠

### Iteration-2（Data Input & Automation）

> 目標：降低 onboarding 阻力，讓用戶更快帶入既有帳目資料開始使用。

- [x] CSV 匯入精靈（欄位對應 UI、預覽表格、逐筆錯誤提示，支援多種日期格式）
- [x] 重複交易偵測與合併建議（匯入時比對金額 + 日期 + 標題相似度，提示可能重複的帳目）
- [x] OFX / QIF 格式匯入（純本機解析，支援各大銀行匯出格式，無需後端）
- [x] 銀行 API 架構預留（定義 `BankImportProvider` protocol，不實作後端，保留擴充點）
- [x] 固定支出與分期帳目自動生成（週期到期時自動新增帳目；Free 限 3 筆規則，Pro 無限，整合既有訂閱管理）

### Iteration-3（Analytics Parity & Report Upgrade）

> 目標：Android 補齊 iOS 視覺化功能，強化 Pro 報表差異化價值。

- [x] Android 圖表視覺化補齊（Compose Charts 實作折線圖 / 長條圖，與 iOS 版本功能對等）
- [x] Android 自定義報表篩選補齊（補齊全部 / 僅收入 / 僅支出 / 淨額篩選，與 iOS 一致）
- [x] 分類占比圖與比較報表（圓餅圖 + 月間分類比較，點擊分類可下鑽明細帳目）【Pro】
- [x] 本月 vs 上月 / 年度同比分析（MoM / YoY 變化率，標注成長 / 下降趨勢，含分類細分）【Pro】
- [x] PDF 月報正式版（含圖表截圖、分類彙總表、月收支趨勢，樣式對齊品牌視覺）【Pro】

### Iteration-4（Smart Budgeting & Retention）

> 目標：AI 功能作為 Pro 核心賣點，覆蓋每次記帳的高頻操作，拉升付費轉換率。
> 注意：AI 分析依賴歷史帳目，建議在 Iteration-2 數據導入完成後推出，確保新用戶有足夠資料可分析。

- [x] AI 預算建議（分析 3 個月歷史消費，自動推薦各分類預算上限，標注異常消費月）【Pro】
- [x] 自動分類建議（輸入帳目標題時 on-device ML 推薦分類，Core ML / TFLite，學習個人習慣）【Pro】
- [x] 異常支出提醒（與個人消費基線比對，即時標記異常大額或非典型時段支出，推播通知）【Pro】
- [x] 月結提醒 / 帳單提醒（自訂提醒日推播月結通知；整合訂閱扣款前一天預警）【Free】
- [x] 超支預測與預算草案生成（月中自動預測是否超支，一鍵生成下月預算草案供用戶確認）【Pro】

### Iteration-5（Group Ledger 2.0）

> 目標：將 Iteration-1 的群組帳本 MVP 升級為完整社交記帳功能。

- [x] 自訂分攤規則（平均 / 自訂比例 / 固定金額，每筆支出可獨立設定分攤方式）【Pro】
- [x] 最佳結算建議（最小化轉帳筆數演算法，一鍵顯示「A 付 B 多少錢」清單）【Pro】
- [x] 群組共享預算（設定群組月預算，追蹤各分類 / 各成員支出進度）【Pro】
- [x] 群組月報（群組月結報告，含各成員支出占比、最高分類、結算摘要）【Pro】
- [x] 成員角色與邀請流程優化（Owner / Editor / Viewer 三層權限；邀請連結 + QR Code 加入）【Free 基礎 / Pro 進階】

### Iteration-6（Pro Growth & Monetization）

> 目標：提升訂閱用戶 LTV，讓 Pro 帳目資料積累形成強留存。

- [x] 年度財務回顧（Wrapped 風格年度報告：最大支出、最常分類、與去年比較，可分享）【Pro】
- [x] PDF / 年報自動產出（iOS PDFKit + Android PdfDocument；含年度圖表、分類彙總、月間趨勢）【Pro】
- [x] 多帳本管理（個人 / 工作 / 旅行等多帳本獨立管理，可跨帳本彙總報表）【Pro】
- [x] 歷史備份版本（每週自動快照，Pro 保留 12 週，可回復至任意版本）【Pro】
- [x] 試用轉正與續訂優化（試用到期限時折扣、取消訂閱挽留畫面、年費 vs 月費動態比較）【Pro】

### Iteration-7（Web / Desktop Expansion）

> 目標：依 `docs/WEB_DESKTOP_PLAN.md` 執行，待商業模式穩定後啟動。
> 前置條件：跨裝置同步後端（雲端 Auth 實作）需在本 Iteration 完成。

- [x] Web 報表中心（React + TypeScript；大螢幕優化的進階圖表與數據篩選介面，含 Free/Pro 區間權限 gating）【Pro】
- [ ] Desktop 快速輸入工具（Tauri Menu Bar 常駐，快速鍵呼出 → 填金額分類 → 儲存）【Pro】
- [ ] 跨裝置同步正式版（`SyncMutation` / `SyncCursor` 骨架接上 Supabase，iOS + Android + Web 三端同步）【Pro】
  - 進度（Phase 1）：`shared/cloud-sync` 已落地 `SupabaseSyncTransport` + schema + expenses/categories merge 與測試。
  - 進度（Phase 2）：`web-report-center` 已接入 `CloudSyncOrchestrator + SupabaseSyncTransport`，提供 expenses/categories smoke flow（enqueue -> flush -> pull -> merge）。
- [ ] 管理後台與資料維護功能（用戶自助後台：帳號管理、完整資料匯出、GDPR 刪除申請）【Pro】

### Iteration-6（成長與變現優化）
- [x] 年度財務回顧（Wrapped 報告）：新增年度財務摘要生成器（年度收入/支出/淨額、儲蓄率、支出最高分類、最佳/艱困月份）。
- [x] 歷史快照備份與還原（Snapshot）：新增 JSON Snapshot 匯出/貼上還原機制，支援快速資料備份與復原。
- [x] 訂閱挽留與續訂優化（Retention Strategy）：新增 trial 近到期、trial 到期、monthly 轉年付等策略建議與 offer code。

### Iteration-1 (MVP-7: 社交與數據共享)
- [x] 家庭/群組帳本：支持多人共同記帳，實現家庭或小團體費用共享與分攤。
- [ ] 帳目數據導入/導出增強：支持更多格式（如 OFX, QIF），或與銀行 API 介接，簡化數據錄入。
- [x] 進階視覺化報表與圖表（第一階段）：已提供多圖表類型切換（折線圖 / 長條圖）與自定義報表篩選（全部 / 僅收入 / 僅支出 / 僅淨額）；目前先上線 iOS，Android 後續補齊。
- [x] 預算管理智能建議：根據歷史消費數據，AI 自動推薦預算設定，並提供超支預警。

### Iteration-7（跨裝置擴展）
- [x] Web 報表中心（React + TypeScript）骨架與月總覽/分類分析初版
- [x] Desktop 快速輸入工具（Tauri + React）骨架與基本輸入驗證
- [x] 雲端同步架構基礎（TypeScript mutation + cursor orchestrator）
- [x] 實作紀錄文件：`docs/ITERATION-7_CROSS_DEVICE.md`

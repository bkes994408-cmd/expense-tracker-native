# Sprint Result - MVP-1（核心功能第二階段）

日期：2026-02-28

## 完成項目

1. **每月總覽（收入 / 支出 / 分類彙總）**
   - `ExpenseStore` 新增 `fetchMonthlyOverview(for:)`。
   - `GRDBExpenseStore` 實作當月彙總查詢（收入、支出、淨額、分類彙總）。
   - 首頁新增「每月總覽」區塊，顯示收入/支出/淨額與分類金額。
   - 新增帳目支援「收入 / 支出」切換（支出以負數入帳）。

2. **訂閱管理基礎功能**
   - 新增 `SubscriptionPlan`、`SubscriptionStore`、`GRDBSubscriptionStore`。
   - 本機 DB 新增 `subscriptions` 表（名稱、金額、週期天數、下次扣款、提醒設定）。
   - 設定頁新增「訂閱管理」：可新增訂閱並顯示下次扣款日期與提醒文字。

3. **分期管理基礎功能**
   - 新增 `InstallmentPlan`、`InstallmentStore`、`GRDBInstallmentStore`。
   - 本機 DB 新增 `installments` 表（總期數、已繳期數、每期金額）。
   - 設定頁新增「分期管理」：可新增分期並顯示已繳 / 剩餘期數。

4. **最小測試 / UI 驗證**
   - 擴充 `ExpenseListViewModelTests`：驗證月總覽計算與收入/支出符號。
   - 新增 `SubscriptionManagementViewModelTests`：驗證新增訂閱與提醒文字。
   - 新增 `InstallmentManagementViewModelTests`：驗證剩餘期數計算。

## 驗證結果

- 測試指令：
  - `xcodegen generate --spec ios/project.yml`
  - `xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' CODE_SIGNING_ALLOWED=NO test`
- 本輪新增測試覆蓋：月總覽、訂閱管理、分期管理核心行為。

## 備註

- 本輪維持離線優先（僅本機 SQLite，未涉及雲端同步）。
- 僅做 MVP-1 第二階段必要改動，未進行額外重構。

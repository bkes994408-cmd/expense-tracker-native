# Sprint Result - MVP-1（核心功能第一階段）

日期：2026-02-27

## 完成項目

1. **帳目 CRUD 最小可用（新增 / 列表 / 刪除）**
   - 建立 `ExpenseStore` 介面與 `GRDBExpenseStore` 實作。
   - 資料表：`expenses(id, title, amount, createdAt, categoryId)`。
   - App 首頁改為可直接輸入標題與金額新增帳目，並在列表中刪除。
   - `update(...)` 已先在介面與 store 留下實作入口（UI 後補）。

2. **分類管理最小可用（新增 + 列表）**
   - 延續既有 `CategoryStore`/`CategoryManagementViewModel`。
   - Settings 畫面提供分類新增與列表。
   - 封存/排序能力仍保留介面（`archive`/`move`），並加上 TODO 註記後續 UX 強化。

3. **列表篩選 / 搜尋（先落地搜尋）**
   - 新增 `ExpenseListViewModel.searchText`。
   - 首頁使用 `.searchable(...)`，可依標題即時過濾帳目。
   - GRDB 查詢支援 `title LIKE` 模糊搜尋。

4. **最小測試與 CI**
   - 新增 `ExpenseListViewModelTests`（新增/刪除/搜尋）。
   - 保留並修正 `CategoryManagementViewModelTests`（型別命名衝突）。
   - iOS CI workflow 更新為：
     - 先 `xcodegen generate`
     - 再執行 `xcodebuild ... test`

## 驗證結果

- 本機測試指令：
  - `xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' CODE_SIGNING_ALLOWED=NO test`
- 結果：`TEST SUCCEEDED`（5 tests, 0 failure）

## 風險 / 後續

- 帳目「更新」目前只有資料層入口，尚未接 UI（MVP-1.2）。
- 分類封存/排序雖有能力，但互動體驗仍偏工程版（MVP-1.2 可優化）。
- Android 端尚未同步補齊同等功能，下一階段需補平台一致性。

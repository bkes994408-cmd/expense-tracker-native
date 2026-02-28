# Sprint Result - MVP-1 收斂 + MVP-2 骨架啟動

日期：2026-02-28

## 完成項目

1. **MVP-1：CSV 匯出補齊（含 ROADMAP 勾選）**
   - `ExpenseListViewModel` 新增 `exportCSV()`，輸出欄位：`id,title,amount,createdAt,categoryId`。
   - 加入 CSV escape（逗號/換行/雙引號）處理。
   - `HomeView` 新增「匯出CSV」按鈕與 `ShareLink`。
   - `docs/ROADMAP.md` 將 CSV 匯出改為已完成並補驗證證據。

2. **MVP-2：Auth 最小骨架（本地 mock）**
   - 新增 `AuthService` 介面、`MockAuthService`、`AuthViewModel`、`AuthView`。
   - 支援註冊 / 登入 / 登出（純本地記憶體流程，不接真後端）。
   - `RootView` 加入 auth gate：未登入先顯示 Auth，登入後進入主畫面。

3. **MVP-2：Delta sync 資料結構骨架**
   - 新增 `SyncMutationType`、`SyncMutation`、`SyncCursor`。
   - 新增 `SyncStateStore` 與 `InMemorySyncStateStore`（enqueue / peek / drain / cursor）。
   - 僅完成資料模型與本地佇列，不含網路同步。

4. **最小測試補齊（Auth / Sync 至少各 1）**
   - `AuthViewModelTests.testRegisterThenLogoutFlow`
   - `SyncStateStoreTests.testEnqueueDrainAndCursorUpdate`
   - 另外補 `ExpenseListViewModelTests.testExportCSVIncludesHeaderAndEscapedTitle`

## 驗證方式

- 產生專案：
  - `xcodegen generate --spec ios/project.yml`
- 執行測試：
  - `xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' CODE_SIGNING_ALLOWED=NO test`

## 備註

- 本輪刻意維持最小可行範圍：
  - Auth 為 mock，不含 token / keychain。
  - Sync 僅資料結構，不含 API、衝突解決。
- 既有 MVP-1 功能維持可編譯、可測試。

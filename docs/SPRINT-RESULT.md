# Sprint Result - MVP-1（核心功能最後階段）

日期：2026-02-28

## 完成項目

1. **每月總覽 / 訂閱管理 / 分期管理（iOS）**
   - 完成月總覽資料查詢與畫面顯示。
   - 設定頁新增訂閱管理與分期管理的新增/列表能力。

2. **CSV 匯出功能（iOS）**
   - 新增 `ExpenseCSVExporter`，支援 `id,title,amount,createdAt,categoryId` 欄位輸出。
   - `title` 支援 CSV escaping（逗號 / 雙引號）。
   - 設定頁新增「匯出 CSV」與「分享最近匯出檔」入口。

3. **最小測試 / 驗證**
   - 新增 `ExpenseCSVExporterTests`（header、escaping、UTF-8 檔案輸出）。

## 變更檔案

- `ios/ExpenseTracker/Expense/ExpenseCSVExporter.swift`（新增）
- `ios/ExpenseTracker/UI/SettingsView.swift`
- `ios/ExpenseTracker/UI/RootView.swift`
- `ios/ExpenseTrackerTests/Expense/ExpenseCSVExporterTests.swift`（新增）
- `docs/ROADMAP.md`
- `docs/SPRINT-RESULT.md`

## 驗證指令

```bash
cd ios
xcodegen generate
xcodebuild \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

> 預期：`TEST SUCCEEDED`

## 備註

- 本次維持最小必要修改，未進行無關重構。
- Android 端 CSV 匯出未在本輪納入（維持既有 MVP-1 範圍）。

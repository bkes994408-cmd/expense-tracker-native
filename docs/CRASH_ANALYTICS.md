# Crash / Analytics（MVP-4 可選）

本輪完成 **可替換的 telemetry 骨架**，先把事件追蹤與 crash 捕捉接點做出來，避免過早綁定第三方 SDK。

## 已完成

### iOS
- 新增 `Telemetry` 單例（`ios/ExpenseTracker/Telemetry/Telemetry.swift`）。
- App 啟動安裝 `NSSetUncaughtExceptionHandler`，並記錄 `app_launched`。
- 已接入事件：
  - `expense_added`
  - `expense_add_invalid`
  - `expense_deleted`
  - `csv_exported` / `csv_export_failed`

### Android
- 新增 `telemetry/Telemetry.kt`。
- 新增 `ExpenseTrackerApplication`，啟動時安裝 `Thread.setDefaultUncaughtExceptionHandler`。
- 已接入事件：
  - `APP_LAUNCHED`
  - `HOME_SCREEN_OPENED`
  - `UNCAUGHT_EXCEPTION`

## 目前行為
- Debug / 現階段預設輸出到 `os.Logger`（iOS）與 `Logcat`（Android）。
- 仍未接 Firebase Crashlytics / Analytics 或 Sentry（保留替換空間）。

## 下一步（正式上線前）
1. 以 Firebase 或 Sentry 取代 Console/Logcat 實作。
2. 在隱私政策補上事件清單與 opt-out 說明。
3. 設定 release 事件採樣與 crash alert 規則。

# Sprint Result - MVP-0（專案初始化門檻）

日期：2026-02-27

## 完成項目

1. **iOS 可編譯驗證（最小骨架）**
   - 修正 Xcode 專案重複 `ExpenseTrackerApp.swift` 導致的編譯衝突。
   - 統一 App 入口在 `ios/ExpenseTracker/App/ExpenseTrackerApp.swift`。
   - 驗證指令：
     - `xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
   - 結果：`BUILD SUCCEEDED`

2. **Android 可編譯驗證（最小骨架）**
   - 補齊 Android app 缺少的 Kotlin 原始碼與入口 Activity。
   - 建立最小可執行 Compose 畫面。
   - 驗證指令：
     - `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ANDROID_HOME="$HOME/Library/Android/sdk" ./gradlew :app:assembleDebug`
   - 結果：`BUILD SUCCESSFUL`

3. **基礎分層架構（network/data/domain/ui）與最小範例**
   - network：`ApiClient`（`ping()`）
   - domain：`Expense`、`ExpenseRepository` 介面
   - data：`ExpenseRepositoryImpl`（組合 network + sample data）
   - ui：`HomeViewModel` + `AppScreen` + `MainActivity`
   - iOS 既有對應分層（`Network/DB/Domain/UI`）保留，並確保可編譯。

4. **CI（GitHub Actions）**
   - iOS workflow 改用 generic simulator destination，降低 runner 機型差異導致失敗的風險。
   - Android workflow 保持 `assembleDebug`。

5. **Roadmap 更新**
   - `docs/ROADMAP.md` 的 MVP-0 四項皆已勾選完成。

## 阻塞 / 風險

- 本機 Android build 需設定 `JAVA_HOME` 與 `ANDROID_HOME`；CI 環境由 workflow step 提供，不受此影響。
- iOS project.pbxproj 目前仍為手動維護狀態，後續若再新增檔案建議固定用同一套流程（Xcode 或 Tuist）避免重複登記。

## 建議下一步（MVP-1 起手）

1. 補第一條垂直功能：Expense CRUD（含本機 DB 寫入 + UI list）。
2. 建立跨平台一致的 Domain 命名與欄位定義（避免後續 sync 成本）。
3. 在 CI 加上 lint / unit test（目前先以 build gate 為主）。

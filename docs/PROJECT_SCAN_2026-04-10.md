# Expense Tracker Native 全專案掃描報告（2026-04-10）

## 掃描範圍與方式
- 模組：`android` / `ios` / `shared/cloud-sync` / `web-report-center` / `web` / `desktop-quick-entry`
- 檢查項：build、test、lint、工具鏈、repo 髒檔/未追蹤檔、UI replica 風險
- 主要執行：
  - Android：`./gradlew :app:assembleDebug :app:testDebugUnitTest :app:lintDebug`
  - iOS：`xcodebuild ... build`、`xcodebuild ... test`
  - shared：`npm test`
  - web-report-center：`npm run build`、`npm test`
  - web：`npm run build`、`npm test`
  - desktop-quick-entry/web：`npm run build`

---

## 問題清單（分級）

### P0（會壞 / 會擋）
1. **Android 在預設 JDK 25 環境直接失敗**
   - 現象：`./gradlew` 直接噴 `IllegalArgumentException: 25.0.2`（Kotlin/Gradle 腳本解析 Java 版本失敗）。
   - 根因：目前 Android build chain 對 Java 25 不相容（此 repo 實際可用 JDK 17/21）。
   - 建議修法：
     - 在 `README`/`android/` 明確要求 JDK 17 或 21。
     - 加入 `org.gradle.java.home`（或 CI/local 啟動腳本固定 JAVA_HOME）避免踩到系統預設 JDK 25。

2. **（已順手修）Android lint NewApi 錯誤導致 `:app:lintDebug` fail**
   - 現象：`ExpenseLedger.kt` 使用 `LocalDate.ofInstant(...)` 被判定需要 API 34。
   - 根因：`LocalDate#ofInstant` 在目前 minSdk 條件下被 lint 視為不安全 API。
   - 修法（已修）：改為 `it.createdAt.atZone(zone).toLocalDate()`。
   - 驗證：修正後 `:app:lintDebug :app:assembleDebug :app:testDebugUnitTest` 全部成功。

### P1（應盡快修）
1. **iOS CI destination 可能脆弱（workflow 寫死 iPhone 16）**
   - 現象：本機 Xcode 17 模擬器列表沒有 `iPhone 16`，只有 `iPhone 17` 系列；`xcodebuild -destination '...name=iPhone 16' test` 會失敗。
   - 根因：workflow 對特定 simulator 名稱硬編碼，受 Xcode 版本變動影響。
   - 建議修法：
     - 改成較穩定策略（例如 `generic/platform=iOS Simulator` + `build-for-testing/test-without-building`，或在 CI 先 `xcrun simctl list` 動態挑可用機型）。

2. **Repo 目前已有未提交檔案，存在混入主線風險**
   - 目前狀態：
     - Modified：`ios/ExpenseTracker/UI/RootView.swift`
     - Untracked：
       - `shared/cloud-sync/README.md`
       - `shared/cloud-sync/tests/supabaseTransport.test.ts`
       - `web-report-center/src/lib/adminMaintenance.ts`
   - 風險：後續 PR 容易把未驗證變更一起帶入。
   - 建議修法：先切分 commit（功能/文件/實驗分開），或將非本次交付內容暫存。

3. **本機 desktop tauri toolchain 不完整（缺 `cargo`）**
   - 現象：`desktop-quick-entry/src-tauri` 無法 `cargo check`。
   - 根因：Rust toolchain 未安裝。
   - 建議修法：安裝 Rust (`rustup`) 並補一條 CI（至少 `cargo check`）保證桌面端不退化。

### P2（技術債 / polish）
1. **Android lint 警告仍有 22 筆**（依賴版本落後、`targetSdk=34`、unused resources、missing application icon、kapt→ksp 建議等）。
2. **Web bundle 體積警告**：`web` build 產物 chunk > 500k，建議 code splitting。
3. **前端依賴弱點**：
   - `web` 安裝後顯示 3 個 high vulnerabilities
   - `desktop-quick-entry/web` 顯示 2 個 moderate vulnerabilities
   - 建議排程做一次 `npm audit` 與升級策略。

---

## UI Replica 高風險缺口評估
- Android / iOS 目前均可編譯，且對應 replica 元件（`ReplicaTokens` / `ReplicaDesign`、`ReplicaStateBox`、`ReplicaListRow`、`ReplicaEdgeStates`）已被實際引用，**未發現編譯層級高風險缺口**。
- 仍有產品驗收風險（P2）：缺少多解析度/真機視覺回歸（目前屬人工驗證缺口，不是編譯阻塞）。

---

## 這次順手修掉的問題
1. `android/app/src/main/java/com/bkes994408/expensetracker/db/ExpenseLedger.kt`
   - 修正 `LocalDate.ofInstant` lint NewApi 問題（P0）。

---

## 結論摘要
- 目前最大實際阻塞風險是 **Android 對預設 JDK 25 不相容**（P0）。
- 本次已修復一個會讓 lint fail 的 Android API 相容性問題。
- 其餘主要風險集中在 **CI destination 穩定性**、**未提交檔案混入風險**、與 **工具鏈/技術債**。

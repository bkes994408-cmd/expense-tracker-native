# UI Replica Sprint 5 收尾報告（expense-tracker-native）

日期：2026-04-10  
範圍：Home / Dashboard、Transactions / Recurring、Reports、Settings（Android + iOS）

## 1) Final Prototype Parity Audit（P0 / P1 / P2）

### P0（本輪已修）
- **跨平台 edge states 統一元件化**
  - Android：新增 `ReplicaEdgeStates(...)`，統一 Loading / Empty / Error / Long text / Dense content。
  - iOS：新增 `ReplicaEdgeStates(...)`，同一組狀態與文案結構。
- **設計 token 收斂（第一輪）**
  - Android：集中於 `ReplicaTokens`（card/row/state 色彩與圓角）。
  - iOS：集中於 `ReplicaDesign`（card radius/border/shadow/padding/row style）。
- **重複樣式去重**
  - iOS 移除 `HomeReplicaStateBox` 與 `settingsStateBox` 重複實作，改用共用 `ReplicaStateBox`。

### P1（本輪已修）
- **Long text 行為一致化**
  - Android：`ReplicaListRow` subtitle 限制 `maxLines=2 + ellipsis`。
  - Android：`ReplicaStateBox` 支援 `maxLines`，避免超長說明撐爆卡片。
- **Reports / Settings 的 edge-state 展示一致化**
  - Android 與 iOS 皆在 Reports/Settings 放入同一套 edge-state 範本。

### P2（待後續）
- Home/Transactions 區塊仍有少量字詞與視覺細節差異（例：chip 字串「固定」vs「固定支出」）。
- iOS Settings 目前仍以 `List + Section` 為主，與 Android `Card` 結構在分隔視覺上仍有系統風格差。
- tab icon/label 的精細對齊（字重、內距、點擊回饋）尚可再收斂。

---

## 2) Android / iOS 手動 QA Checklist 與發現

## QA Checklist
- [ ] Home：Hero / stats / 最近交易、空資料展示
- [ ] Transactions：新增交易、列表、Recurring、空資料
- [ ] Reports：range chip、摘要、圖表區塊、edge states
- [ ] Settings：分類管理、匯入匯出、edge states、長文字
- [ ] 長字串（中英文混合）換行與截斷
- [ ] 高密度內容（多列、多按鈕）可讀性

## 本輪實際驗證結果
- **Android build/test：阻塞**（見第 6 節，JDK 25.0.2 工具鏈問題）。
- **iOS：以程式碼與 preview 結構檢查為主**，本輪未附實機截圖驗證。

## 問題整理
1. Android 無法進入測試流程（阻塞）
2. iOS Settings 使用系統 `List`，在 grouped/inset 模式與 Android card 觀感仍有平台差
3. Transactions 類別 chip 文案在兩端仍有輕微不一致

---

## 3) Edge States 統一成果與例外

## 已統一
- Loading / Empty / Error / Long text / Dense content 五類狀態，雙平台已共用同一概念與層次。
- 統一顯示順序與文案語氣（資訊優先、避免過長）。

## 仍有例外
- iOS `List` 內部間距受系統樣式影響，與 Android `LazyColumn + Card` 仍有些微差。
- 個別業務區塊（非 edge-state）仍保留既有細節差異。

---

## 4) 抽出的共用樣式 / token 清單

## Android（`PrototypeUi.kt`）
- `ReplicaTokens.cardRadius`
- `ReplicaTokens.cardBorder`
- `ReplicaTokens.cardSurface`
- `ReplicaTokens.rowRadius`
- `ReplicaTokens.rowBg`
- `ReplicaTokens.rowBorder`
- `ReplicaTokens.stateRadius`
- `ReplicaTokens.stateBg`
- `ReplicaTokens.stateBorder`
- `ReplicaTokens.stateTitle`
- `ReplicaTokens.stateBody`

## iOS（`ReplicaDesign.swift`）
- `ReplicaDesign.cardRadius`
- `ReplicaDesign.cardBorder`
- `ReplicaDesign.cardShadow`
- `ReplicaDesign.cardPadding`
- `ReplicaDesign.sectionSpacing`
- `ReplicaDesign.rowBg`
- `ReplicaDesign.rowBorder`

## 共用 UI 元件
- `ReplicaStateBox`
- `ReplicaListRow`
- `ReplicaEdgeStates`

---

## 5) Micro Interaction（收斂後）

- 保留必要回饋，不增加高成本動畫。
- Android：既有 `TransactionRow` press scale/bg 互動保留。
- iOS：tab/chip 切換維持輕量動畫，不新增多段動效。

---

## 6) Android `25.0.2` 工具鏈問題：根因與最小修法

## 根因
- 目前本機 Java 為 `25.0.2`。
- 專案使用 Gradle `8.7` + Kotlin DSL，啟動時在 `JavaVersion.parse("25.0.2")` 失敗：
  - `java.lang.IllegalArgumentException: 25.0.2`
- 因此 Gradle 在解析設定階段即中止，尚未進入 app compile/test。

## 最小修法（建議優先）
1. **將 Android 建置 JDK 固定到 17 或 21（推薦 21）**
   - 安裝 JDK 21（Temurin/Oracle 均可）
   - 設定 `JAVA_HOME` 指向 JDK 21 後再執行 `./gradlew ...`
2. 在 `android/gradle.properties` 補註（團隊共識文件，不硬寫機器路徑）
   - 明確規範 Android 本地開發使用 JDK 21

## 次要修法（風險較高）
- 升級 Gradle Wrapper（與 AGP/Kotlin 一起驗證）到可穩定解析 Java 25 的版本；此路徑改動面較大，不建議作為本輪最小修補。

---

## 7) 本輪變更檔案

- `android/app/src/main/java/com/bkes994408/expensetracker/ui/PrototypeUi.kt`
- `android/app/src/main/java/com/bkes994408/expensetracker/ui/HomeScreen.kt`
- `android/app/src/main/java/com/bkes994408/expensetracker/ui/SettingsScreen.kt`
- `ios/ExpenseTracker/UI/ReplicaDesign.swift`
- `ios/ExpenseTracker/UI/HomeView.swift`
- `ios/ExpenseTracker/UI/SettingsView.swift`
- `docs/UI_REPLICA_SPRINT5_REPORT.md`

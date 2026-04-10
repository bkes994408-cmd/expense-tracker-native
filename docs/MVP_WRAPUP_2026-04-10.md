# Expense Tracker Native MVP 收尾報告（2026-04-10）

## 一、收尾摘要
- 本輪聚焦於 UI Replica 收斂、跨平台可行驗收、環境阻塞排除與 repo 狀態清理。
- 完成一項最小必要修正：將 `ReplicaDesign.swift` 正式納入 iOS target，修復 `SettingsView`/`HomeView` 相關元件找不到的編譯問題。
- iOS 與 Android 皆完成可執行驗證（build / test）。

---

## 二、UI Replica Final Wrap-up（最小必要修正）

### 已完成
1. **修復 iOS UI Replica 元件未納入 target 的問題**
   - 症狀：`ReplicaStateBox` / `ReplicaListRow` / `ReplicaEdgeStates` 在 `SettingsView.swift` 編譯失敗。
   - 根因：`ios/ExpenseTracker/UI/ReplicaDesign.swift` 存在，但未加入 `ExpenseTracker.xcodeproj` 的 Sources。
   - 修正：更新 `ios/ExpenseTracker.xcodeproj/project.pbxproj`，將 `ReplicaDesign.swift` 加入 UI group 與 Sources build phase。

### 驗證結果
- 指令：
  - `xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 結果：**BUILD SUCCEEDED**

---

## 三、Android / iOS 驗收與 QA Checklist

## A. Android（可行範圍）
- [x] `:app:assembleDebug` 可成功
- [x] `:app:testDebugUnitTest` 可成功
- [x] 確認 JVM 版本對 Gradle/Kotlin 影響
- [x] 明確提供本機可執行修法（JDK 21）

執行指令：
```bash
cd android
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
```

驗收結論：
- 在 JDK 21 下，Android build/test 正常。
- 在 JDK 25.0.2 下，Gradle 設定階段即失敗（詳見第六節）。

## B. iOS（可行範圍）
- [x] App Debug build 可成功
- [x] 單元測試可成功執行
- [x] UI Replica 相關 View 編譯/連結通過

執行指令：
```bash
xcodebuild -project ios/ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 17' test
```

驗收結論：
- **57 tests 全數通過（0 fail）**
- UI Replica 相關元件已可正常編譯。

---

## 四、剩餘未收尾項目（不在本輪擴功能）
1. **Android JVM 相容性仍依賴本機環境設定**
   - 若使用者回到 JDK 25 作為預設 Java，build 仍會失敗。
2. **UI Replica 的人工視覺比對（真機/多解析度）仍需產品驗收**
   - 本輪已確保編譯與測試，尚未做完整多裝置視覺走查截圖矩陣。
3. **repo 仍有既存未追蹤業務檔案（非本輪新增）**
   - `shared/cloud-sync/README.md`
   - `shared/cloud-sync/tests/supabaseTransport.test.ts`
   - `web-report-center/src/lib/adminMaintenance.ts`

---

## 五、Repo 清理 / 狀態說明

### 本輪清理
- 移除建置產物：
  - `android/.gradle/`
  - `android/app/build/`
- 更新 `.gitignore`：
  - `android/.gradle/`
  - `android/**/build/`
  - `android/local.properties`

### 當前重點變更（與本輪收尾直接相關）
- `ios/ExpenseTracker.xcodeproj/project.pbxproj`（加入 `ReplicaDesign.swift` 至 target）
- `.gitignore`（Android 建置噪音排除）
- `docs/MVP_WRAPUP_2026-04-10.md`（本報告）

---

## 六、Android `25.0.2` 工具鏈問題：根因與處理結果

## 根因
- `./gradlew :app:assembleDebug` 在 **JDK 25.0.2** 下失敗，錯誤為：
  - `java.lang.IllegalArgumentException: 25.0.2`
  - 來源為 Kotlin/Gradle 設定階段對 Java 版本字串解析不相容。

## 處理結果
- 已驗證本機存在 `openjdk@21`，切換後可正常建置與測試。
- 最小可執行修法：
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
```
- 修法驗證：
  - `:app:assembleDebug` ✅
  - `:app:testDebugUnitTest` ✅

---

## 七、建議下一步
1. 在團隊 README 或 Android setup 文件固定註明：**JDK 17/21 為支援版本**（避免 JDK 25 重現）。
2. 由產品/設計做一輪 iOS/Android 真機視覺 QA（字級、間距、深色模式、小螢幕）。
3. 針對本報告列出的既存未追蹤檔案，決定要納入版控或清理，避免下輪混淆。

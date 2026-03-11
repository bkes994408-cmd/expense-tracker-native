# 記帳APP（原生 iOS + Android）

MVP-0：提供可編譯/可執行的原生專案骨架，並先建立基礎分層（Network/DB/Domain/UI）與最小 routing 範例。

## iOS（Swift / SwiftUI）

### 開啟
- 用 Xcode 打開：`ios/ExpenseTracker.xcodeproj`

### 執行
- 選擇任一 iOS Simulator，Run 即可。

### CLI Build（可用於 CI）
```bash
xcodebuild \
  -project ios/ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build
```

> 專案由 `xcodegen` 生成（設定檔：`ios/project.yml`）。

## Android（Kotlin / Jetpack Compose）

### 開啟
- 用 Android Studio 打開資料夾：`android/`

### 執行
```bash
cd android
./gradlew :app:assembleDebug
```

## CI
- iOS build：`.github/workflows/ios.yml`（macos runner）
- Android build：`.github/workflows/android.yml`（ubuntu runner）

## Pro 預算功能規則（MVP-6）

### Free / Pro 限制
- **Free 方案**：每月最多 2 個預算分類。
  - 新增第 3 個分類時會觸發 paywall。
  - 使用「快速複製上月預算」若導入後會超過 2 個分類，也會觸發 paywall。
- **Pro 方案**：不受上述分類數上限限制。

### 預算計算規則
- 以「分類」為單位設定每月預算。
- 預算狀態：
  - `Healthy`：使用率 < 80%
  - `Warning`：使用率 >= 80% 且 <= 100%
  - `Overspent`：使用率 > 100%
- 進度條與剩餘金額依當月實際支出（同分類彙總）計算。

### 已知限制（目前交付範圍）
- **iOS**：預算功能（建立/刪除/複製上月/狀態計算/Free gating）已完成可用。
- **Android**：已提供 Pro 預算 gating 與進階報表區間摘要（1M/3M/6M/12M）；報表目前以 `ExpenseRepository` 資料來源計算區間平均，後續仍需補齊完整帳目 CRUD 與持久化流程，才能達到與 iOS 同等成熟度。

Docs:
- `docs/ARCHITECTURE.md`（MVP-0 分層基礎）
- `docs/ROADMAP.md`（整體路線圖）
- `docs/SPRINT-RESULT.md`（最新開發進度）
- `docs/PRIVACY_POLICY.md`（隱私政策）
- `docs/DATA_DELETION_PROCESS.md`（資料刪除流程）
- `docs/CRASH_ANALYTICS.md`（Crash/analytics 骨架與上線建議）
- `docs/RELEASE_CHECKLIST.md`（MVP-4 上架前檢查清單）
- 另見 Downloads/ChatGPT專案/記帳APP（SRS/API/簡報）

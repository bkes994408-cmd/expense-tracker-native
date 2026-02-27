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

Docs:
- `docs/ARCHITECTURE.md`（MVP-0 分層基礎）
- `docs/ROADMAP.md`（整體路線圖）
- `docs/SPRINT-RESULT.md`（最新開發進度）
- 另見 Downloads/ChatGPT專案/記帳APP（SRS/API/簡報）

# 記帳APP（原生 iOS + Android）

## MVP-0 目前狀態
- ✅ iOS 專案可編譯（SwiftUI + XcodeGen）
- ⏳ Android 專案（待完成）
- ⏳ 基礎架構（待完成）

## iOS 本機建置
```bash
cd ios
xcodegen generate
xcodebuild -project ExpenseTrackerNative.xcodeproj \
  -scheme ExpenseTrackerNative \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Docs: 見 `docs/ROADMAP.md`

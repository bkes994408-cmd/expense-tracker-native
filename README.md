# 記帳APP（原生 iOS + Android）

## MVP-0 目前狀態
- ⏳ iOS 專案（待完成）
- ✅ Android 專案可編譯（Gradle + Kotlin + Compose）
- ✅ 基礎架構 baseline（Network/Data/Domain/UI）

## Android 本機建置
```bash
cd android
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
ANDROID_HOME="$HOME/Library/Android/sdk" \
./gradlew :app:assembleDebug
```

## 架構說明
- `docs/ARCHITECTURE.md`

Docs: 見 `docs/ROADMAP.md`、`docs/ARCHITECTURE.md`

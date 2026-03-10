# Release Checklist（MVP-4）

> 目的：在 iOS / Android 上架前，確認功能、品質、法遵、發佈流程皆可追溯。

## 1) Scope / 版本凍結

- [ ] 已確認 release 範圍（本版功能、已知限制、延期項目）
- [ ] 已建立 release branch / tag 命名規則（例如 `v0.1.0`）
- [ ] `CHANGELOG` 或 release notes 草稿完成

## 2) 功能與測試驗證

- [ ] 核心流程 smoke test：新增帳目、刪除帳目、月總覽更新
- [ ] iOS UI test 通過（`ExpenseTrackerUITests`）
- [ ] Android UI test 通過（`ExpenseFlowUiTest`）
- [ ] 本地資料流程驗證（離線可操作，重啟後資料一致）
- [ ] 匯出 CSV 功能可用（格式與欄位正確）

## 3) 穩定性與觀測

- [ ] Crash handler 已啟用（iOS / Android）
- [ ] 核心事件 telemetry 可記錄（啟動、登入、新增帳目、匯出）
- [ ] 發佈前確認 log 不含敏感資訊（token、email、PII）

## 4) 安全與隱私

- [ ] 憑證與敏感資料存放於 Keychain / Keystore
- [ ] 僅使用 HTTPS/TLS 連線
- [ ] 隱私政策文件可存取：`docs/PRIVACY_POLICY.md`
- [ ] 資料刪除流程文件可存取：`docs/DATA_DELETION_PROCESS.md`

## 5) iOS 上架準備（App Store Connect）

- [ ] Bundle ID / Team / Signing 設定正確
- [ ] 版本號（Marketing Version）與 Build Number 已更新
- [ ] App Icon、Launch、截圖、描述、關鍵字已備齊
- [ ] Privacy Nutrition Labels 已填寫
- [ ] TestFlight build 上傳成功並完成基本驗證

## 6) Android 上架準備（Google Play Console）

- [ ] `applicationId`、versionCode、versionName 已更新
- [ ] 產出並驗證 AAB（release build）
- [ ] Play App Signing / keystore 流程確認
- [ ] Store listing（圖示、截圖、描述）已備齊
- [ ] Data safety 表單已填寫
- [ ] Internal testing track 發佈與安裝驗證完成

## 7) 發佈決策與回滾

- [ ] Go/No-Go 會議：確認 blocker 為 0
- [ ] 發佈負責人與聯絡窗口已指定
- [ ] 回滾策略已確認（下架、hotfix、版本回退）
- [ ] 發佈後 24-48 小時監控計畫已排定

## 8) 發佈後檢查

- [ ] 實際安裝/更新驗證（新安裝 + 升級）
- [ ] Crash rate、ANR、啟動成功率監控
- [ ] 使用者回饋管道可用（email/表單/社群）
- [ ] 產出 release retrospective（問題、改善、下一版）

---

## 建議執行指令（可直接複製）

### iOS build
```bash
xcodebuild \
  -project ios/ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build
```

### Android build
```bash
cd android
./gradlew :app:assembleDebug
```

### Android UI tests（connected）
```bash
cd android
./gradlew :app:connectedDebugAndroidTest
```

> 說明：此 checklist 為「MVP-4：上架準備 / Release checklist」基線，可在每次 release 建立複本並勾選留存。
# Roadmap / MVP Checklist（記帳APP：原生 iOS + Android）

> 目標：先達成「可用 MVP」+ 完整功能測試基礎，再談進階同步/效能。

## MVP-0：專案初始化（門檻）
- [x] iOS 專案建立（Xcode / Swift）可編譯執行
- [x] Android 專案建立（Gradle / Kotlin）可編譯執行
- [x] 基礎架構：網路層、資料層（本機 DB）、Domain 層、UI 層
- [x] CI：iOS build + Android build（GitHub Actions）

## MVP-1：核心功能（離線優先）
- [x] 帳目 CRUD（第一階段：新增/列表/刪除，更新接口已預留）
- [x] 分類管理（第一階段：新增/列表，封存/排序保留介面並可擴充）
- [x] 帳目列表篩選/搜尋（第一階段：標題搜尋）
- [ ] 每月總覽（收入/支出/分類彙總）
- [ ] 訂閱管理（週期、下次扣款、提醒）
- [ ] 分期管理（期數/每期/剩餘/本月應繳）
- [ ] 匯出（CSV）

## MVP-2：雲端同步（後續可拆）
- [ ] Auth（註冊/登入）
- [ ] Delta sync（mutations + cursor）
- [ ] 衝突偵測與處理（version/updatedAt）

## MVP-3：完整功能測試（必備）
- [ ] iOS：至少 1 條 UI 測試（新增帳目→月總覽數字變更）
- [ ] Android：至少 1 條 UI 測試（同流程）
- [ ] 同步（若有）：至少 1 條 integration 測試（兩端資料一致）
- [ ] 安全：Keychain/Keystore、TLS、log 脫敏

## MVP-4：上架準備
- [ ] 隱私政策/資料刪除流程
- [ ] Crash/analytics（可選）
- [ ] Release checklist

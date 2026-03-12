# Web/Desktop 版本規劃（MVP-5）

> 目標：在不犧牲目前 iOS / Android 原生體驗的前提下，規劃可擴展的 Web/Desktop 版本，優先滿足「檢視 + 輕量編輯 + 匯出」需求，並與既有資料模型與同步策略對齊。

## 1) 範圍定義（Scope）

### Phase A（MVP Web）
- 帳目列表檢視（搜尋、時間區間篩選、分類篩選）
- 月總覽（收入/支出/分類彙總）
- 進階報表只開放 Pro（沿用行動端 paywall 規則）
- CSV/PDF 匯出
- 帳號登入（沿用現有 Auth skeleton，補齊雲端 token 流程）

### Phase B（MVP Desktop）
- 打包桌面版（macOS / Windows，Linux 視需求）
- 本地快取 + 離線唯讀（先不做完整離線編輯衝突合併）
- 系統通知（訂閱提醒、預算警示）

### 明確不納入（本輪）
- 複雜分期編輯流程
- 即時多人協作
- 大型 BI 儀表板（企業級）

## 2) 技術路線建議

### 前端技術
- **Web UI**：React + TypeScript（共享 domain 邏輯較容易）
- **State 管理**：TanStack Query + Zustand（或 Redux Toolkit）
- **Desktop 包裝**：Tauri（優先）
  - 優點：比 Electron 輕量、記憶體占用較低、啟動快
  - 若遇到 plugin 生態限制，再評估 Electron fallback

### 共用邏輯策略
- 將「報表計算、預算規則、方案 gating」抽離成可共享 module（Kotlin/Swift 各自實作先保留，Web 端用 TypeScript 對齊同規格測試）
- 以「規格一致 + 測試向量一致」取代強制同語言共享，降低重構風險

## 3) 後端與同步對齊

- API 先沿用現有資料模型：`Expense`、`Category`、`Subscription`、`Installment`
- 同步協議延續 MVP-2：`mutations + cursor + version/updatedAt`
- Web/Desktop 先採「線上優先 + 本地快取」
- 權限策略：
  - Free：基本列表與月總覽
  - Pro：進階報表、高階匯出、更多篩選能力

## 4) 資安與隱私

- Web token 儲存：HTTP-only cookie（優先）或短效 access token + refresh rotation
- Desktop 憑證儲存：系統 keychain/credential vault
- 保持 log 脫敏（沿用 mobile 既有策略）
- 文件對齊：`docs/PRIVACY_POLICY.md` 與 `docs/DATA_DELETION_PROCESS.md`

## 5) 里程碑與預估

### M1（1~2 週）— 架構打底
- Web 專案初始化（routing/auth/layout）
- API client 與資料模型定稿
- 設定 CI（web build + lint + unit test）

### M2（2 週）— 核心頁面
- 帳目列表、月總覽、基礎篩選
- CSV 匯出
- Pro gating + paywall Web 版本

### M3（1~2 週）— Desktop 打包
- Tauri 打包流程
- 系統通知與基本設定
- 安裝包驗證（macOS / Windows）

### M4（1 週）— 穩定化
- E2E smoke（登入、列表、報表、匯出）
- 效能基線與 crash 監控
- 文件與上線清單

## 6) 驗收標準（Definition of Done）

- 可在瀏覽器完成：登入、檢視帳目、查看月總覽、匯出 CSV
- Pro gating 與行動端一致（同一帳號狀態）
- Desktop 可安裝並成功登入，支援基本通知
- CI 維持綠燈，且至少包含：
  - 單元測試（報表/預算規則）
  - E2E smoke（1 條以上）
  - 安全檢查（dependency scan / secret scan）

## 7) 風險與緩解

- **風險：** Web 與 Mobile 規則漂移
  - **緩解：** 建立共享測試向量（同一批輸入/輸出 fixtures）
- **風險：** Desktop 打包相依複雜
  - **緩解：** 優先 Tauri + 最小 plugin，維持 fallback 方案
- **風險：** 同步衝突在多端更常見
  - **緩解：** 先提供明確衝突提示與手動解決 UI，再做自動 merge 策略

---

本文件完成 MVP-5「Web/Desktop 版本規劃（跨平台擴展）」項目，供下一輪實作（MVP-6/7）直接拆分成 engineering tasks。

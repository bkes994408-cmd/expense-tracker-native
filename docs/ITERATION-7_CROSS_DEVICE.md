# Iteration-7 跨裝置擴展（實作紀錄）

## 本輪交付

### 1) Web 報表中心（React + TypeScript）
- 路徑：`web-report-center/`
- 內容：
  - React + TS 專案骨架（Vite）
  - 月總覽卡片（收入 / 支出 / 淨額）
  - 支出分類 Top5
  - 報表計算函式獨立於 UI（`src/lib/reporting.ts`）

### 2) Desktop 快速輸入工具（Tauri）
- 路徑：`desktop-quick-entry/`
- 內容：
  - Tauri 2 Rust 殼層（`src-tauri/`）
  - React + TS 前端快速輸入表單（`web/`）
  - Rust command：`save_quick_entry`
  - 輸入驗證與基本 UX（標題/分類/金額）

### 3) 雲端同步架構基礎
- 路徑：`shared/cloud-sync/`
- 內容：
  - TypeScript Sync 型別：`SyncMutation`, `SyncCursor`, `SyncPullResult`
  - `CloudSyncOrchestrator`：提供 enqueue / flush / cursor 管理
  - 傳輸層抽象：`SyncTransport`，便於接後端 API

## 設計原則
- 與既有 iOS sync 模型對齊（`mutation + cursor`）
- UI 與計算邏輯分離，利於後續共用規格測試向量
- Web / Desktop 採最小可運作骨架，讓後續迭代可快速疊代

## 下一步建議（Iteration-7.1）
1. 將 `shared/cloud-sync` 接上實際 backend API（push/pull endpoint）
2. Web 加入 Auth token 流程與真實資料查詢
3. Desktop 前端改用 Tauri invoke 串接 Rust `save_quick_entry` 與本地快取
4. 新增 CI job：web build、desktop tauri check、cloud-sync unit tests

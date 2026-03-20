# Iteration-7 跨裝置擴展（實作紀錄）

## 本輪交付

### 1) Web 報表中心（React + TypeScript）
- 路徑：`web-report-center/`
- 內容：
  - React + TS 專案骨架（Vite）
  - 月份切換 + 月總覽卡片（收入 / 支出 / 淨額）
  - 支出分類 Top5（含占比）
  - 報表計算函式獨立於 UI（`src/lib/reporting.ts`，提供 month filter / months extraction）

### 2) Desktop 快速輸入工具（Tauri）
- 路徑：`desktop-quick-entry/`
- 內容：
  - Tauri 2 Rust 殼層（`src-tauri/`）
  - React + TS 前端快速輸入表單（`web/`）
  - Rust command：`save_quick_entry`
  - 前端 `@tauri-apps/api` invoke 串接 + 非 Tauri 環境 local mock fallback
  - 輸入驗證與提交狀態 UX（標題/分類/金額）

### 3) 雲端同步架構基礎
- 路徑：`shared/cloud-sync/`
- 內容：
  - TypeScript Sync 型別：`SyncMutation`, `SyncCursor`, `SyncPullResult`, `SyncFlushResult`
  - `CloudSyncOrchestrator`：提供 hydrate / enqueue / flush / cursor 管理
  - 內建 `InMemorySyncStore` + `SyncStore` 介面，便於接 local DB/kv
  - chunked push（batch size）+ patch callback hooks（onPatches/onSyncError）
  - 傳輸層抽象：`SyncTransport`，便於接後端 API

## 設計原則
- 與既有 iOS sync 模型對齊（`mutation + cursor`）
- UI 與計算邏輯分離，利於後續共用規格測試向量
- Web / Desktop 採最小可運作骨架，讓後續迭代可快速疊代

## CI
- 新增 `.github/workflows/cross-platform.yml`
  - web-report-center build
  - desktop-quick-entry/web build
  - shared/cloud-sync typecheck

## 下一步建議（Iteration-7.1）
1. 將 `shared/cloud-sync` 接上實際 backend API（push/pull endpoint）
2. Web 加入 Auth token 流程與真實資料查詢
3. Desktop 補上 Tauri 端本地儲存（SQLite）與系統通知
4. cloud-sync 補齊 unit tests（包括 conflict / partial-ack 案例）

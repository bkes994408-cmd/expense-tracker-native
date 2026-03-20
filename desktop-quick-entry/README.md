# Desktop Quick Entry (Tauri Menu Bar)

Iteration-7 的桌面快速輸入工具，目標是提供 Menu Bar 常駐快捷記帳入口。

## 結構
- `web/`：快速輸入 UI（React + TS）
- `src-tauri/`：Tauri shell + tray/menu 設定

## 目前能力
- Menu Bar / System Tray 常駐
- 快速輸入表單（標題、金額、分類）
- 透過 Tauri command 將輸入 payload 送至 Rust 層（目前先印 log，後續接 SyncMutation）

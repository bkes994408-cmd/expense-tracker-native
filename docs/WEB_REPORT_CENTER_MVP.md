# Web 報表中心 MVP（Iteration-7 Slice）

本文件描述 Iteration-7 的第一個可落地垂直切片：
以 **React + TypeScript** 建立可運行的 Web 報表中心基礎。

## 這一版完成內容

- 新增 `web/` 前端專案（Vite + React + TypeScript）
- 報表控制列：
  - 區間篩選：`1M / 3M / 6M / 12M`
  - 資料篩選：`all / income / expense / net`
  - 圖表模式：`line / bar`
- 訂閱狀態切換（Free / Pro）與區間權限 gating：
  - Free 僅可使用 `1M`
  - `3M / 6M / 12M` 顯示為 `（Pro）` 並鎖定
  - 切換回 Free 會自動回落到 `1M`
- 大螢幕友善版面（1200px container + 卡片式 summary + chart panel）
- 趨勢圖（Recharts）
- 匯總卡片：收入 / 支出 / 淨額
- 單元測試：`reportCalculator` 的區間過濾、月彙總、篩選映射、summary 計算
- UI 測試：控制列互動（切換區間、篩選、圖表模式）

## 執行方式

```bash
cd web
npm install
npm run test
npm run build
npm run dev
```

## 目前資料來源

- 先使用 `src/data/sampleEntries.ts` 的本機範例資料。
- 目的是先驗證 Web 報表中心在功能結構與 UI 互動上可工作。

## 下一步（TODO）

1. 串接正式同步資料源（Supabase sync 完成後改為實際用戶資料）
2. 新增分類占比、分類 drill-down 與 MoM/YoY 詳細分析卡
3. 加入 PDF 匯出（Web print/PDF pipeline）
4. 導入 e2e 測試（Playwright）與 CI job（web build/test）

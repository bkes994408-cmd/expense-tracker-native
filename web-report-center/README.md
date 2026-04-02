# web-report-center

Phase 2（Web 端最小接線）已接入 `@expense-tracker/cloud-sync`：

- `CloudSyncOrchestrator`
- `SupabaseSyncTransport`
- 最小 smoke flow：`expenses` / `categories`

## 本地設定

1. 安裝依賴

```bash
cd web-report-center
npm install
```

2. 建立環境變數

```bash
cp .env.example .env.local
```

填入以下欄位：

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SYNC_USER_ID`
- `VITE_SYNC_DEVICE_ID`

> `VITE_SYNC_USER_ID` 請與 Supabase `sync_mutations.user_id` 對齊。

3. 啟動

```bash
npm run dev
```

## Smoke Flow（expenses/categories）

在頁面點擊：

`執行雲端同步 Smoke（expenses/categories）`

流程：

1. 將當前本地 `expenses/categories` enqueue 為 mutation
2. `flush()` 先 push、再 pull 其他裝置 patch
3. 將 pull 回來的 patch 套用到畫面（LWW merge）

## 最小測試

```bash
npm run test
```

測試檔：`src/features/syncSmoke.test.ts`

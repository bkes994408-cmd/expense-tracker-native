# @expense-tracker/cloud-sync

Iteration-7.1 / Phase 1 最小可用同步閉環（Supabase）

## Scope（本輪）
- 實作正式版同步後端最小路徑：Supabase
- 同步主體：`expenses` + `categories`
- 流程：`enqueue -> push -> pull -> merge`
- 衝突策略：`updatedAt` last-write-wins（LWW）

## 安裝

```bash
cd shared/cloud-sync
npm install
```

## Supabase 必要資料表

請在 Supabase SQL Editor 執行：`./supabase/schema.sql`

## 最小使用方式

```ts
import {
  CloudSyncOrchestrator,
  InMemorySyncStore,
  SupabaseSyncTransport,
  mergeExpenses,
  mergeCategories
} from "@expense-tracker/cloud-sync";

const transport = new SupabaseSyncTransport({
  supabaseUrl: process.env.SUPABASE_URL!,
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY!,
  userId: "user-123",
  deviceId: "ios-device-a"
});

const orchestrator = new CloudSyncOrchestrator(transport, new InMemorySyncStore(), {
  onPatches(patches) {
    const expensePatches = patches
      .filter((p) => p.entity === "expense")
      .map((p) => JSON.parse(p.payload));

    const categoryPatches = patches
      .filter((p) => p.entity === "category")
      .map((p) => JSON.parse(p.payload));

    // localExpenses / localCategories 由 app 端儲存層提供
    // const mergedExpenses = mergeExpenses(localExpenses, expensePatches)
    // const mergedCategories = mergeCategories(localCategories, categoryPatches)
    // ...persist merged data
  }
});

await orchestrator.hydrate();
await orchestrator.flush();
```

## 驗證

```bash
npm run check
npm run test
```

> `test` 目前覆蓋 merge 基礎邏輯（expenses/categories）。

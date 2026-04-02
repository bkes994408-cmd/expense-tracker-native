import { CloudSyncOrchestrator, SupabaseSyncTransport, mergeCategories, mergeExpenses, type CategorySyncRecord, type ExpenseSyncRecord, type SyncMutation, type SyncStore } from "@expense-tracker/cloud-sync";
import type { ExpenseRecord } from "../types/expense";

export interface SyncCategory {
  id: string;
  name: string;
  updatedAt: string;
}

export interface SyncState {
  expenses: ExpenseRecord[];
  categories: SyncCategory[];
}

const CURSOR_KEY = "cursor";
const QUEUE_KEY = "queue";

interface EnvConfig {
  supabaseUrl: string;
  supabaseAnonKey: string;
  userId: string;
  deviceId: string;
}

const nowIso = () => new Date().toISOString();

export function getEnvConfig(): EnvConfig | null {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  const userId = import.meta.env.VITE_SYNC_USER_ID;
  const deviceId = import.meta.env.VITE_SYNC_DEVICE_ID;

  if (!supabaseUrl || !supabaseAnonKey || !userId || !deviceId) return null;
  return { supabaseUrl, supabaseAnonKey, userId, deviceId };
}

export function deriveCategories(records: ExpenseRecord[]): SyncCategory[] {
  const seen = new Map<string, SyncCategory>();
  for (const record of records) {
    const id = `cat-${record.category.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`;
    if (!seen.has(id)) {
      seen.set(id, { id, name: record.category, updatedAt: nowIso() });
    }
  }
  return [...seen.values()];
}

export function createBrowserSyncStore(prefix = "web-report-center-sync"): SyncStore {
  const key = (name: string) => `${prefix}:${name}`;

  return {
    async loadQueue() {
      const raw = localStorage.getItem(key(QUEUE_KEY));
      if (!raw) return [];
      try {
        return JSON.parse(raw) as SyncMutation[];
      } catch {
        return [];
      }
    },
    async saveQueue(queue) {
      localStorage.setItem(key(QUEUE_KEY), JSON.stringify(queue));
    },
    async loadCursor() {
      const raw = localStorage.getItem(key(CURSOR_KEY));
      if (!raw) return {};
      try {
        return JSON.parse(raw);
      } catch {
        return {};
      }
    },
    async saveCursor(cursor) {
      localStorage.setItem(key(CURSOR_KEY), JSON.stringify(cursor));
    }
  };
}

function toExpenseSyncRecord(record: ExpenseRecord): ExpenseSyncRecord {
  return {
    id: record.id,
    title: record.title,
    amount: record.amount,
    type: record.type,
    categoryId: `cat-${record.category.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`,
    createdAt: record.createdAt,
    updatedAt: record.createdAt
  };
}

function toCategorySyncRecord(category: SyncCategory): CategorySyncRecord {
  return {
    id: category.id,
    name: category.name,
    updatedAt: category.updatedAt
  };
}

export function applyIncomingPatches(state: SyncState, patches: SyncMutation[]): SyncState {
  const expenseUpdates: ExpenseSyncRecord[] = [];
  const categoryUpdates: CategorySyncRecord[] = [];
  const deletedExpenseIds = new Set<string>();
  const deletedCategoryIds = new Set<string>();

  for (const patch of patches) {
    if (patch.entity === "expense") {
      if (patch.type === "delete") {
        deletedExpenseIds.add(patch.entityId);
        continue;
      }
      expenseUpdates.push(JSON.parse(patch.payload) as ExpenseSyncRecord);
      continue;
    }

    if (patch.entity === "category") {
      if (patch.type === "delete") {
        deletedCategoryIds.add(patch.entityId);
        continue;
      }
      categoryUpdates.push(JSON.parse(patch.payload) as CategorySyncRecord);
    }
  }

  const localExpenseSync = state.expenses.map(toExpenseSyncRecord);
  const localCategorySync = state.categories.map(toCategorySyncRecord);

  const mergedCategories = mergeCategories(localCategorySync, categoryUpdates).filter((item) => !deletedCategoryIds.has(item.id));
  const categoryMap = new Map(mergedCategories.map((item) => [item.id, item.name]));

  const mergedExpenses = mergeExpenses(localExpenseSync, expenseUpdates)
    .filter((item) => !deletedExpenseIds.has(item.id))
    .map<ExpenseRecord>((item) => ({
      id: item.id,
      title: item.title,
      amount: item.amount,
      type: item.type,
      createdAt: item.createdAt,
      category: categoryMap.get(item.categoryId) ?? item.categoryId
    }));

  return {
    expenses: mergedExpenses,
    categories: mergedCategories.map((item) => ({ id: item.id, name: item.name, updatedAt: item.updatedAt }))
  };
}

export async function runSyncSmoke(state: SyncState, onPatchesApplied: (next: SyncState) => void) {
  const env = getEnvConfig();
  if (!env) {
    throw new Error("缺少同步環境變數：請設定 VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY / VITE_SYNC_USER_ID / VITE_SYNC_DEVICE_ID");
  }

  const transport = new SupabaseSyncTransport({
    supabaseUrl: env.supabaseUrl,
    supabaseAnonKey: env.supabaseAnonKey,
    userId: env.userId,
    deviceId: env.deviceId
  });

  const store = createBrowserSyncStore(`${env.userId}:${env.deviceId}`);
  const orchestrator = new CloudSyncOrchestrator(transport, store, {
    onPatches: (patches) => {
      const next = applyIncomingPatches(state, patches);
      onPatchesApplied(next);
    }
  });

  await orchestrator.hydrate();

  for (const record of state.expenses) {
    const payload = toExpenseSyncRecord(record);
    await orchestrator.enqueue({
      id: `web-smoke-expense-${record.id}`,
      entity: "expense",
      entityId: record.id,
      type: "update",
      payload: JSON.stringify(payload),
      updatedAt: nowIso(),
      userId: env.userId,
      deviceId: env.deviceId
    });
  }

  for (const category of state.categories) {
    const payload = toCategorySyncRecord(category);
    await orchestrator.enqueue({
      id: `web-smoke-category-${category.id}`,
      entity: "category",
      entityId: category.id,
      type: "update",
      payload: JSON.stringify(payload),
      updatedAt: nowIso(),
      userId: env.userId,
      deviceId: env.deviceId
    });
  }

  return orchestrator.flush();
}

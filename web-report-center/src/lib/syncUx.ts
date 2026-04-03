import type { SyncMutation } from "@expense-tracker/cloud-sync";

export type SyncStatus = "synced" | "syncing" | "pending" | "failed";

export function deriveSyncStatus(params: {
  isSyncing: boolean;
  pendingCount: number;
  lastError: string | null;
}): SyncStatus {
  if (params.lastError) return "failed";
  if (params.isSyncing) return "syncing";
  if (params.pendingCount > 0) return "pending";
  return "synced";
}

export function toSyncStatusLabel(status: SyncStatus): string {
  switch (status) {
    case "syncing":
      return "Syncing";
    case "pending":
      return "Pending changes";
    case "failed":
      return "Sync failed";
    case "synced":
    default:
      return "Synced";
  }
}

export interface PendingQueueSummary {
  total: number;
  byEntityType: Partial<Record<SyncMutation["entityType"], number>>;
  oldestClientTimestamp: string | null;
}

export function summarizePendingQueue(mutations: SyncMutation[]): PendingQueueSummary {
  const byEntityType: PendingQueueSummary["byEntityType"] = {};
  let oldestClientTimestamp: string | null = null;

  for (const mutation of mutations) {
    byEntityType[mutation.entityType] = (byEntityType[mutation.entityType] ?? 0) + 1;
    if (!oldestClientTimestamp || mutation.clientTimestamp < oldestClientTimestamp) {
      oldestClientTimestamp = mutation.clientTimestamp;
    }
  }

  return {
    total: mutations.length,
    byEntityType,
    oldestClientTimestamp,
  };
}

export function createDebouncedRunner(runner: () => void, delayMs: number) {
  let timer: ReturnType<typeof setTimeout> | null = null;

  return {
    schedule() {
      if (timer) clearTimeout(timer);
      timer = setTimeout(() => {
        timer = null;
        runner();
      }, delayMs);
    },
    cancel() {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
    },
  };
}

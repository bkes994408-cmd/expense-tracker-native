export interface SyncMergeEntity {
  id: string;
  updatedAt: string;
  deletedAt?: string | null;
}

const toMillis = (value: string) => {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

/**
 * Last-write-wins merge by id + updatedAt.
 * - newer updatedAt wins
 * - if timestamps tie, prefer incoming patch (remote)
 */
export function mergeByUpdatedAt<T extends SyncMergeEntity>(local: T[], incoming: T[]): T[] {
  const merged = new Map<string, T>();

  for (const item of local) {
    merged.set(item.id, item);
  }

  for (const item of incoming) {
    const existing = merged.get(item.id);
    if (!existing) {
      merged.set(item.id, item);
      continue;
    }

    const existingTs = toMillis(existing.updatedAt);
    const incomingTs = toMillis(item.updatedAt);
    if (incomingTs >= existingTs) {
      merged.set(item.id, item);
    }
  }

  return [...merged.values()];
}

export interface ExpenseSyncRecord extends SyncMergeEntity {
  title: string;
  amount: number;
  type: "income" | "expense";
  categoryId: string;
  createdAt: string;
}

export interface CategorySyncRecord extends SyncMergeEntity {
  name: string;
  colorHex?: string;
}

export const mergeExpenses = (local: ExpenseSyncRecord[], incoming: ExpenseSyncRecord[]) =>
  mergeByUpdatedAt(local, incoming);

export const mergeCategories = (local: CategorySyncRecord[], incoming: CategorySyncRecord[]) =>
  mergeByUpdatedAt(local, incoming);

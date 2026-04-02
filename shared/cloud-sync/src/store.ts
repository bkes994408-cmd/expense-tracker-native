import type { SyncCursor, SyncMutation } from "./types.js";

export interface SyncStateStore {
  getCursor(deviceId: string): Promise<SyncCursor | undefined>;
  saveCursor(cursor: SyncCursor): Promise<void>;
  enqueueMutation(mutation: SyncMutation): Promise<void>;
  listPendingMutations(deviceId: string): Promise<SyncMutation[]>;
  markMutationsSynced(deviceId: string, acceptedIds: string[]): Promise<void>;
}

interface QueueItem {
  deviceId: string;
  mutation: SyncMutation;
}

export class InMemorySyncStateStore implements SyncStateStore {
  private readonly cursors = new Map<string, SyncCursor>();
  private readonly queue: QueueItem[] = [];

  async getCursor(deviceId: string): Promise<SyncCursor | undefined> {
    return this.cursors.get(deviceId);
  }

  async saveCursor(cursor: SyncCursor): Promise<void> {
    this.cursors.set(cursor.deviceId, cursor);
  }

  async enqueueMutation(mutation: SyncMutation): Promise<void> {
    const deviceId = mutation.id.split(":")[0] ?? "unknown-device";
    this.queue.push({ deviceId, mutation });
  }

  async listPendingMutations(deviceId: string): Promise<SyncMutation[]> {
    return this.queue.filter((item) => item.deviceId === deviceId).map((item) => item.mutation);
  }

  async markMutationsSynced(deviceId: string, acceptedIds: string[]): Promise<void> {
    const accepted = new Set(acceptedIds);
    for (let i = this.queue.length - 1; i >= 0; i -= 1) {
      const item = this.queue[i];
      if (item.deviceId === deviceId && accepted.has(item.mutation.id)) {
        this.queue.splice(i, 1);
      }
    }
  }
}

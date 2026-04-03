import type { SyncStateStore } from "./store.js";
import type { SyncCursor, SyncMutation, SyncTransport } from "./types.js";

export class SyncEngine {
  constructor(
    private readonly deviceId: string,
    private readonly store: SyncStateStore,
    private readonly transport: SyncTransport,
  ) {}

  async stageMutation(mutation: Omit<SyncMutation, "id" | "clientTimestamp">): Promise<SyncMutation> {
    const staged: SyncMutation = {
      ...mutation,
      id: `${this.deviceId}:${crypto.randomUUID()}`,
      clientTimestamp: new Date().toISOString(),
    };
    await this.store.enqueueMutation(staged);
    return staged;
  }

  async syncNow(): Promise<{ pushed: number; pulled: number; cursor: SyncCursor }> {
    const cursor = (await this.store.getCursor(this.deviceId)) ?? {
      deviceId: this.deviceId,
      lastSyncedAt: new Date(0).toISOString(),
    };
    const pending = await this.store.listPendingMutations(this.deviceId);

    const pushResult = await this.transport.pushMutations({
      deviceId: this.deviceId,
      baseCursor: cursor.serverCursor,
      mutations: pending,
    });

    if (pushResult.acceptedIds.length > 0) {
      await this.store.markMutationsSynced(this.deviceId, pushResult.acceptedIds);
    }

    const pullResult = await this.transport.pullMutations({
      deviceId: this.deviceId,
      fromCursor: pushResult.nextCursor,
    });

    const nextCursor: SyncCursor = {
      deviceId: this.deviceId,
      lastSyncedAt: new Date().toISOString(),
      serverCursor: pullResult.nextCursor,
      mutationWatermark: pullResult.mutations[pullResult.mutations.length - 1]?.id ?? cursor.mutationWatermark,
    };
    await this.store.saveCursor(nextCursor);

    return {
      pushed: pushResult.acceptedIds.length,
      pulled: pullResult.mutations.length,
      cursor: nextCursor,
    };
  }
}

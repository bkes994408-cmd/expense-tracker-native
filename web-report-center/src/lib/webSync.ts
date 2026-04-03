import type { SyncCursor, SyncStateStore, SyncTransport } from "@expense-tracker/cloud-sync";

export interface RunSyncResult {
  pushed: number;
  pulled: number;
  cursor: SyncCursor;
  pulledMutations: Awaited<ReturnType<SyncTransport["pullMutations"]>>["mutations"];
  pushedMutationIds: string[];
}

export async function runSyncOnce(
  deviceId: string,
  store: SyncStateStore,
  transport: SyncTransport,
): Promise<RunSyncResult> {
  const cursor = (await store.getCursor(deviceId)) ?? {
    deviceId,
    lastSyncedAt: new Date(0).toISOString(),
    serverCursor: "0",
  };

  const pending = await store.listPendingMutations(deviceId);
  const pushResult = await transport.pushMutations({
    deviceId,
    baseCursor: cursor.serverCursor,
    mutations: pending,
  });

  if (pushResult.acceptedIds.length > 0) {
    await store.markMutationsSynced(deviceId, pushResult.acceptedIds);
  }

  const pullResult = await transport.pullMutations({
    deviceId,
    fromCursor: pushResult.nextCursor,
  });

  const nextCursor: SyncCursor = {
    deviceId,
    lastSyncedAt: new Date().toISOString(),
    serverCursor: pullResult.nextCursor,
    mutationWatermark: pullResult.mutations[pullResult.mutations.length - 1]?.id ?? cursor.mutationWatermark,
  };

  await store.saveCursor(nextCursor);

  return {
    pushed: pushResult.acceptedIds.length,
    pulled: pullResult.mutations.length,
    cursor: nextCursor,
    pulledMutations: pullResult.mutations,
    pushedMutationIds: pushResult.acceptedIds,
  };
}

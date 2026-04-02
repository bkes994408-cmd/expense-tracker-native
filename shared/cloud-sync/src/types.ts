export type EntityType = "expense" | "category" | "subscription" | "installment";

export interface SyncMutation<TPayload = unknown> {
  id: string;
  entityType: EntityType;
  entityId: string;
  operation: "create" | "update" | "delete";
  payload: TPayload;
  clientTimestamp: string;
  version: number;
}

export interface SyncCursor {
  deviceId: string;
  lastSyncedAt: string;
  serverCursor?: string;
  mutationWatermark?: string;
}

export interface SyncPullResult {
  cursor: SyncCursor;
  patches: SyncMutation[];
}

export interface SyncFlushResult {
  pushed: number;
  patched: number;
  hasPending: boolean;
}

export interface SyncPushRequest {
  deviceId: string;
  baseCursor?: string;
  mutations: SyncMutation[];
}

export interface SyncPullRequest {
  deviceId: string;
  fromCursor?: string;
}

export interface SyncTransport {
  pushMutations(request: SyncPushRequest): Promise<{ acceptedIds: string[]; nextCursor: string }>;
  pullMutations(request: SyncPullRequest): Promise<{ mutations: SyncMutation[]; nextCursor: string }>;
}

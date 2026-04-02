export type SyncMutationType = "create" | "update" | "delete";

export type SyncEntity = "expense" | "category" | "subscription" | "installment" | "profile" | "budget";

export interface SyncMutation {
  id: string;
  entity: SyncEntity;
  entityId: string;
  type: SyncMutationType;
  payload: string;
  updatedAt: string;
  deviceId?: string;
  userId?: string;
}

export interface SyncCursor {
  lastPulledAt?: string;
  lastMutationId?: string;
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

export type SyncMutationType = "create" | "update" | "delete";

export interface SyncMutation {
  id: string;
  entity: "expense" | "category" | "subscription" | "installment";
  entityId: string;
  type: SyncMutationType;
  payload: string;
  updatedAt: string;
  deviceId?: string;
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

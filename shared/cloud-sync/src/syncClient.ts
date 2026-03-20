import type { SyncCursor, SyncFlushResult, SyncMutation, SyncPullResult } from "./types";

export interface SyncTransport {
  push(mutations: SyncMutation[]): Promise<{ acceptedMutationIds: string[] }>;
  pull(cursor: SyncCursor): Promise<SyncPullResult>;
}

export interface SyncStore {
  loadQueue(): Promise<SyncMutation[]>;
  saveQueue(queue: SyncMutation[]): Promise<void>;
  loadCursor(): Promise<SyncCursor>;
  saveCursor(cursor: SyncCursor): Promise<void>;
}

export interface SyncHooks {
  onPatches?(patches: SyncMutation[]): Promise<void> | void;
  onSyncError?(error: Error): void;
}

export interface CloudSyncOptions {
  batchSize?: number;
}

export class InMemorySyncStore implements SyncStore {
  private queue: SyncMutation[] = [];
  private cursor: SyncCursor = {};

  async loadQueue(): Promise<SyncMutation[]> {
    return [...this.queue];
  }

  async saveQueue(queue: SyncMutation[]): Promise<void> {
    this.queue = [...queue];
  }

  async loadCursor(): Promise<SyncCursor> {
    return { ...this.cursor };
  }

  async saveCursor(cursor: SyncCursor): Promise<void> {
    this.cursor = { ...cursor };
  }
}

export class CloudSyncOrchestrator {
  private cursor: SyncCursor = {};
  private queue: SyncMutation[] = [];
  private readonly batchSize: number;

  constructor(
    private readonly transport: SyncTransport,
    private readonly store: SyncStore = new InMemorySyncStore(),
    private readonly hooks: SyncHooks = {},
    options: CloudSyncOptions = {}
  ) {
    this.batchSize = Math.max(1, options.batchSize ?? 30);
  }

  async hydrate() {
    this.queue = await this.store.loadQueue();
    this.cursor = await this.store.loadCursor();
  }

  async enqueue(mutation: SyncMutation) {
    this.queue.push(mutation);
    await this.store.saveQueue(this.queue);
  }

  peekQueue() {
    return [...this.queue];
  }

  getCursor() {
    return { ...this.cursor };
  }

  async flush(): Promise<SyncFlushResult> {
    try {
      let pushedCount = 0;

      while (this.queue.length > 0) {
        const chunk = this.queue.slice(0, this.batchSize);
        const pushed = await this.transport.push(chunk);
        const accepted = new Set(pushed.acceptedMutationIds);

        if (accepted.size === 0) {
          break;
        }

        this.queue = this.queue.filter((mutation) => !accepted.has(mutation.id));
        pushedCount += accepted.size;
      }

      await this.store.saveQueue(this.queue);

      const pulled = await this.transport.pull(this.cursor);
      this.cursor = pulled.cursor;
      await this.store.saveCursor(this.cursor);

      await this.hooks.onPatches?.(pulled.patches);

      return {
        pushed: pushedCount,
        patched: pulled.patches.length,
        hasPending: this.queue.length > 0
      };
    } catch (error) {
      const normalized = error instanceof Error ? error : new Error(String(error));
      this.hooks.onSyncError?.(normalized);
      throw normalized;
    }
  }
}

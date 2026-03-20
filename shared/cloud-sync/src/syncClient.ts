import type { SyncCursor, SyncMutation, SyncPullResult } from "./types";

export interface SyncTransport {
  push(mutations: SyncMutation[]): Promise<{ acceptedMutationIds: string[] }>;
  pull(cursor: SyncCursor): Promise<SyncPullResult>;
}

export class CloudSyncOrchestrator {
  private cursor: SyncCursor = {};
  private queue: SyncMutation[] = [];

  constructor(private readonly transport: SyncTransport) {}

  enqueue(mutation: SyncMutation) {
    this.queue.push(mutation);
  }

  peekQueue() {
    return [...this.queue];
  }

  getCursor() {
    return this.cursor;
  }

  async flush() {
    if (this.queue.length === 0) return { pushed: 0, patched: 0 };

    const pending = [...this.queue];
    const pushed = await this.transport.push(pending);
    const accepted = new Set(pushed.acceptedMutationIds);

    this.queue = this.queue.filter((m) => !accepted.has(m.id));

    const pulled = await this.transport.pull(this.cursor);
    this.cursor = pulled.cursor;

    return { pushed: pushed.acceptedMutationIds.length, patched: pulled.patches.length };
  }
}

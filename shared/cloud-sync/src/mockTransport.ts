import type { SyncMutation, SyncPullRequest, SyncPushRequest, SyncTransport } from "./types.js";

export class InMemorySyncTransport implements SyncTransport {
  private readonly mutations: SyncMutation[] = [];

  async pushMutations(request: SyncPushRequest): Promise<{ acceptedIds: string[]; nextCursor: string }> {
    for (const mutation of request.mutations) {
      const exists = this.mutations.some((item) => item.id === mutation.id);
      if (!exists) this.mutations.push(mutation);
    }
    return {
      acceptedIds: request.mutations.map((m) => m.id),
      nextCursor: `${this.mutations.length}`,
    };
  }

  async pullMutations(request: SyncPullRequest): Promise<{ mutations: SyncMutation[]; nextCursor: string }> {
    const start = Number(request.fromCursor ?? "0");
    const mutations = this.mutations.slice(Number.isNaN(start) ? 0 : start);
    return {
      mutations,
      nextCursor: `${this.mutations.length}`,
    };
  }
}

import type { SyncMutation, SyncPullRequest, SyncPushRequest, SyncTransport } from "./types.js";

export interface SupabaseSyncTransportOptions {
  supabaseUrl: string;
  anonKey: string;
  schema?: string;
}

interface RpcResponse<T> {
  data: T;
  error?: { message?: string };
}

export class SupabaseSyncTransport implements SyncTransport {
  private readonly schema: string;

  constructor(private readonly options: SupabaseSyncTransportOptions) {
    this.schema = options.schema ?? "public";
  }

  async pushMutations(request: SyncPushRequest): Promise<{ acceptedIds: string[]; nextCursor: string }> {
    const result = await this.rpc<{ acceptedIds: string[]; nextCursor: string }>("sync_push_mutations", {
      p_device_id: request.deviceId,
      p_base_cursor: request.baseCursor ?? null,
      p_mutations: request.mutations,
    });

    return {
      acceptedIds: result.acceptedIds ?? [],
      nextCursor: result.nextCursor,
    };
  }

  async pullMutations(request: SyncPullRequest): Promise<{ mutations: SyncMutation[]; nextCursor: string }> {
    const result = await this.rpc<{ mutations: SyncMutation[]; nextCursor: string }>("sync_pull_mutations", {
      p_device_id: request.deviceId,
      p_from_cursor: request.fromCursor ?? null,
    });

    return {
      mutations: result.mutations ?? [],
      nextCursor: result.nextCursor,
    };
  }

  private async rpc<T>(fn: string, body: object): Promise<T> {
    const url = `${this.options.supabaseUrl}/rest/v1/rpc/${fn}`;
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: this.options.anonKey,
        Authorization: `Bearer ${this.options.anonKey}`,
        "Accept-Profile": this.schema,
        "Content-Profile": this.schema,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Supabase RPC ${fn} failed: ${response.status} ${text}`);
    }

    const payload = (await response.json()) as RpcResponse<T> | T;
    const normalized = (payload as RpcResponse<T>).data ? (payload as RpcResponse<T>).data : (payload as T);

    if ((payload as RpcResponse<T>).error) {
      throw new Error((payload as RpcResponse<T>).error?.message ?? `Supabase RPC ${fn} returned error`);
    }

    return normalized;
  }
}

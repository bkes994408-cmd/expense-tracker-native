import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { SyncCursor, SyncMutation, SyncPullResult } from "./types";
import type { SyncTransport } from "./syncClient";

interface SyncMutationRow {
  id: string;
  user_id: string;
  device_id: string | null;
  entity: string;
  entity_id: string;
  mutation_type: "create" | "update" | "delete";
  payload: string;
  updated_at: string;
  created_at: string;
}

export interface SupabaseSyncTransportOptions {
  supabaseUrl: string;
  supabaseAnonKey: string;
  userId: string;
  deviceId: string;
  tableName?: string;
  pullLimit?: number;
}

export class SupabaseSyncTransport implements SyncTransport {
  private readonly client: SupabaseClient;
  private readonly userId: string;
  private readonly deviceId: string;
  private readonly tableName: string;
  private readonly pullLimit: number;

  constructor(options: SupabaseSyncTransportOptions) {
    this.client = createClient(options.supabaseUrl, options.supabaseAnonKey);
    this.userId = options.userId;
    this.deviceId = options.deviceId;
    this.tableName = options.tableName ?? "sync_mutations";
    this.pullLimit = Math.max(1, options.pullLimit ?? 300);
  }

  async push(mutations: SyncMutation[]): Promise<{ acceptedMutationIds: string[] }> {
    if (mutations.length === 0) return { acceptedMutationIds: [] };

    const rows: SyncMutationRow[] = mutations.map((mutation) => ({
      id: mutation.id,
      user_id: mutation.userId ?? this.userId,
      device_id: mutation.deviceId ?? this.deviceId,
      entity: mutation.entity,
      entity_id: mutation.entityId,
      mutation_type: mutation.type,
      payload: mutation.payload,
      updated_at: mutation.updatedAt,
      created_at: new Date().toISOString()
    }));

    const { error } = await this.client.from(this.tableName).upsert(rows, { onConflict: "id" });
    if (error) throw new Error(`Supabase push failed: ${error.message}`);

    return { acceptedMutationIds: mutations.map((m) => m.id) };
  }

  async pull(cursor: SyncCursor): Promise<SyncPullResult> {
    const lastPulledAt = cursor.lastPulledAt ?? "1970-01-01T00:00:00.000Z";

    const { data, error } = await this.client
      .from(this.tableName)
      .select("id,user_id,device_id,entity,entity_id,mutation_type,payload,updated_at,created_at")
      .eq("user_id", this.userId)
      .gt("updated_at", lastPulledAt)
      .neq("device_id", this.deviceId)
      .order("updated_at", { ascending: true })
      .limit(this.pullLimit);

    if (error) throw new Error(`Supabase pull failed: ${error.message}`);

    const rows = ((data ?? []) as SyncMutationRow[]);
    const patches: SyncMutation[] = rows.map((row) => ({
      id: row.id,
      entity: row.entity as SyncMutation["entity"],
      entityId: row.entity_id,
      type: row.mutation_type,
      payload: row.payload,
      updatedAt: row.updated_at,
      deviceId: row.device_id ?? undefined,
      userId: row.user_id
    }));

    const nextCursor: SyncCursor = {
      lastPulledAt: rows.length > 0 ? rows[rows.length - 1].updated_at : lastPulledAt,
      lastMutationId: rows.length > 0 ? rows[rows.length - 1].id : cursor.lastMutationId
    };

    return { cursor: nextCursor, patches };
  }
}

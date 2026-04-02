import test from "node:test";
import assert from "node:assert/strict";
import { SupabaseSyncTransport } from "@expense-tracker/cloud-sync/supabaseTransport";

test("cloud-sync package wiring resolves supabase transport", () => {
  const transport = new SupabaseSyncTransport({
    supabaseUrl: "https://demo.supabase.co",
    anonKey: "anon-key",
  });

  assert.ok(transport);
});

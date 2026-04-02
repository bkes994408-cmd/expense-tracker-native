import type { QuickEntryDraft } from "../types/quickEntry";

async function invokeInTauri(command: string, payload: Record<string, unknown>) {
  const tauriCore = await import("@tauri-apps/api/core");
  return tauriCore.invoke<string>(command, payload);
}

function createLocalMockResult(entry: QuickEntryDraft): string {
  const key = "expense-tracker.quick-entry.drafts";
  const current = JSON.parse(globalThis.localStorage.getItem(key) ?? "[]") as QuickEntryDraft[];
  current.unshift(entry);
  globalThis.localStorage.setItem(key, JSON.stringify(current.slice(0, 50)));
  return `saved-local:${entry.title}:${entry.amount}:${entry.category}`;
}

export async function saveQuickEntry(entry: QuickEntryDraft): Promise<string> {
  const tauriFlag = (globalThis as { __TAURI__?: unknown }).__TAURI__;

  if (tauriFlag) {
    return invokeInTauri("save_quick_entry", {
      title: entry.title,
      amount: entry.amount,
      category: entry.category
    });
  }

  return createLocalMockResult(entry);
}

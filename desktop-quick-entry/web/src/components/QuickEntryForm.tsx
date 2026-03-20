import { useState } from "react";
import { validateDraft } from "../lib/validators";
import { saveQuickEntry } from "../lib/tauriBridge";
import type { QuickEntryDraft } from "../types/quickEntry";

const initialDraft: QuickEntryDraft = { title: "", amount: 0, category: "" };

export function QuickEntryForm() {
  const [draft, setDraft] = useState<QuickEntryDraft>(initialDraft);
  const [message, setMessage] = useState<string>("");
  const [submitting, setSubmitting] = useState(false);

  async function submit() {
    const error = validateDraft(draft);
    if (error) {
      setMessage(error);
      return;
    }

    try {
      setSubmitting(true);
      const result = await saveQuickEntry(draft);
      setMessage(`已建立快速帳目：${draft.title} (${draft.amount})｜${result}`);
      setDraft(initialDraft);
    } catch (error) {
      setMessage(`新增失敗：${error instanceof Error ? error.message : "未知錯誤"}`);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section style={{ display: "grid", gap: 8, width: 360 }}>
      <input
        placeholder="標題"
        value={draft.title}
        onChange={(e) => setDraft({ ...draft, title: e.target.value })}
        disabled={submitting}
      />
      <input
        placeholder="分類"
        value={draft.category}
        onChange={(e) => setDraft({ ...draft, category: e.target.value })}
        disabled={submitting}
      />
      <input
        placeholder="金額"
        type="number"
        value={draft.amount || ""}
        onChange={(e) => setDraft({ ...draft, amount: Number(e.target.value) })}
        disabled={submitting}
      />
      <button onClick={submit} disabled={submitting}>{submitting ? "儲存中..." : "快速新增"}</button>
      {message && <p>{message}</p>}
    </section>
  );
}

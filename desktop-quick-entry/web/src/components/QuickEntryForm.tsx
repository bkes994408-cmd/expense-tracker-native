import { useState } from "react";
import { validateDraft } from "../lib/validators";
import type { QuickEntryDraft } from "../types/quickEntry";

export function QuickEntryForm() {
  const [draft, setDraft] = useState<QuickEntryDraft>({ title: "", amount: 0, category: "" });
  const [message, setMessage] = useState<string>("");

  function submit() {
    const error = validateDraft(draft);
    if (error) {
      setMessage(error);
      return;
    }

    setMessage(`已建立快速帳目：${draft.title} (${draft.amount})`);
  }

  return (
    <section style={{ display: "grid", gap: 8, width: 360 }}>
      <input placeholder="標題" value={draft.title} onChange={(e) => setDraft({ ...draft, title: e.target.value })} />
      <input placeholder="分類" value={draft.category} onChange={(e) => setDraft({ ...draft, category: e.target.value })} />
      <input
        placeholder="金額"
        type="number"
        value={draft.amount}
        onChange={(e) => setDraft({ ...draft, amount: Number(e.target.value) })}
      />
      <button onClick={submit}>快速新增</button>
      {message && <p>{message}</p>}
    </section>
  );
}

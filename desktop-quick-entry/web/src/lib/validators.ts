import type { QuickEntryDraft } from "../types/quickEntry";

export function validateDraft(input: QuickEntryDraft): string | null {
  if (!input.title.trim()) return "標題不可空白";
  if (!input.category.trim()) return "分類不可空白";
  if (input.amount <= 0) return "金額需大於 0";
  return null;
}

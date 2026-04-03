import type { SyncMutation } from "@expense-tracker/cloud-sync";

export interface Category {
  id: string;
  name: string;
}

export interface Expense {
  id: string;
  title: string;
  categoryId: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
}

export interface SyncDomainState {
  categories: Category[];
  expenses: Expense[];
}

type CategoryPayload = { name: string };
type ExpensePayload = {
  title: string;
  categoryId: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
};

function upsertById<T extends { id: string }>(items: T[], value: T): T[] {
  const index = items.findIndex((item) => item.id === value.id);
  if (index < 0) return [...items, value];
  const next = items.slice();
  next[index] = value;
  return next;
}

export function applySyncMutation(state: SyncDomainState, mutation: SyncMutation): SyncDomainState {
  if (mutation.entityType === "category") {
    if (mutation.operation === "delete") {
      return {
        ...state,
        categories: state.categories.filter((category) => category.id !== mutation.entityId),
      };
    }

    const payload = mutation.payload as CategoryPayload;
    return {
      ...state,
      categories: upsertById(state.categories, {
        id: mutation.entityId,
        name: payload.name,
      }),
    };
  }

  if (mutation.entityType === "expense") {
    if (mutation.operation === "delete") {
      return {
        ...state,
        expenses: state.expenses.filter((expense) => expense.id !== mutation.entityId),
      };
    }

    const payload = mutation.payload as ExpensePayload;
    return {
      ...state,
      expenses: upsertById(state.expenses, {
        id: mutation.entityId,
        title: payload.title,
        categoryId: payload.categoryId,
        amount: payload.amount,
        type: payload.type,
        createdAt: payload.createdAt,
      }),
    };
  }

  return state;
}

export function applySyncMutations(state: SyncDomainState, mutations: SyncMutation[]): SyncDomainState {
  return mutations.reduce(applySyncMutation, state);
}

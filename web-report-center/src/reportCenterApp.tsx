import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  InMemorySyncStateStore,
  type SyncMutation,
  type SyncPullRequest,
  type SyncPushRequest,
  type SyncTransport,
} from "@expense-tracker/cloud-sync";
import { summarize, toCsv, type ExpenseRecord, type ReportFilter } from "./lib/report";
import { applySyncMutations, type SyncDomainState } from "./lib/syncDomain";
import { runSyncOnce } from "./lib/webSync";
import {
  createDebouncedRunner,
  deriveSyncStatus,
  summarizePendingQueue,
  toSyncStatusLabel,
} from "./lib/syncUx";

const deviceId = "web-report-center";

class DemoSyncTransport implements SyncTransport {
  private readonly mutations: SyncMutation[];

  constructor(seed: SyncMutation[]) {
    this.mutations = [...seed];
  }

  async pushMutations(request: SyncPushRequest) {
    for (const mutation of request.mutations) {
      if (!this.mutations.some((item) => item.id === mutation.id)) {
        this.mutations.push(mutation);
      }
    }

    return {
      acceptedIds: request.mutations.map((item) => item.id),
      nextCursor: request.baseCursor ?? "0",
    };
  }

  async pullMutations(request: SyncPullRequest) {
    const start = Number(request.fromCursor ?? "0");
    const from = Number.isNaN(start) ? 0 : start;
    return {
      mutations: this.mutations.slice(from),
      nextCursor: `${this.mutations.length}`,
    };
  }
}

const seedMutations: SyncMutation[] = [
  {
    id: "seed:cat-food",
    entityType: "category",
    entityId: "cat-food",
    operation: "create",
    payload: { name: "飲食" },
    clientTimestamp: "2026-04-01T09:00:00.000Z",
    version: 1,
  },
  {
    id: "seed:cat-home",
    entityType: "category",
    entityId: "cat-home",
    operation: "create",
    payload: { name: "居住" },
    clientTimestamp: "2026-04-01T09:00:05.000Z",
    version: 1,
  },
  {
    id: "seed:exp-rent",
    entityType: "expense",
    entityId: "exp-rent",
    operation: "create",
    payload: {
      title: "房租",
      categoryId: "cat-home",
      amount: 21000,
      type: "expense",
      createdAt: "2026-04-01",
    },
    clientTimestamp: "2026-04-01T09:00:08.000Z",
    version: 1,
  },
  {
    id: "seed:exp-dinner",
    entityType: "expense",
    entityId: "exp-dinner",
    operation: "create",
    payload: {
      title: "晚餐",
      categoryId: "cat-food",
      amount: 280,
      type: "expense",
      createdAt: "2026-04-01",
    },
    clientTimestamp: "2026-04-01T09:00:10.000Z",
    version: 1,
  },
];

const initialState: SyncDomainState = { categories: [], expenses: [] };

export function ReportCenterApp() {
  const [isPro, setIsPro] = useState(false);
  const [filter, setFilter] = useState<ReportFilter>("all");
  const [dataState, setDataState] = useState<SyncDomainState>(initialState);
  const [pendingCount, setPendingCount] = useState(0);
  const [pendingSummaryText, setPendingSummaryText] = useState("佇列為空");
  const [lastSyncedAt, setLastSyncedAt] = useState<string | null>(null);
  const [lastError, setLastError] = useState<string | null>(null);
  const [remoteMergeNotice, setRemoteMergeNotice] = useState<string | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);

  const syncDeps = useMemo(() => {
    const store = new InMemorySyncStateStore();
    const transport = new DemoSyncTransport(seedMutations);
    return { store, transport };
  }, []);

  const records: ExpenseRecord[] = useMemo(() => {
    const categoryMap = new Map(dataState.categories.map((item) => [item.id, item.name]));
    return dataState.expenses.map((expense) => ({
      id: expense.id,
      title: expense.title,
      category: categoryMap.get(expense.categoryId) ?? "未分類",
      amount: expense.amount,
      type: expense.type,
      createdAt: expense.createdAt,
    }));
  }, [dataState]);

  const summary = useMemo(() => summarize(records, filter), [records, filter]);

  const refreshPendingCount = useCallback(async () => {
    const pending = await syncDeps.store.listPendingMutations(deviceId);
    setPendingCount(pending.length);

    const summary = summarizePendingQueue(pending);
    if (summary.total === 0) {
      setPendingSummaryText("佇列為空");
      return;
    }

    setPendingSummaryText(
      `總計 ${summary.total} 筆（expense ${summary.byEntityType.expense ?? 0} / category ${summary.byEntityType.category ?? 0}），最早 ${summary.oldestClientTimestamp ?? "-"}`,
    );
  }, [syncDeps.store]);

  const syncNow = useCallback(async () => {
    setIsSyncing(true);
    setLastError(null);

    try {
      const pendingBefore = await syncDeps.store.listPendingMutations(deviceId);
      const result = await runSyncOnce(deviceId, syncDeps.store, syncDeps.transport);
      const pushedMutations = pendingBefore.filter((mutation) => result.pushedMutationIds.includes(mutation.id));

      setDataState((prev) => applySyncMutations(applySyncMutations(prev, pushedMutations), result.pulledMutations));
      setLastSyncedAt(result.cursor.lastSyncedAt);
      if (result.pulledMutations.length > 0) {
        setRemoteMergeNotice(`已合併 ${result.pulledMutations.length} 筆遠端更新`);
      }
      await refreshPendingCount();
    } catch (error) {
      setLastError(error instanceof Error ? error.message : "同步失敗");
    } finally {
      setIsSyncing(false);
    }
  }, [refreshPendingCount, syncDeps.store, syncDeps.transport]);

  const debounceSyncRef = useRef(createDebouncedRunner(() => {
    void syncNow();
  }, 900));

  async function stageLocalMutation() {
    try {
      const localId = `local-${Date.now()}`;
      const mutation: SyncMutation = {
        id: `${deviceId}:${localId}`,
        entityType: "expense",
        entityId: localId,
        operation: "create",
        payload: {
          title: "本地待同步支出",
          categoryId: "cat-food",
          amount: 120,
          type: "expense",
          createdAt: new Date().toISOString().slice(0, 10),
        },
        clientTimestamp: new Date().toISOString(),
        version: 1,
      };

      await syncDeps.store.enqueueMutation(mutation);
      await refreshPendingCount();
      debounceSyncRef.current.schedule();
    } catch (error) {
      setLastError(error instanceof Error ? error.message : "加入待同步資料失敗");
    }
  }

  useEffect(() => {
    void refreshPendingCount();
    void syncNow();
  }, [refreshPendingCount, syncNow]);

  useEffect(() => {
    function onFocus() {
      void syncNow();
    }

    window.addEventListener("focus", onFocus);
    return () => {
      window.removeEventListener("focus", onFocus);
      debounceSyncRef.current.cancel();
    };
  }, [syncNow]);

  useEffect(() => {
    if (!remoteMergeNotice) return;
    const timer = setTimeout(() => setRemoteMergeNotice(null), 3000);
    return () => clearTimeout(timer);
  }, [remoteMergeNotice]);

  function downloadCsv() {
    const blob = new Blob([toCsv(records)], { type: "text/csv;charset=utf-8" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = "report-center-export.csv";
    link.click();
    URL.revokeObjectURL(link.href);
  }

  const syncStatus = deriveSyncStatus({ isSyncing, pendingCount, lastError });

  return (
    <main className="container">
      <h1>Web 報表中心</h1>
      <p>Phase 3：Web 同步狀態與資料接線（MVP）</p>

      <section className="card">
        <h2>同步狀態</h2>
        <div className="sync-status-bar">
          <span className={`sync-badge sync-badge-${syncStatus}`}>{toSyncStatusLabel(syncStatus)}</span>
          <span>最後同步時間：{lastSyncedAt ?? "尚未同步"}</span>
          <span>Pending mutations：{pendingCount}</span>
        </div>
        <p className="pending-summary">Queue 摘要：{pendingSummaryText}</p>
        {lastError ? (
          <div className="sync-error-box">
            <p>同步錯誤：{lastError}</p>
            <button onClick={syncNow} disabled={isSyncing}>重試</button>
          </div>
        ) : null}
        {remoteMergeNotice ? <p className="merge-notice">{remoteMergeNotice}</p> : null}
        <div className="row">
          <button onClick={syncNow} disabled={isSyncing}>{isSyncing ? "同步中..." : "手動同步"}</button>
          <button onClick={stageLocalMutation}>新增本地待同步資料</button>
        </div>
      </section>

      <div className="row">
        <label>
          <input type="checkbox" checked={isPro} onChange={(e) => setIsPro(e.target.checked)} /> Pro 用戶
        </label>
        <select value={filter} onChange={(e) => setFilter(e.target.value as ReportFilter)}>
          <option value="all">全部</option>
          <option value="income">僅收入</option>
          <option value="expense">僅支出</option>
          <option value="net">僅淨額</option>
        </select>
        <button onClick={downloadCsv}>匯出 CSV</button>
      </div>

      <section className="card">
        <h2>月總覽（來自同步資料）</h2>
        <ul>
          <li>收入：{summary.income}</li>
          <li>支出：{summary.expense}</li>
          <li>淨額：{summary.net}</li>
          <li>筆數：{summary.count}</li>
        </ul>
      </section>

      <section className="card">
        <h2>Categories（{dataState.categories.length}）</h2>
        <ul>
          {dataState.categories.map((category) => (
            <li key={category.id}>{category.name}</li>
          ))}
        </ul>
      </section>

      <section className="card">
        <h2>Expenses（{dataState.expenses.length}）</h2>
        <ul>
          {records.map((record) => (
            <li key={record.id}>
              {record.createdAt}｜{record.title}｜{record.category}｜{record.type}｜{record.amount}
            </li>
          ))}
        </ul>
      </section>

      <section className="card">
        <h2>進階報表（Pro）</h2>
        {isPro ? <p>✅ 已開通：可顯示趨勢圖、分類比較與 PDF 匯出入口。</p> : <p>🔒 Free 方案僅開放月總覽，升級 Pro 以查看進階分析。</p>}
      </section>
    </main>
  );
}

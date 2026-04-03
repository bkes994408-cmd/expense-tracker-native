import Foundation

protocol SyncStateStore {
    func enqueue(_ mutation: SyncMutation)
    func drainMutations() -> [SyncMutation]
    func peekMutations() -> [SyncMutation]

    func getCursor() -> SyncCursor
    func setCursor(_ cursor: SyncCursor)
}

final class InMemorySyncStateStore: SyncStateStore {
    private var queue: [SyncMutation] = []
    private var cursor: SyncCursor = .empty

    func enqueue(_ mutation: SyncMutation) {
        queue.append(mutation)
    }

    func drainMutations() -> [SyncMutation] {
        defer { queue.removeAll() }
        return queue
    }

    func peekMutations() -> [SyncMutation] {
        queue
    }

    func getCursor() -> SyncCursor {
        cursor
    }

    func setCursor(_ cursor: SyncCursor) {
        self.cursor = cursor
    }
}

final class SyncingExpenseStore: ExpenseStore {
    private let base: ExpenseStore
    private let syncStateStore: SyncStateStore
    private let encoder = JSONEncoder()

    init(base: ExpenseStore, syncStateStore: SyncStateStore) {
        self.base = base
        self.syncStateStore = syncStateStore
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchAll(searchText: String?) throws -> [Expense] { try base.fetchAll(searchText: searchText) }

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {
        try base.add(title: title, amount: amount, categoryId: categoryId, createdAt: createdAt)
        guard let inserted = try base.fetchAll(searchText: nil).first(where: {
            $0.title == title && $0.amount == amount && $0.categoryId == categoryId && abs($0.createdAt.timeIntervalSince(createdAt)) < 0.001
        }) else { return }
        try enqueue(type: .create, payload: ExpenseSyncPayload(id: inserted.id, title: inserted.title, amount: inserted.amount, createdAt: inserted.createdAt, categoryId: inserted.categoryId), entityId: inserted.id)
    }

    func delete(id: Int64) throws {
        try base.delete(id: id)
        try enqueue(type: .delete, payload: ExpenseSyncPayload(id: id, title: "", amount: 0, createdAt: .distantPast, categoryId: nil), entityId: id)
    }

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview { try base.fetchMonthlyOverview(for: month) }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {
        try base.update(id: id, title: title, amount: amount, categoryId: categoryId)
        try enqueue(type: .update, payload: ExpenseSyncPayload(id: id, title: title, amount: amount, createdAt: Date(), categoryId: categoryId), entityId: id)
    }

    private func enqueue<T: Encodable>(type: SyncMutationType, payload: T, entityId: Int64) throws {
        let json = try encoder.encode(payload)
        guard let payloadString = String(data: json, encoding: .utf8) else { return }
        syncStateStore.enqueue(SyncMutation(entity: "expense", entityId: String(entityId), type: type, payload: payloadString))
    }
}

final class SyncingCategoryStore: CategoryStore {
    private let base: CategoryStore
    private let syncStateStore: SyncStateStore
    private let encoder = JSONEncoder()

    init(base: CategoryStore, syncStateStore: SyncStateStore) {
        self.base = base
        self.syncStateStore = syncStateStore
    }

    func fetchActive() throws -> [Category] { try base.fetchActive() }

    func add(name: String) throws {
        try base.add(name: name)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let added = try base.fetchActive().last(where: { $0.name == trimmed }) else { return }
        try enqueue(type: .create, payload: CategorySyncPayload(id: added.id, name: added.name, isArchived: added.isArchived, sortOrder: added.sortOrder), entityId: added.id)
    }

    func archive(id: Int64) throws {
        try base.archive(id: id)
        try enqueue(type: .delete, payload: CategorySyncPayload(id: id, name: "", isArchived: true, sortOrder: -1), entityId: id)
    }

    func move(from: Int, to: Int) throws {
        try base.move(from: from, to: to)
        let json = try encoder.encode(CategoryReorderSyncPayload(from: from, to: to))
        guard let payload = String(data: json, encoding: .utf8) else { return }
        syncStateStore.enqueue(SyncMutation(entity: "category", entityId: "reorder", type: .update, payload: payload))
    }

    private func enqueue<T: Encodable>(type: SyncMutationType, payload: T, entityId: Int64) throws {
        let json = try encoder.encode(payload)
        guard let payloadString = String(data: json, encoding: .utf8) else { return }
        syncStateStore.enqueue(SyncMutation(entity: "category", entityId: String(entityId), type: type, payload: payloadString))
    }
}

final class IOSRepositorySyncBridge {
    private let expenseStore: ExpenseStore
    private let categoryStore: CategoryStore
    private let syncStateStore: SyncStateStore
    private let puller: CloudSyncPulling
    private let decoder = JSONDecoder()

    init(expenseStore: ExpenseStore, categoryStore: CategoryStore, syncStateStore: SyncStateStore, puller: CloudSyncPulling) {
        self.expenseStore = expenseStore
        self.categoryStore = categoryStore
        self.syncStateStore = syncStateStore
        self.puller = puller
        decoder.dateDecodingStrategy = .iso8601
    }

    func pullAndApplyOnce() {
        guard let result = try? puller.pull(cursor: syncStateStore.getCursor()) else { return }
        result.mutations.forEach(apply)
        syncStateStore.setCursor(result.cursor)
    }

    private func apply(_ mutation: SyncMutation) {
        switch mutation.entity {
        case "expense": applyExpenseMutation(mutation)
        case "category": applyCategoryMutation(mutation)
        default: break
        }
    }

    private func applyExpenseMutation(_ mutation: SyncMutation) {
        guard let data = mutation.payload.data(using: .utf8), let payload = try? decoder.decode(ExpenseSyncPayload.self, from: data) else { return }
        switch mutation.type {
        case .create: try? expenseStore.add(title: payload.title, amount: payload.amount, categoryId: payload.categoryId, createdAt: payload.createdAt)
        case .update: try? expenseStore.update(id: payload.id, title: payload.title, amount: payload.amount, categoryId: payload.categoryId)
        case .delete: try? expenseStore.delete(id: payload.id)
        }
    }

    private func applyCategoryMutation(_ mutation: SyncMutation) {
        guard let data = mutation.payload.data(using: .utf8) else { return }
        switch mutation.type {
        case .create:
            guard let payload = try? decoder.decode(CategorySyncPayload.self, from: data) else { return }
            try? categoryStore.add(name: payload.name)
        case .update:
            guard let payload = try? decoder.decode(CategoryReorderSyncPayload.self, from: data) else { return }
            try? categoryStore.move(from: payload.from, to: payload.to)
        case .delete:
            guard let payload = try? decoder.decode(CategorySyncPayload.self, from: data) else { return }
            try? categoryStore.archive(id: payload.id)
        }
    }
}

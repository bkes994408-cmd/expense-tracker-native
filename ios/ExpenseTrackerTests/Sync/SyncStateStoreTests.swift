import XCTest
@testable import ExpenseTracker

final class SyncStateStoreTests: XCTestCase {
    func testEnqueueDrainAndCursorUpdate() {
        let store = InMemorySyncStateStore()
        let mutation = SyncMutation(entity: "expense", entityId: "1", type: .create, payload: "{\"title\":\"coffee\"}")

        store.enqueue(mutation)

        XCTAssertEqual(store.peekMutations().count, 1)

        let drained = store.drainMutations()
        XCTAssertEqual(drained, [mutation])
        XCTAssertTrue(store.peekMutations().isEmpty)

        let cursor = SyncCursor(lastPulledAt: Date(timeIntervalSince1970: 100), lastMutationID: mutation.id)
        store.setCursor(cursor)
        XCTAssertEqual(store.getCursor(), cursor)
    }

    func testSyncingExpenseStoreEnqueuesCreateUpdateDelete() throws {
        let syncStore = InMemorySyncStateStore()
        let base = FakeExpenseStoreForSync()
        let store = SyncingExpenseStore(base: base, syncStateStore: syncStore)

        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        try store.add(title: "Coffee", amount: -80, categoryId: nil, createdAt: createdAt)
        try store.update(id: 1, title: "Coffee Beans", amount: -120, categoryId: nil)
        try store.delete(id: 1)

        let queued = syncStore.peekMutations()
        XCTAssertEqual(queued.map(\.entity), ["expense", "expense", "expense"])
        XCTAssertEqual(queued.map(\.type), [.create, .update, .delete])
        XCTAssertEqual(queued.map(\.entityId), ["1", "1", "1"])
    }

    func testPullAndApplyOnceAppliesMutationsAndCursor() throws {
        let syncStore = InMemorySyncStateStore()
        let expenseStore = FakeExpenseStoreForSync()
        let categoryStore = FakeCategoryStoreForSync()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let pullResult = SyncPullResult(
            mutations: [
                SyncMutation(
                    entity: "category",
                    entityId: "1",
                    type: .create,
                    payload: String(data: try encoder.encode(CategorySyncPayload(id: 1, name: "Transport", isArchived: false, sortOrder: 0)), encoding: .utf8)!
                ),
                SyncMutation(
                    entity: "expense",
                    entityId: "1",
                    type: .create,
                    payload: String(data: try encoder.encode(ExpenseSyncPayload(id: 1, title: "Taxi", amount: -250, createdAt: Date(timeIntervalSince1970: 10), categoryId: nil)), encoding: .utf8)!
                )
            ],
            cursor: SyncCursor(lastPulledAt: Date(timeIntervalSince1970: 20), lastMutationID: nil)
        )

        let bridge = IOSRepositorySyncBridge(
            expenseStore: expenseStore,
            categoryStore: categoryStore,
            syncStateStore: syncStore,
            puller: FakeCloudSyncPuller(result: pullResult)
        )

        bridge.pullAndApplyOnce()

        XCTAssertEqual(try categoryStore.fetchActive().map(\.name), ["Transport"])
        XCTAssertEqual(try expenseStore.fetchAll(searchText: nil).map(\.title), ["Taxi"])
        XCTAssertEqual(syncStore.getCursor().lastPulledAt, Date(timeIntervalSince1970: 20))
    }
}

private final class FakeCloudSyncPuller: CloudSyncPulling {
    let result: SyncPullResult

    init(result: SyncPullResult) {
        self.result = result
    }

    func pull(cursor: SyncCursor) throws -> SyncPullResult {
        result
    }
}

private final class FakeExpenseStoreForSync: ExpenseStore {
    private var items: [Expense] = []

    func fetchAll(searchText: String?) throws -> [Expense] { items }

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {
        let nextID = (items.map(\.id).max() ?? 0) + 1
        items.append(Expense(id: nextID, title: title, amount: amount, createdAt: createdAt, categoryId: categoryId))
    }

    func delete(id: Int64) throws {
        items.removeAll { $0.id == id }
    }

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        .empty(month: month)
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx] = Expense(id: id, title: title, amount: amount, createdAt: items[idx].createdAt, categoryId: categoryId)
    }
}

private final class FakeCategoryStoreForSync: CategoryStore {
    private var items: [ExpenseTracker.Category] = []

    func fetchActive() throws -> [ExpenseTracker.Category] {
        items.filter { !$0.isArchived }
    }

    func add(name: String) throws {
        let nextID = (items.map(\.id).max() ?? 0) + 1
        let nextSortOrder = (items.map(\.sortOrder).max() ?? -1) + 1
        items.append(ExpenseTracker.Category(id: nextID, name: name, isArchived: false, sortOrder: nextSortOrder))
    }

    func archive(id: Int64) throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx] = ExpenseTracker.Category(id: id, name: items[idx].name, isArchived: true, sortOrder: items[idx].sortOrder)
    }

    func move(from: Int, to: Int) throws {
        guard from != to,
              from >= 0, from < items.count,
              to >= 0, to < items.count
        else { return }
        let moved = items.remove(at: from)
        items.insert(moved, at: to)
    }
}

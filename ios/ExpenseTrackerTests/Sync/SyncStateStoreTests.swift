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
}

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

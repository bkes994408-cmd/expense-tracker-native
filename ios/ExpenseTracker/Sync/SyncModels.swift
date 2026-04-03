import Foundation

enum SyncMutationType: String, Codable {
    case create
    case update
    case delete
}

struct SyncMutation: Identifiable, Equatable, Codable {
    let id: UUID
    let entity: String
    let entityId: String
    let type: SyncMutationType
    let payload: String
    let updatedAt: Date

    init(id: UUID = UUID(), entity: String, entityId: String, type: SyncMutationType, payload: String, updatedAt: Date = Date()) {
        self.id = id
        self.entity = entity
        self.entityId = entityId
        self.type = type
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

struct SyncCursor: Equatable, Codable {
    var lastPulledAt: Date?
    var lastMutationID: UUID?

    static let empty = SyncCursor(lastPulledAt: nil, lastMutationID: nil)
}

struct ExpenseSyncPayload: Codable {
    let id: Int64
    let title: String
    let amount: Decimal
    let createdAt: Date
    let categoryId: Int64?
}

struct CategorySyncPayload: Codable {
    let id: Int64
    let name: String
    let isArchived: Bool
    let sortOrder: Int
}

struct CategoryReorderSyncPayload: Codable {
    let from: Int
    let to: Int
}

struct SyncPullResult: Codable {
    let mutations: [SyncMutation]
    let cursor: SyncCursor

    static let empty = SyncPullResult(mutations: [], cursor: .empty)
}

protocol CloudSyncPulling {
    func pull(cursor: SyncCursor) throws -> SyncPullResult
}

final class NoopCloudSyncPuller: CloudSyncPulling {
    func pull(cursor: SyncCursor) throws -> SyncPullResult {
        SyncPullResult(mutations: [], cursor: cursor)
    }
}

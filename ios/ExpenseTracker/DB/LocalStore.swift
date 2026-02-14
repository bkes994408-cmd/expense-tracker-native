import Foundation
import GRDB

/// GRDB-backed local persistence (SQLite).
///
/// Why GRDB (vs CoreData):
/// - Lightweight SQLite wrapper, deterministic migrations, easy to unit test.
/// - Good fit for a simple offline-first MVP with a single table.
final class LocalStore: TransactionRepository {

    private let dbQueue: DatabaseQueue

    init() throws {
        let fm = FileManager.default
        let dir = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbURL = dir.appendingPathComponent("expense_tracker.sqlite")
        self.dbQueue = try DatabaseQueue(path: dbURL.path)
        try bootstrapIfNeeded()
    }

    private func bootstrapIfNeeded() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createTransactions") { db in
            try db.create(table: "transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("amountCents", .integer).notNull()
                t.column("note", .text).notNull().defaults(to: "")
                t.column("occurredAt", .datetime).notNull()
            }
        }
        try migrator.migrate(dbQueue)
    }

    // MARK: - TransactionRepository

    func list() throws -> [Transaction] {
        try dbQueue.read { db in
            try TransactionRecord
                .order(Column("occurredAt").desc, Column("id").desc)
                .fetchAll(db)
                .map { $0.asDomain() }
        }
    }

    func add(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64 {
        try dbQueue.write { db in
            var record = TransactionRecord(
                id: nil,
                amountCents: amountCents,
                note: note,
                occurredAt: occurredAt
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    func delete(id: Int64) throws {
        try dbQueue.write { db in
            _ = try TransactionRecord.deleteOne(db, key: id)
        }
    }
}

// MARK: - GRDB Record

private struct TransactionRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "transactions"

    var id: Int64?
    var amountCents: Int64
    var note: String
    var occurredAt: Date

    func asDomain() -> Transaction {
        Transaction(
            id: id ?? 0,
            amountCents: amountCents,
            note: note,
            occurredAt: occurredAt
        )
    }
}

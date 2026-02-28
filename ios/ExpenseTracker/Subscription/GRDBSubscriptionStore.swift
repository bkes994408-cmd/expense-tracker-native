import Foundation
import GRDB

final class GRDBSubscriptionStore: SubscriptionStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetchAll() throws -> [SubscriptionPlan] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, name, amount, cycleDays, nextChargeAt, reminderDaysBefore, reminderEnabled
                FROM subscriptions
                ORDER BY nextChargeAt ASC, id ASC
            """)
            return rows.map { row in
                SubscriptionPlan(
                    id: row["id"],
                    name: row["name"],
                    amount: Decimal(string: row["amount"] as String) ?? 0,
                    cycleDays: row["cycleDays"],
                    nextChargeAt: Date(timeIntervalSince1970: row["nextChargeAt"]),
                    reminderDaysBefore: row["reminderDaysBefore"],
                    reminderEnabled: (row["reminderEnabled"] as Int64) == 1
                )
            }
        }
    }

    func add(name: String, amount: Decimal, cycleDays: Int, nextChargeAt: Date, reminderDaysBefore: Int, reminderEnabled: Bool) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0, cycleDays > 0 else { return }

        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO subscriptions (name, amount, cycleDays, nextChargeAt, reminderDaysBefore, reminderEnabled) VALUES (?, ?, ?, ?, ?, ?)",
                arguments: [trimmed, NSDecimalNumber(decimal: amount).stringValue, cycleDays, nextChargeAt.timeIntervalSince1970, reminderDaysBefore, reminderEnabled ? 1 : 0]
            )
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createSubscriptions") { db in
            try db.create(table: "subscriptions") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("amount", .text).notNull()
                table.column("cycleDays", .integer).notNull()
                table.column("nextChargeAt", .double).notNull()
                table.column("reminderDaysBefore", .integer).notNull().defaults(to: 1)
                table.column("reminderEnabled", .integer).notNull().defaults(to: 1)
            }
        }
        return migrator
    }
}

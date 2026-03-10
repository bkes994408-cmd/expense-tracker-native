import Foundation
import GRDB

final class GRDBBudgetStore: BudgetStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetch(monthKey: String) throws -> [BudgetPlan] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, monthKey, categoryName, amount, carryOverMode
                FROM budgets
                WHERE monthKey = ?
                ORDER BY categoryName ASC
            """, arguments: [monthKey])

            return rows.map { row in
                BudgetPlan(
                    id: row["id"],
                    monthKey: row["monthKey"],
                    categoryName: row["categoryName"],
                    amount: Decimal(string: row["amount"]) ?? 0,
                    carryOverMode: CarryOverMode(rawValue: row["carryOverMode"]) ?? .none
                )
            }
        }
    }

    func upsert(monthKey: String, categoryName: String, amount: Decimal, carryOverMode: CarryOverMode) throws {
        try dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO budgets (monthKey, categoryName, amount, carryOverMode, updatedAt)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(monthKey, categoryName) DO UPDATE SET
                    amount = excluded.amount,
                    carryOverMode = excluded.carryOverMode,
                    updatedAt = excluded.updatedAt
            """, arguments: [monthKey, categoryName, NSDecimalNumber(decimal: amount).stringValue, carryOverMode.rawValue, Date().timeIntervalSince1970])
        }
    }

    func delete(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM budgets WHERE id = ?", arguments: [id])
        }
    }

    func copy(from fromMonthKey: String, to toMonthKey: String) throws {
        guard fromMonthKey != toMonthKey else { return }
        try dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO budgets (monthKey, categoryName, amount, carryOverMode, updatedAt)
                SELECT ?, categoryName, amount, carryOverMode, ?
                FROM budgets
                WHERE monthKey = ?
                ON CONFLICT(monthKey, categoryName) DO UPDATE SET
                    amount = excluded.amount,
                    carryOverMode = excluded.carryOverMode,
                    updatedAt = excluded.updatedAt
            """, arguments: [toMonthKey, Date().timeIntervalSince1970, fromMonthKey])
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createBudgets") { db in
            try db.create(table: "budgets", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("monthKey", .text).notNull()
                t.column("categoryName", .text).notNull()
                t.column("amount", .text).notNull()
                t.column("carryOverMode", .text).notNull().defaults(to: CarryOverMode.none.rawValue)
                t.column("updatedAt", .double).notNull()
                t.uniqueKey(["monthKey", "categoryName"])
            }
        }
        return migrator
    }
}

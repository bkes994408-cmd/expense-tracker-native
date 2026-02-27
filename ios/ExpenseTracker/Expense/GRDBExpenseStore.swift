import Foundation
import GRDB

final class GRDBExpenseStore: ExpenseStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetchAll(searchText: String?) throws -> [Expense] {
        let keyword = searchText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return try dbQueue.read { db in
            let rows: [Row]
            if keyword.isEmpty {
                rows = try Row.fetchAll(db, sql: """
                    SELECT id, title, amount, createdAt, categoryId
                    FROM expenses
                    ORDER BY createdAt DESC, id DESC
                """)
            } else {
                rows = try Row.fetchAll(db, sql: """
                    SELECT id, title, amount, createdAt, categoryId
                    FROM expenses
                    WHERE title LIKE '%' || ? || '%'
                    ORDER BY createdAt DESC, id DESC
                """, arguments: [keyword])
            }

            return rows.map {
                let amountString: String = $0["amount"]
                return Expense(
                    id: $0["id"],
                    title: $0["title"],
                    amount: Decimal(string: amountString) ?? 0,
                    createdAt: Date(timeIntervalSince1970: $0["createdAt"]),
                    categoryId: $0["categoryId"]
                )
            }
        }
    }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO expenses (title, amount, createdAt, categoryId) VALUES (?, ?, ?, ?)",
                arguments: [trimmed, NSDecimalNumber(decimal: amount).stringValue, Date().timeIntervalSince1970, categoryId]
            )
        }
    }

    func delete(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM expenses WHERE id = ?", arguments: [id])
        }
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {
        // TODO(MVP-1.2): wire edit flow in UI.
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE expenses SET title = ?, amount = ?, categoryId = ? WHERE id = ?",
                arguments: [title, NSDecimalNumber(decimal: amount).stringValue, categoryId, id]
            )
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createExpenses") { db in
            try db.create(table: "expenses") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("title", .text).notNull()
                table.column("amount", .text).notNull()
                table.column("createdAt", .double).notNull()
                table.column("categoryId", .integer)
            }
        }
        return migrator
    }
}

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

            return rows.map(Self.mapExpense)
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

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

        return try dbQueue.read { db in
            let uncategorized = String(localized: "common.uncategorized")
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    COALESCE(c.name, ?) AS categoryName,
                    SUM(CAST(e.amount AS REAL)) AS totalAmount
                FROM expenses e
                LEFT JOIN categories c ON c.id = e.categoryId
                WHERE e.createdAt >= ? AND e.createdAt < ?
                GROUP BY COALESCE(c.name, ?)
                ORDER BY totalAmount ASC
            """, arguments: [uncategorized, monthStart.timeIntervalSince1970, monthEnd.timeIntervalSince1970, uncategorized])

            var income: Decimal = 0
            var expense: Decimal = 0
            let categories: [MonthlyOverview.CategoryTotal] = rows.compactMap { row in
                let name: String = row["categoryName"]
                let amountDouble: Double = row["totalAmount"]
                let amount = Decimal(amountDouble)
                if amount >= 0 {
                    income += amount
                } else {
                    expense += -amount
                }
                return MonthlyOverview.CategoryTotal(id: name, name: name, amount: amount)
            }

            return MonthlyOverview(month: monthStart, income: income, expense: expense, categoryTotals: categories)
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

    private static func mapExpense(_ row: Row) -> Expense {
        let amountString: String = row["amount"]
        return Expense(
            id: row["id"],
            title: row["title"],
            amount: Decimal(string: amountString) ?? 0,
            createdAt: Date(timeIntervalSince1970: row["createdAt"]),
            categoryId: row["categoryId"]
        )
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

import Foundation
import GRDB

final class GRDBInstallmentStore: InstallmentStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetchAll() throws -> [InstallmentPlan] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, name, totalPeriods, paidPeriods, periodAmount
                FROM installments
                ORDER BY id DESC
            """)
            return rows.map { row in
                InstallmentPlan(
                    id: row["id"],
                    name: row["name"],
                    totalPeriods: row["totalPeriods"],
                    paidPeriods: row["paidPeriods"],
                    periodAmount: Decimal(string: row["periodAmount"] as String) ?? 0
                )
            }
        }
    }

    func add(name: String, periodAmount: Decimal, totalPeriods: Int, paidPeriods: Int) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, periodAmount > 0, totalPeriods > 0 else { return }
        let paid = min(max(paidPeriods, 0), totalPeriods)

        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO installments (name, totalPeriods, paidPeriods, periodAmount) VALUES (?, ?, ?, ?)",
                arguments: [trimmed, totalPeriods, paid, NSDecimalNumber(decimal: periodAmount).stringValue]
            )
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createInstallments") { db in
            try db.create(table: "installments") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("totalPeriods", .integer).notNull()
                table.column("paidPeriods", .integer).notNull().defaults(to: 0)
                table.column("periodAmount", .text).notNull()
            }
        }
        return migrator
    }
}

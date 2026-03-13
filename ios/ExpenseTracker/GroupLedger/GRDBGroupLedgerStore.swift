import Foundation
import GRDB

final class GRDBGroupLedgerStore: GroupLedgerStore {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrator.migrate(dbQueue)
    }

    func fetchLedgers() throws -> [GroupLedger] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, name, createdAt
                FROM group_ledgers
                ORDER BY createdAt DESC, id DESC
            """)
            return rows.map(Self.mapLedger)
        }
    }

    func createLedger(name: String) throws -> GroupLedger {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError.invalidInput
        }

        return try dbQueue.write { db in
            let createdAt = Date().timeIntervalSince1970
            try db.execute(
                sql: "INSERT INTO group_ledgers (name, createdAt) VALUES (?, ?)",
                arguments: [trimmed, createdAt]
            )
            let id = db.lastInsertedRowID
            return GroupLedger(id: id, name: trimmed, createdAt: Date(timeIntervalSince1970: createdAt))
        }
    }

    func fetchMembers(ledgerId: Int64) throws -> [LedgerMember] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, ledgerId, name, createdAt
                FROM group_members
                WHERE ledgerId = ?
                ORDER BY createdAt ASC, id ASC
            """, arguments: [ledgerId])
            return rows.map(Self.mapMember)
        }
    }

    func addMember(ledgerId: Int64, name: String) throws -> LedgerMember {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError.invalidInput
        }

        return try dbQueue.write { db in
            let createdAt = Date().timeIntervalSince1970
            try db.execute(
                sql: "INSERT INTO group_members (ledgerId, name, createdAt) VALUES (?, ?, ?)",
                arguments: [ledgerId, trimmed, createdAt]
            )
            let id = db.lastInsertedRowID
            return LedgerMember(id: id, ledgerId: ledgerId, name: trimmed, createdAt: Date(timeIntervalSince1970: createdAt))
        }
    }

    func addSharedExpense(
        ledgerId: Int64,
        title: String,
        amount: Decimal,
        paidByMemberId: Int64,
        splits: [(memberId: Int64, amount: Decimal)]
    ) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, amount > 0, !splits.isEmpty else {
            throw ValidationError.invalidInput
        }

        let totalSplit = splits.reduce(Decimal.zero) { $0 + $1.amount }
        guard totalSplit == amount else {
            throw ValidationError.invalidSplit
        }

        try dbQueue.write { db in
            let createdAt = Date().timeIntervalSince1970
            try db.execute(
                sql: """
                INSERT INTO shared_expenses (ledgerId, title, amount, paidByMemberId, createdAt)
                VALUES (?, ?, ?, ?, ?)
                """,
                arguments: [ledgerId, trimmed, NSDecimalNumber(decimal: amount).stringValue, paidByMemberId, createdAt]
            )
            let expenseId = db.lastInsertedRowID

            for split in splits {
                try db.execute(
                    sql: """
                    INSERT INTO shared_expense_splits (expenseId, memberId, amount)
                    VALUES (?, ?, ?)
                    """,
                    arguments: [expenseId, split.memberId, NSDecimalNumber(decimal: split.amount).stringValue]
                )
            }
        }
    }

    func fetchOverview(ledgerId: Int64) throws -> GroupLedgerOverview {
        try dbQueue.read { db in
            guard let ledgerRow = try Row.fetchOne(db, sql: "SELECT id, name, createdAt FROM group_ledgers WHERE id = ?", arguments: [ledgerId]) else {
                throw ValidationError.notFound
            }

            let ledger = Self.mapLedger(ledgerRow)
            let members = try fetchMembers(ledgerId: ledgerId)
            let expensesRows = try Row.fetchAll(db, sql: """
                SELECT id, ledgerId, title, amount, paidByMemberId, createdAt
                FROM shared_expenses
                WHERE ledgerId = ?
                ORDER BY createdAt DESC, id DESC
                LIMIT 50
            """, arguments: [ledgerId])

            let expenses = expensesRows.map(Self.mapExpense)
            let expenseIds = expenses.map(\.id)

            let splitRows: [Row]
            if expenseIds.isEmpty {
                splitRows = []
            } else {
                let placeholders = Array(repeating: "?", count: expenseIds.count).joined(separator: ",")
                splitRows = try Row.fetchAll(db, sql: """
                    SELECT expenseId, memberId, amount
                    FROM shared_expense_splits
                    WHERE expenseId IN (
                        \(placeholders)
                    )
                """, arguments: StatementArguments(expenseIds))
            }

            let splits = splitRows.map(Self.mapSplit)
            let paidMap = Dictionary(expenses.map { ($0.paidByMemberId, $0.amount) }, uniquingKeysWith: +)
            let owedMap = Dictionary(splits.map { ($0.memberId, $0.amount) }, uniquingKeysWith: +)

            let balances = members.map { member in
                LedgerBalance(
                    member: member,
                    paid: paidMap[member.id] ?? .zero,
                    owed: owedMap[member.id] ?? .zero
                )
            }

            return GroupLedgerOverview(ledger: ledger, members: members, recentExpenses: expenses, balances: balances)
        }
    }

    private static func mapLedger(_ row: Row) -> GroupLedger {
        GroupLedger(
            id: row["id"],
            name: row["name"],
            createdAt: Date(timeIntervalSince1970: row["createdAt"])
        )
    }

    private static func mapMember(_ row: Row) -> LedgerMember {
        LedgerMember(
            id: row["id"],
            ledgerId: row["ledgerId"],
            name: row["name"],
            createdAt: Date(timeIntervalSince1970: row["createdAt"])
        )
    }

    private static func mapExpense(_ row: Row) -> SharedExpense {
        let amountString: String = row["amount"]
        return SharedExpense(
            id: row["id"],
            ledgerId: row["ledgerId"],
            title: row["title"],
            amount: Decimal(string: amountString) ?? 0,
            paidByMemberId: row["paidByMemberId"],
            createdAt: Date(timeIntervalSince1970: row["createdAt"])
        )
    }

    private static func mapSplit(_ row: Row) -> SharedExpenseSplit {
        let amountString: String = row["amount"]
        return SharedExpenseSplit(
            expenseId: row["expenseId"],
            memberId: row["memberId"],
            amount: Decimal(string: amountString) ?? 0
        )
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createGroupLedgers") { db in
            try db.create(table: "group_ledgers", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("name", .text).notNull()
                table.column("createdAt", .double).notNull()
            }

            try db.create(table: "group_members", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("ledgerId", .integer).notNull().indexed().references("group_ledgers", onDelete: .cascade)
                table.column("name", .text).notNull()
                table.column("createdAt", .double).notNull()
            }

            try db.create(table: "shared_expenses", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("ledgerId", .integer).notNull().indexed().references("group_ledgers", onDelete: .cascade)
                table.column("title", .text).notNull()
                table.column("amount", .text).notNull()
                table.column("paidByMemberId", .integer).notNull().references("group_members", onDelete: .restrict)
                table.column("createdAt", .double).notNull()
            }

            try db.create(table: "shared_expense_splits", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("expenseId", .integer).notNull().indexed().references("shared_expenses", onDelete: .cascade)
                table.column("memberId", .integer).notNull().indexed().references("group_members", onDelete: .restrict)
                table.column("amount", .text).notNull()
            }
        }

        return migrator
    }
}

enum ValidationError: Error {
    case invalidInput
    case invalidSplit
    case notFound
}

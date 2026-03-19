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

    func upsertMonthlyBudget(ledgerId: Int64, month: Date, amount: Decimal) throws {
        guard amount >= 0 else {
            throw ValidationError.invalidInput
        }

        try dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO group_monthly_budgets (ledgerId, monthKey, amount)
                VALUES (?, ?, ?)
                ON CONFLICT(ledgerId, monthKey)
                DO UPDATE SET amount = excluded.amount
                """,
                arguments: [ledgerId, Self.monthKey(month), NSDecimalNumber(decimal: amount).stringValue]
            )
        }
    }

    func fetchOverview(ledgerId: Int64, month: Date) throws -> GroupLedgerOverview {
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

            let allSplitRows = try Row.fetchAll(db, sql: """
                SELECT s.expenseId, s.memberId, s.amount
                FROM shared_expense_splits s
                INNER JOIN shared_expenses e ON e.id = s.expenseId
                WHERE e.ledgerId = ?
            """, arguments: [ledgerId])
            let allSplits = allSplitRows.map(Self.mapSplit)

            let paidMap = Dictionary(expenses.map { ($0.paidByMemberId, $0.amount) }, uniquingKeysWith: +)
            let owedMap = Dictionary(allSplits.map { ($0.memberId, $0.amount) }, uniquingKeysWith: +)

            let balances = members.map { member in
                LedgerBalance(
                    member: member,
                    paid: paidMap[member.id] ?? .zero,
                    owed: owedMap[member.id] ?? .zero
                )
            }

            let settlements = Self.computeSettlements(balances: balances)

            let monthStart = Self.monthStart(month)
            let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: 0), to: monthStart) ?? monthStart
            let monthRows = try Row.fetchAll(db, sql: """
                SELECT id, ledgerId, title, amount, paidByMemberId, createdAt
                FROM shared_expenses
                WHERE ledgerId = ? AND createdAt >= ? AND createdAt < ?
                ORDER BY createdAt DESC, id DESC
            """, arguments: [ledgerId, monthStart.timeIntervalSince1970, monthEnd.timeIntervalSince1970])
            let monthExpenses = monthRows.map(Self.mapExpense)
            let monthTotal = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }

            let budgetRow = try Row.fetchOne(db, sql: """
                SELECT amount
                FROM group_monthly_budgets
                WHERE ledgerId = ? AND monthKey = ?
            """, arguments: [ledgerId, Self.monthKey(monthStart)])
            let budgetAmount = budgetRow.flatMap { row -> Decimal? in
                let amountString: String = row["amount"]
                return Decimal(string: amountString)
            } ?? .zero

            let payerMap = Dictionary(monthExpenses.map { ($0.paidByMemberId, $0.amount) }, uniquingKeysWith: +)
            let payerBreakdown = members.map { member in
                MemberAmountBreakdown(member: member, amount: payerMap[member.id] ?? .zero)
            }.filter { $0.amount > .zero }
            .sorted { $0.amount > $1.amount }

            let topExpenseTitle = monthExpenses.max(by: { $0.amount < $1.amount })?.title
            let expenseCount = monthExpenses.count

            let monthlyReport = GroupMonthlyReport(
                monthStart: monthStart,
                expenseCount: expenseCount,
                totalExpense: monthTotal,
                averageExpense: expenseCount == 0 ? .zero : monthTotal / Decimal(expenseCount),
                topExpenseTitle: topExpenseTitle,
                payerBreakdown: payerBreakdown
            )

            return GroupLedgerOverview(
                ledger: ledger,
                members: members,
                recentExpenses: expenses,
                balances: balances,
                settlements: settlements,
                budgetSnapshot: GroupBudgetSnapshot(monthStart: monthStart, budget: budgetAmount, spent: monthTotal),
                monthlyReport: monthlyReport
            )
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

    private static func monthStart(_ date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private static func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: monthStart(date))
    }

    private static func computeSettlements(balances: [LedgerBalance]) -> [SettlementTransfer] {
        var debtors = balances
            .filter { $0.net < .zero }
            .map { (member: $0.member, amount: -$0.net) }
            .sorted { $0.amount > $1.amount }

        var creditors = balances
            .filter { $0.net > .zero }
            .map { (member: $0.member, amount: $0.net) }
            .sorted { $0.amount > $1.amount }

        var debtorIndex = 0
        var creditorIndex = 0
        var result: [SettlementTransfer] = []

        while debtorIndex < debtors.count, creditorIndex < creditors.count {
            let transferAmount = min(debtors[debtorIndex].amount, creditors[creditorIndex].amount)
            if transferAmount > .zero {
                result.append(
                    SettlementTransfer(
                        fromMember: debtors[debtorIndex].member,
                        toMember: creditors[creditorIndex].member,
                        amount: transferAmount
                    )
                )
            }

            debtors[debtorIndex].amount -= transferAmount
            creditors[creditorIndex].amount -= transferAmount

            if debtors[debtorIndex].amount == .zero { debtorIndex += 1 }
            if creditors[creditorIndex].amount == .zero { creditorIndex += 1 }
        }

        return result
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

        migrator.registerMigration("createGroupMonthlyBudgets") { db in
            try db.create(table: "group_monthly_budgets", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("ledgerId", .integer).notNull().indexed().references("group_ledgers", onDelete: .cascade)
                table.column("monthKey", .text).notNull()
                table.column("amount", .text).notNull()
                table.uniqueKey(["ledgerId", "monthKey"])
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

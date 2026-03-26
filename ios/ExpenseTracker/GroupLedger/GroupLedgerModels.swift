import Foundation

struct GroupLedger: Identifiable, Equatable {
    let id: Int64
    let name: String
    let createdAt: Date
}

struct LedgerMember: Identifiable, Equatable {
    let id: Int64
    let ledgerId: Int64
    let name: String
    let createdAt: Date
}

struct SharedExpense: Identifiable, Equatable {
    let id: Int64
    let ledgerId: Int64
    let title: String
    let amount: Decimal
    let paidByMemberId: Int64
    let createdAt: Date
}

struct SharedExpenseSplit: Equatable {
    let expenseId: Int64
    let memberId: Int64
    let amount: Decimal
}

struct LedgerBalance: Identifiable, Equatable {
    var id: Int64 { member.id }
    let member: LedgerMember
    let paid: Decimal
    let owed: Decimal

    var net: Decimal { paid - owed }
}

struct SettlementTransfer: Identifiable, Equatable {
    var id: String { "\(fromMember.id)-\(toMember.id)-\(amount)" }
    let fromMember: LedgerMember
    let toMember: LedgerMember
    let amount: Decimal
}

struct GroupBudgetSnapshot: Equatable {
    let monthStart: Date
    let budget: Decimal
    let spent: Decimal

    var remaining: Decimal { budget - spent }
    var usageRatio: Decimal {
        guard budget > 0 else { return .zero }
        return spent / budget
    }
}

struct MemberAmountBreakdown: Identifiable, Equatable {
    var id: Int64 { member.id }
    let member: LedgerMember
    let amount: Decimal
}

struct GroupMonthlyReport: Equatable {
    let monthStart: Date
    let expenseCount: Int
    let totalExpense: Decimal
    let averageExpense: Decimal
    let topExpenseTitle: String?
    let payerBreakdown: [MemberAmountBreakdown]
}

struct GroupLedgerOverview: Equatable {
    let ledger: GroupLedger
    let members: [LedgerMember]
    let recentExpenses: [SharedExpense]
    let balances: [LedgerBalance]
    let settlements: [SettlementTransfer]
    let budgetSnapshot: GroupBudgetSnapshot
    let monthlyReport: GroupMonthlyReport

    static func empty(ledger: GroupLedger) -> GroupLedgerOverview {
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        return .init(
            ledger: ledger,
            members: [],
            recentExpenses: [],
            balances: [],
            settlements: [],
            budgetSnapshot: GroupBudgetSnapshot(monthStart: monthStart, budget: .zero, spent: .zero),
            monthlyReport: GroupMonthlyReport(monthStart: monthStart, expenseCount: 0, totalExpense: .zero, averageExpense: .zero, topExpenseTitle: nil, payerBreakdown: [])
        )
    }
}

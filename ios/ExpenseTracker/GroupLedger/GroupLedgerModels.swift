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

struct GroupLedgerOverview: Equatable {
    let ledger: GroupLedger
    let members: [LedgerMember]
    let recentExpenses: [SharedExpense]
    let balances: [LedgerBalance]

    static func empty(ledger: GroupLedger) -> GroupLedgerOverview {
        .init(ledger: ledger, members: [], recentExpenses: [], balances: [])
    }
}

import Foundation

protocol GroupLedgerStore {
    func fetchLedgers() throws -> [GroupLedger]
    func createLedger(name: String) throws -> GroupLedger

    func fetchMembers(ledgerId: Int64) throws -> [LedgerMember]
    func addMember(ledgerId: Int64, name: String) throws -> LedgerMember

    func addSharedExpense(
        ledgerId: Int64,
        title: String,
        amount: Decimal,
        paidByMemberId: Int64,
        splits: [(memberId: Int64, amount: Decimal)]
    ) throws

    func fetchOverview(ledgerId: Int64) throws -> GroupLedgerOverview
}

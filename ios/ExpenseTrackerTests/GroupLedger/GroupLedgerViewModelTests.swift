import XCTest
@testable import ExpenseTracker

@MainActor
final class GroupLedgerViewModelTests: XCTestCase {
    func testCreateLedgerAndAddMembersAndSharedExpense() {
        let store = FakeGroupLedgerStore()
        let vm = GroupLedgerViewModel(store: store)

        vm.newLedgerName = "家庭帳本"
        vm.createLedger()

        XCTAssertEqual(vm.ledgers.count, 1)
        XCTAssertEqual(vm.ledgers.first?.name, "家庭帳本")

        vm.newMemberName = "Bruce"
        vm.addMember()
        vm.newMemberName = "Alex"
        vm.addMember()

        XCTAssertEqual(vm.overview?.members.count, 2)

        vm.expenseTitle = "晚餐"
        vm.expenseAmount = "600"
        vm.selectedPayerId = vm.overview?.members.first?.id
        vm.addSharedExpense()

        guard let balances = vm.overview?.balances else {
            XCTFail("Expected balances")
            return
        }

        XCTAssertEqual(balances.count, 2)
        XCTAssertEqual(balances.first(where: { $0.member.name == "Bruce" })?.net, 300)
        XCTAssertEqual(balances.first(where: { $0.member.name == "Alex" })?.net, -300)
    }
}

private final class FakeGroupLedgerStore: GroupLedgerStore {
    private var ledgers: [GroupLedger] = []
    private var members: [Int64: [LedgerMember]] = [:]
    private var expenses: [Int64: [SharedExpense]] = [:]
    private var splitsByExpenseId: [Int64: [SharedExpenseSplit]] = [:]

    private var nextLedgerId: Int64 = 1
    private var nextMemberId: Int64 = 1
    private var nextExpenseId: Int64 = 1

    func fetchLedgers() throws -> [GroupLedger] { ledgers }

    func createLedger(name: String) throws -> GroupLedger {
        let ledger = GroupLedger(id: nextLedgerId, name: name, createdAt: Date())
        nextLedgerId += 1
        ledgers.append(ledger)
        members[ledger.id] = []
        return ledger
    }

    func fetchMembers(ledgerId: Int64) throws -> [LedgerMember] {
        members[ledgerId] ?? []
    }

    func addMember(ledgerId: Int64, name: String) throws -> LedgerMember {
        let member = LedgerMember(id: nextMemberId, ledgerId: ledgerId, name: name, createdAt: Date())
        nextMemberId += 1
        members[ledgerId, default: []].append(member)
        return member
    }

    func addSharedExpense(ledgerId: Int64, title: String, amount: Decimal, paidByMemberId: Int64, splits: [(memberId: Int64, amount: Decimal)]) throws {
        let expense = SharedExpense(
            id: nextExpenseId,
            ledgerId: ledgerId,
            title: title,
            amount: amount,
            paidByMemberId: paidByMemberId,
            createdAt: Date()
        )
        nextExpenseId += 1
        expenses[ledgerId, default: []].append(expense)
        splitsByExpenseId[expense.id] = splits.map { SharedExpenseSplit(expenseId: expense.id, memberId: $0.memberId, amount: $0.amount) }
    }

    func fetchOverview(ledgerId: Int64) throws -> GroupLedgerOverview {
        let ledger = ledgers.first(where: { $0.id == ledgerId }) ?? GroupLedger(id: ledgerId, name: "N/A", createdAt: Date())
        let groupMembers = members[ledgerId] ?? []
        let groupExpenses = expenses[ledgerId] ?? []

        let paidMap = Dictionary(groupExpenses.map { ($0.paidByMemberId, $0.amount) }, uniquingKeysWith: +)
        let owedRows = groupExpenses.flatMap { expense in
            splitsByExpenseId[expense.id] ?? []
        }
        let owedMap = Dictionary(owedRows.map { ($0.memberId, $0.amount) }, uniquingKeysWith: +)

        let balances = groupMembers.map {
            LedgerBalance(member: $0, paid: paidMap[$0.id] ?? .zero, owed: owedMap[$0.id] ?? .zero)
        }

        return GroupLedgerOverview(ledger: ledger, members: groupMembers, recentExpenses: groupExpenses, balances: balances)
    }
}

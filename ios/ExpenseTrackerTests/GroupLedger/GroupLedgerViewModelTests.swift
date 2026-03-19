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

    func testCustomProportionSplit() {
        let store = FakeGroupLedgerStore()
        let vm = GroupLedgerViewModel(store: store)

        vm.newLedgerName = "旅行"
        vm.createLedger()
        vm.newMemberName = "A"
        vm.addMember()
        vm.newMemberName = "B"
        vm.addMember()

        guard let members = vm.overview?.members else {
            XCTFail("Expected members")
            return
        }

        vm.splitRuleMode = .proportion
        vm.splitRuleInputs[members[0].id] = "2"
        vm.splitRuleInputs[members[1].id] = "1"
        vm.expenseTitle = "住宿"
        vm.expenseAmount = "900"
        vm.selectedPayerId = members[0].id
        vm.addSharedExpense()

        let balances = vm.overview?.balances ?? []
        XCTAssertEqual(balances.first(where: { $0.member.id == members[0].id })?.owed, 600)
        XCTAssertEqual(balances.first(where: { $0.member.id == members[1].id })?.owed, 300)
    }

    func testCustomFixedAmountSplitValidation() {
        let store = FakeGroupLedgerStore()
        let vm = GroupLedgerViewModel(store: store)

        vm.newLedgerName = "室友"
        vm.createLedger()
        vm.newMemberName = "A"
        vm.addMember()
        vm.newMemberName = "B"
        vm.addMember()

        guard let members = vm.overview?.members else {
            XCTFail("Expected members")
            return
        }

        vm.splitRuleMode = .fixedAmount
        vm.splitRuleInputs[members[0].id] = "100"
        vm.splitRuleInputs[members[1].id] = "100"
        vm.expenseTitle = "外送"
        vm.expenseAmount = "300"
        vm.selectedPayerId = members[0].id
        vm.addSharedExpense()

        XCTAssertEqual(vm.errorMessage, "金額分攤總和需等於支出金額")
    }

    func testSettlementUsesMinimalTransferCount() {
        let store = FakeGroupLedgerStore()
        let vm = GroupLedgerViewModel(store: store)

        vm.newLedgerName = "聚餐"
        vm.createLedger()
        vm.newMemberName = "A"
        vm.addMember()
        vm.newMemberName = "B"
        vm.addMember()
        vm.newMemberName = "C"
        vm.addMember()

        guard let members = vm.overview?.members else {
            XCTFail("Expected members")
            return
        }

        vm.selectedPayerId = members[0].id
        vm.expenseTitle = "A支付"
        vm.expenseAmount = "300"
        vm.addSharedExpense()

        vm.selectedPayerId = members[1].id
        vm.expenseTitle = "B支付"
        vm.expenseAmount = "150"
        vm.addSharedExpense()

        let settlements = vm.overview?.settlements ?? []
        XCTAssertEqual(settlements.count, 1)
        XCTAssertEqual(settlements.first?.fromMember.id, members[2].id)
        XCTAssertEqual(settlements.first?.toMember.id, members[0].id)
        XCTAssertEqual(settlements.first?.amount, 150)
    }

    func testMonthlyBudgetTracking() {
        let store = FakeGroupLedgerStore()
        let vm = GroupLedgerViewModel(store: store)

        vm.newLedgerName = "家庭"
        vm.createLedger()
        vm.newMemberName = "A"
        vm.addMember()

        vm.monthlyBudgetAmount = "3000"
        vm.saveMonthlyBudget()

        XCTAssertEqual(vm.overview?.budgetSnapshot.budget, 3000)
    }
}

private final class FakeGroupLedgerStore: GroupLedgerStore {
    private var ledgers: [GroupLedger] = []
    private var members: [Int64: [LedgerMember]] = [:]
    private var expenses: [Int64: [SharedExpense]] = [:]
    private var splitsByExpenseId: [Int64: [SharedExpenseSplit]] = [:]
    private var monthlyBudgets: [Int64: Decimal] = [:]

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

    func upsertMonthlyBudget(ledgerId: Int64, month: Date, amount: Decimal) throws {
        monthlyBudgets[ledgerId] = amount
    }

    func fetchOverview(ledgerId: Int64, month: Date) throws -> GroupLedgerOverview {
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

        return GroupLedgerOverview(
            ledger: ledger,
            members: groupMembers,
            recentExpenses: groupExpenses,
            balances: balances,
            settlements: computeSettlements(from: balances),
            budgetSnapshot: GroupBudgetSnapshot(monthStart: month, budget: monthlyBudgets[ledgerId] ?? .zero, spent: groupExpenses.reduce(.zero, { $0 + $1.amount })),
            monthlyReport: GroupMonthlyReport(
                monthStart: month,
                expenseCount: groupExpenses.count,
                totalExpense: groupExpenses.reduce(.zero, { $0 + $1.amount }),
                averageExpense: groupExpenses.isEmpty ? .zero : groupExpenses.reduce(.zero, { $0 + $1.amount }) / Decimal(groupExpenses.count),
                topExpenseTitle: groupExpenses.max(by: { $0.amount < $1.amount })?.title,
                payerBreakdown: []
            )
        )
    }

    private func computeSettlements(from balances: [LedgerBalance]) -> [SettlementTransfer] {
        var debtors = balances.filter { $0.net < 0 }.map { ($0.member, -$0.net) }
        var creditors = balances.filter { $0.net > 0 }.map { ($0.member, $0.net) }
        var i = 0
        var j = 0
        var result: [SettlementTransfer] = []

        while i < debtors.count, j < creditors.count {
            let amount = min(debtors[i].1, creditors[j].1)
            result.append(SettlementTransfer(fromMember: debtors[i].0, toMember: creditors[j].0, amount: amount))
            debtors[i].1 -= amount
            creditors[j].1 -= amount
            if debtors[i].1 == .zero { i += 1 }
            if creditors[j].1 == .zero { j += 1 }
        }

        return result
    }
}

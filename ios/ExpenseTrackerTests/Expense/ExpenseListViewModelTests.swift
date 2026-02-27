import XCTest
@testable import ExpenseTracker

@MainActor
final class ExpenseListViewModelTests: XCTestCase {
    func testAddExpenseAndReloadList() {
        let store = FakeExpenseStore()
        let vm = ExpenseListViewModel(store: store)

        vm.newTitle = "Dinner"
        vm.newAmount = "250"
        vm.isIncome = false
        vm.addExpense()

        XCTAssertEqual(vm.expenses.count, 1)
        XCTAssertEqual(vm.expenses.first?.title, "Dinner")
        XCTAssertEqual(vm.expenses.first?.amount, -250)
    }

    func testDeleteExpense() {
        let store = FakeExpenseStore(seed: [
            Expense(id: 1, title: "Coffee", amount: 80, createdAt: Date(), categoryId: nil),
            Expense(id: 2, title: "Taxi", amount: 200, createdAt: Date(), categoryId: nil),
        ])
        let vm = ExpenseListViewModel(store: store)

        vm.deleteExpenses(at: IndexSet(integer: 0))

        XCTAssertEqual(vm.expenses.map(\.id), [1])
    }

    func testSearchFiltersByTitle() {
        let store = FakeExpenseStore(seed: [
            Expense(id: 1, title: "Breakfast", amount: 120, createdAt: Date(), categoryId: nil),
            Expense(id: 2, title: "Bus", amount: 15, createdAt: Date(), categoryId: nil),
        ])
        let vm = ExpenseListViewModel(store: store)

        vm.searchText = "Break"

        XCTAssertEqual(vm.expenses.map(\.title), ["Breakfast"])
    }

    func testMonthlyOverviewCalculated() {
        let store = FakeExpenseStore(seed: [
            Expense(id: 1, title: "Salary", amount: 50000, createdAt: Date(), categoryId: nil),
            Expense(id: 2, title: "Rent", amount: -18000, createdAt: Date(), categoryId: nil),
        ])

        let vm = ExpenseListViewModel(store: store)

        XCTAssertEqual(vm.monthlyOverview.income, 50000)
        XCTAssertEqual(vm.monthlyOverview.expense, 18000)
        XCTAssertEqual(vm.monthlyOverview.net, 32000)
    }
}

private final class FakeExpenseStore: ExpenseStore {
    private var items: [Expense]

    init(seed: [Expense] = []) {
        self.items = seed
    }

    func fetchAll(searchText: String?) throws -> [Expense] {
        let keyword = (searchText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = keyword.isEmpty ? items : items.filter { $0.title.localizedCaseInsensitiveContains(keyword) }
        return filtered.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt { return lhs.id > rhs.id }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        let income = items.filter { $0.amount > 0 }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = items.filter { $0.amount < 0 }.reduce(Decimal(0)) { $0 + (-$1.amount) }
        return MonthlyOverview(
            month: month,
            income: income,
            expense: expense,
            categoryTotals: [.init(id: "未分類", name: "未分類", amount: income - expense)]
        )
    }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {
        let nextID = (items.map(\.id).max() ?? 0) + 1
        items.append(Expense(id: nextID, title: title, amount: amount, createdAt: Date(), categoryId: categoryId))
    }

    func delete(id: Int64) throws {
        items.removeAll { $0.id == id }
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

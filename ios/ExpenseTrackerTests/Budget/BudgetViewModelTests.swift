import XCTest
@testable import ExpenseTracker

@MainActor
final class BudgetViewModelTests: XCTestCase {
    func testSaveBudgetBuildsProgressFromMonthlyOverview() {
        let budgetStore = InMemoryBudgetStore()
        let expenseStore = MockExpenseStore(categoryTotals: [
            .init(id: "餐飲", name: "餐飲", amount: -800),
            .init(id: "薪資", name: "薪資", amount: 3000)
        ])

        let viewModel = BudgetViewModel(budgetStore: budgetStore, expenseStore: expenseStore)
        viewModel.selectedCategoryName = "餐飲"
        viewModel.amountText = "1000"
        viewModel.saveBudget()

        XCTAssertEqual(viewModel.progressItems.count, 1)
        XCTAssertEqual(viewModel.progressItems.first?.spent, 800)
        XCTAssertEqual(viewModel.progressItems.first?.remaining, 200)
        XCTAssertEqual(viewModel.progressItems.first?.status, .warning)
    }

    func testCopyLastMonthBringsPlansToCurrentMonth() {
        let budgetStore = InMemoryBudgetStore()
        let expenseStore = MockExpenseStore(categoryTotals: [.init(id: "交通", name: "交通", amount: -200)])
        let currentMonth = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"

        try? budgetStore.upsert(monthKey: formatter.string(from: lastMonth), categoryName: "交通", amount: 1000, carryOverMode: .none)

        let viewModel = BudgetViewModel(budgetStore: budgetStore, expenseStore: expenseStore, month: currentMonth)
        viewModel.copyLastMonth()

        XCTAssertEqual(viewModel.progressItems.count, 1)
        XCTAssertEqual(viewModel.progressItems.first?.categoryName, "交通")
    }
}

private final class InMemoryBudgetStore: BudgetStore {
    private var plans: [BudgetPlan] = []
    private var seq: Int64 = 1

    func fetch(monthKey: String) throws -> [BudgetPlan] {
        plans.filter { $0.monthKey == monthKey }
    }

    func upsert(monthKey: String, categoryName: String, amount: Decimal, carryOverMode: CarryOverMode) throws {
        if let index = plans.firstIndex(where: { $0.monthKey == monthKey && $0.categoryName == categoryName }) {
            plans[index] = BudgetPlan(id: plans[index].id, monthKey: monthKey, categoryName: categoryName, amount: amount, carryOverMode: carryOverMode)
            return
        }
        plans.append(BudgetPlan(id: seq, monthKey: monthKey, categoryName: categoryName, amount: amount, carryOverMode: carryOverMode))
        seq += 1
    }

    func delete(id: Int64) throws {
        plans.removeAll { $0.id == id }
    }

    func copy(from fromMonthKey: String, to toMonthKey: String) throws {
        let source = plans.filter { $0.monthKey == fromMonthKey }
        for item in source {
            try upsert(monthKey: toMonthKey, categoryName: item.categoryName, amount: item.amount, carryOverMode: item.carryOverMode)
        }
    }
}

private final class MockExpenseStore: ExpenseStore {
    private let categoryTotals: [MonthlyOverview.CategoryTotal]

    init(categoryTotals: [MonthlyOverview.CategoryTotal]) {
        self.categoryTotals = categoryTotals
    }

    func fetchAll(searchText: String?) throws -> [Expense] { [] }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {}

    func delete(id: Int64) throws {}

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        MonthlyOverview(month: month, income: 0, expense: 0, categoryTotals: categoryTotals)
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

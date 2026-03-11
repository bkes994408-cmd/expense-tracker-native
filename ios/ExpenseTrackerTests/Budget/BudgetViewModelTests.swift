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

    func testAdvancedReportFreeTierFallsBackToOneMonth() {
        let expenseStore = MockExpenseStore(categoryTotals: [
            .init(id: "餐飲", name: "餐飲", amount: -800),
            .init(id: "交通", name: "交通", amount: -300)
        ])
        let freeDefaults = UserDefaults(suiteName: "test.report.free")!
        freeDefaults.removePersistentDomain(forName: "test.report.free")
        let entitlement = ProEntitlementStore(defaults: freeDefaults)

        let viewModel = AdvancedReportViewModel(expenseStore: expenseStore, proEntitlementStore: entitlement)
        viewModel.selectedRange = .sixMonths
        viewModel.refresh()

        XCTAssertEqual(viewModel.report?.monthlyTrend.count, 1)
    }

    func testAdvancedReportProTierProvidesMoMCategoryDelta() {
        let previousMonth = MonthlyOverview(
            month: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            income: 5000,
            expense: 3000,
            categoryTotals: [.init(id: "餐飲", name: "餐飲", amount: -900), .init(id: "交通", name: "交通", amount: -400)]
        )
        let currentMonth = MonthlyOverview(
            month: Date(),
            income: 6000,
            expense: 3200,
            categoryTotals: [.init(id: "餐飲", name: "餐飲", amount: -1200), .init(id: "交通", name: "交通", amount: -300)]
        )

        let expenseStore = MonthlyOverviewStubStore(snapshots: [previousMonth, currentMonth])
        let defaults = UserDefaults(suiteName: "test.report.pro")!
        defaults.removePersistentDomain(forName: "test.report.pro")
        let entitlement = ProEntitlementStore(defaults: defaults)
        entitlement.subscribeMonthly()

        let viewModel = AdvancedReportViewModel(expenseStore: expenseStore, proEntitlementStore: entitlement)
        viewModel.selectedRange = .threeMonths
        viewModel.refresh()

        XCTAssertEqual(viewModel.report?.monthlyTrend.count, 3)
        XCTAssertEqual(viewModel.report?.topGrowth?.categoryName, "餐飲")
        XCTAssertEqual(viewModel.report?.topDecline?.categoryName, "交通")
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
        let result = viewModel.copyLastMonth()

        XCTAssertEqual(result, .copied)
        XCTAssertEqual(viewModel.progressItems.count, 1)
        XCTAssertEqual(viewModel.progressItems.first?.categoryName, "交通")
    }

    func testCopyLastMonthFreePlanTriggersPaywallWhenCategoryCountWouldExceedLimit() {
        let budgetStore = InMemoryBudgetStore()
        let expenseStore = MockExpenseStore(categoryTotals: [.init(id: "餐飲", name: "餐飲", amount: -200)])
        let currentMonth = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"

        try? budgetStore.upsert(monthKey: formatter.string(from: lastMonth), categoryName: "餐飲", amount: 1000, carryOverMode: .none)
        try? budgetStore.upsert(monthKey: formatter.string(from: lastMonth), categoryName: "交通", amount: 1000, carryOverMode: .none)
        try? budgetStore.upsert(monthKey: formatter.string(from: lastMonth), categoryName: "娛樂", amount: 1000, carryOverMode: .none)

        let viewModel = BudgetViewModel(budgetStore: budgetStore, expenseStore: expenseStore, month: currentMonth)
        let result = viewModel.copyLastMonth(isPro: false)

        XCTAssertEqual(result, .requiresProUpgrade)
        XCTAssertTrue(viewModel.progressItems.isEmpty)
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

private final class MonthlyOverviewStubStore: ExpenseStore {
    private let snapshots: [String: MonthlyOverview]

    init(snapshots: [MonthlyOverview]) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        self.snapshots = Dictionary(uniqueKeysWithValues: snapshots.map { (formatter.string(from: $0.month), $0) })
    }

    func fetchAll(searchText: String?) throws -> [Expense] { [] }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {}

    func delete(id: Int64) throws {}

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return snapshots[formatter.string(from: month)] ?? .empty(month: month)
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
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

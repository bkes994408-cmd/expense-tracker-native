import XCTest
@testable import ExpenseTracker

@MainActor
final class Iteration6FeatureTests: XCTestCase {
    func testAnnualWrappedBuilderCalculatesTotalsAndTopCategory() {
        let store = InMemoryExpenseStoreForIteration6()
        store.seed(
            year: 2025,
            month: 1,
            income: 50000,
            expense: 20000,
            categories: ["餐飲": -7000, "交通": -3000]
        )
        store.seed(
            year: 2025,
            month: 2,
            income: 48000,
            expense: 26000,
            categories: ["餐飲": -8000, "娛樂": -6000]
        )

        let report = AnnualWrappedReportBuilder(store: store).build(year: 2025)

        XCTAssertEqual(report?.totalIncome, 98000)
        XCTAssertEqual(report?.totalExpense, 46000)
        XCTAssertEqual(report?.totalNet, 52000)
        XCTAssertEqual(report?.topExpenseCategory?.name, "餐飲")
    }

    func testSnapshotExportAndRestoreRoundTrip() throws {
        let store = InMemoryExpenseStoreForIteration6(expenses: [
            Expense(id: 1, title: "Lunch", amount: -120, createdAt: Date(timeIntervalSince1970: 100), categoryId: nil),
            Expense(id: 2, title: "Salary", amount: 30000, createdAt: Date(timeIntervalSince1970: 200), categoryId: nil)
        ])
        let service = ExpenseSnapshotService(store: store)

        let snapshot = try service.exportSnapshot()
        try store.delete(id: 1)
        XCTAssertEqual(try store.fetchAll(searchText: nil).count, 1)

        try service.restoreSnapshot(from: snapshot)
        let restored = try store.fetchAll(searchText: nil)
        XCTAssertEqual(restored.count, 2)
        XCTAssertTrue(restored.contains(where: { $0.title == "Lunch" }))
    }

    func testRetentionStrategyForTrialLastDay() async {
        let suiteName = "Iteration6FeatureTests.retention"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .success(.trial)),
            nowProvider: { now }
        )

        await store.startTrial()

        defaults.set(now.addingTimeInterval(24 * 60 * 60), forKey: "pro.entitlement.trial.expireAt")
        let nearExpiry = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(),
            nowProvider: { now }
        )

        XCTAssertEqual(nearExpiry.retentionStrategy?.offerCode, "trial_last48h")
    }
}

private final class InMemoryExpenseStoreForIteration6: ExpenseStore {
    private var expenses: [Expense]
    private var monthlyOverviews: [String: MonthlyOverview] = [:]

    init(expenses: [Expense] = []) {
        self.expenses = expenses
    }

    func seed(year: Int, month: Int, income: Decimal, expense: Decimal, categories: [String: Decimal]) {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
        monthlyOverviews["\(year)-\(month)"] = MonthlyOverview(
            month: date,
            income: income,
            expense: expense,
            categoryTotals: categories.map { .init(id: $0.key, name: $0.key, amount: $0.value) }
        )
    }

    func fetchAll(searchText: String?) throws -> [Expense] { expenses }

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {
        let nextId = (expenses.map(\.id).max() ?? 0) + 1
        expenses.append(Expense(id: nextId, title: title, amount: amount, createdAt: createdAt, categoryId: categoryId))
    }

    func delete(id: Int64) throws {
        expenses.removeAll { $0.id == id }
    }

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        let c = Calendar.current.dateComponents([.year, .month], from: month)
        return monthlyOverviews["\(c.year!)-\(c.month!)"] ?? .empty(month: month)
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

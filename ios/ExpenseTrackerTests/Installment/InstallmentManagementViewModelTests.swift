import XCTest
@testable import ExpenseTracker

@MainActor
final class InstallmentManagementViewModelTests: XCTestCase {
    func testAddInstallmentAndCalculateRemainingPeriods() {
        let store = FakeInstallmentStore()
        let vm = InstallmentManagementViewModel(store: store)

        vm.newName = "MacBook"
        vm.periodAmount = "3200"
        vm.totalPeriods = "12"
        vm.paidPeriods = "3"
        vm.addPlan()

        XCTAssertEqual(vm.plans.count, 1)
        XCTAssertEqual(vm.plans.first?.remainingPeriods, 9)
    }
}

private final class FakeInstallmentStore: InstallmentStore {
    private var items: [InstallmentPlan] = []

    func fetchAll() throws -> [InstallmentPlan] { items }

    func add(name: String, periodAmount: Decimal, totalPeriods: Int, paidPeriods: Int) throws {
        let nextId = (items.map(\.id).max() ?? 0) + 1
        items.append(
            InstallmentPlan(
                id: nextId,
                name: name,
                totalPeriods: totalPeriods,
                paidPeriods: min(max(0, paidPeriods), totalPeriods),
                periodAmount: periodAmount
            )
        )
    }
}

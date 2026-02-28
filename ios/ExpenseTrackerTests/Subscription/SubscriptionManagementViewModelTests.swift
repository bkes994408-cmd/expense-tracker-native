import XCTest
@testable import ExpenseTracker

@MainActor
final class SubscriptionManagementViewModelTests: XCTestCase {
    func testAddSubscriptionAndShowReminder() {
        let store = FakeSubscriptionStore()
        let vm = SubscriptionManagementViewModel(store: store)

        vm.newName = "Spotify"
        vm.newAmount = "149"
        vm.cycleDays = "30"
        vm.reminderDaysBefore = "2"
        vm.reminderEnabled = true
        vm.addPlan()

        XCTAssertEqual(vm.plans.count, 1)
        XCTAssertEqual(vm.plans.first?.name, "Spotify")
        XCTAssertEqual(vm.plans.first?.reminderText, "扣款前 2 天提醒")
    }
}

private final class FakeSubscriptionStore: SubscriptionStore {
    private var items: [SubscriptionPlan] = []

    func fetchAll() throws -> [SubscriptionPlan] { items }

    func add(name: String, amount: Decimal, cycleDays: Int, nextChargeAt: Date, reminderDaysBefore: Int, reminderEnabled: Bool) throws {
        let nextId = (items.map(\.id).max() ?? 0) + 1
        items.append(
            SubscriptionPlan(
                id: nextId,
                name: name,
                amount: amount,
                cycleDays: cycleDays,
                nextChargeAt: nextChargeAt,
                reminderDaysBefore: reminderDaysBefore,
                reminderEnabled: reminderEnabled
            )
        )
    }
}

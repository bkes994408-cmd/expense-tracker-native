import XCTest
@testable import ExpenseTracker

@MainActor
final class ProEntitlementStoreTests: XCTestCase {
    func testSubscribeMonthlyUpdatesTierAndSource() async {
        let suiteName = "ProEntitlementStoreTests.subscribeMonthly"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .success(.monthly))
        )

        await store.subscribeMonthly()

        XCTAssertEqual(store.tier, .monthly)
        XCTAssertEqual(store.source, "paywall_monthly")
        XCTAssertNil(store.errorMessage)
    }

    func testPurchaseFailureShowsErrorAndDoesNotUpgrade() async {
        struct DummyError: LocalizedError { var errorDescription: String? { "mock-fail" } }

        let suiteName = "ProEntitlementStoreTests.purchaseFail"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .failure(DummyError()))
        )

        await store.subscribeYearly()

        XCTAssertEqual(store.tier, .free)
        XCTAssertEqual(store.errorMessage, "mock-fail")
    }

    func testRestoreSetsTierFromService() async {
        let suiteName = "ProEntitlementStoreTests.restore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(restoreResult: .success(.yearly))
        )

        await store.restorePurchase()

        XCTAssertEqual(store.tier, .yearly)
        XCTAssertEqual(store.source, "restore_purchase")
    }
}

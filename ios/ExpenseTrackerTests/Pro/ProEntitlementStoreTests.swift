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

    func testRestoreFailureKeepsCurrentTierAndShowsError() async {
        struct RestoreError: LocalizedError { var errorDescription: String? { "restore-failed" } }

        let suiteName = "ProEntitlementStoreTests.restoreFailure"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(
                purchaseResult: .success(.monthly),
                restoreResult: .failure(RestoreError())
            )
        )

        await store.subscribeMonthly()
        await store.restorePurchase()

        XCTAssertEqual(store.tier, .monthly)
        XCTAssertEqual(store.errorMessage, "restore-failed")
    }

    func testRestoreWithNoPurchaseRecordKeepsFreeTier() async {
        let suiteName = "ProEntitlementStoreTests.restoreNil"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(restoreResult: .success(nil))
        )

        await store.restorePurchase()

        XCTAssertEqual(store.tier, .free)
        XCTAssertEqual(store.source, "restore_purchase")
        XCTAssertNil(store.errorMessage)
    }

    func testPendingPurchaseShowsPendingMessage() async {
        let suiteName = "ProEntitlementStoreTests.pendingPurchase"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .failure(IAPError.pending))
        )

        await store.subscribeMonthly()

        XCTAssertEqual(store.tier, .free)
        XCTAssertEqual(store.errorMessage, IAPError.pending.errorDescription)
    }

    func testTrialExpiryRevokesProAccess() async {
        let suiteName = "ProEntitlementStoreTests.trialExpiry"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .success(.trial)),
            nowProvider: { baseDate }
        )

        await store.startTrial()
        XCTAssertEqual(store.subscriptionState, .active)
        XCTAssertTrue(store.canAccess(.advancedReports))

        let expired = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(),
            nowProvider: { baseDate.addingTimeInterval(8 * 24 * 60 * 60) }
        )

        XCTAssertEqual(expired.subscriptionState, .expired)
        XCTAssertFalse(expired.canAccess(.pdfExport))
    }

    func testRestoreTrialDoesNotExtendExistingTrialWindow() async {
        let suiteName = "ProEntitlementStoreTests.restoreTrialNoExtend"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let oneDayLater = baseDate.addingTimeInterval(24 * 60 * 60)

        let firstStore = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(purchaseResult: .success(.trial)),
            nowProvider: { baseDate }
        )
        await firstStore.startTrial()
        let originalExpiry = firstStore.trialExpireAt

        let restoredStore = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(restoreResult: .success(.trial)),
            nowProvider: { oneDayLater }
        )
        await restoredStore.restorePurchase()

        XCTAssertEqual(restoredStore.trialExpireAt, originalExpiry)
    }

    func testRestoreTrialWithoutStoredExpiryIsImmediatelyExpired() async {
        let suiteName = "ProEntitlementStoreTests.restoreTrialWithoutExpiry"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ProEntitlementStore(
            defaults: defaults,
            purchaseService: MockInAppPurchaseService(restoreResult: .success(.trial)),
            nowProvider: { now }
        )

        await store.restorePurchase()

        XCTAssertEqual(store.subscriptionState, .expired)
        XCTAssertFalse(store.isPro)
    }

    func testIAPErrorMessagesAreSpecific() {
        XCTAssertNotEqual(IAPError.pending.errorDescription, IAPError.userCancelled.errorDescription)
        XCTAssertEqual(IAPError.unknownProduct.errorDescription, "收到未知商品，請聯繫客服協助處理。")
    }

    func testStoreKitProductMappingDistinguishesTrialAndYearly() throws {
        let service = StoreKitPurchaseService()

        XCTAssertEqual(try service.mapProductIdToTier(StoreKitPurchaseService.trialProductId), .trial)
        XCTAssertEqual(try service.mapProductIdToTier(StoreKitPurchaseService.yearlyProductId), .yearly)
    }

    func testStoreKitUnknownProductThrowsUnknownProductError() {
        let service = StoreKitPurchaseService()

        XCTAssertThrowsError(try service.mapProductIdToTier("com.bkes994408.expensetracker.pro.unknown")) { error in
            XCTAssertEqual(error as? IAPError, .unknownProduct)
        }
    }
}

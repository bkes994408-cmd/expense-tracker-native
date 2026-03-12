package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProEntitlementStoreTest {
    @Test
    fun subscribeMonthly_updatesTierAndStatusMetadata() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.MONTHLY)),
        )

        store.subscribeMonthly()

        assertEquals(ProTier.MONTHLY, store.tier)
        assertEquals("paywall_monthly", store.source)
        assertNotNull(store.lastUpdatedAtMillis)
        assertNull(store.lastError)
    }

    @Test
    fun permissionCheck_followsTier() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.YEARLY)),
        )

        assertFalse(store.hasAccess(ProFeature.REPORT_PDF_EXPORT))
        store.subscribeYearly()

        assertTrue(store.hasAccess(ProFeature.REPORT_PDF_EXPORT))
        assertTrue(store.hasAccess(ProFeature.ADVANCED_REPORT_MULTI_MONTH))
    }

    @Test
    fun purchaseFailure_keepsFreeAndStoresError() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(
                purchaseResult = Result.failure(IllegalStateException("billing-fail")),
            ),
        )

        store.subscribeYearly()

        assertEquals(ProTier.FREE, store.tier)
        assertEquals("billing-fail", store.lastError)
    }

    @Test
    fun pendingPurchase_keepsFreeAndStoresPendingError() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(
                purchaseResult = Result.failure(IllegalStateException("pending")),
            ),
        )

        store.subscribeMonthly()

        assertEquals(ProTier.FREE, store.tier)
        assertEquals("pending", store.lastError)
    }

    @Test
    fun unknownProduct_keepsFreeAndStoresError() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(
                purchaseResult = Result.failure(IllegalArgumentException("unknown product")),
            ),
        )

        store.startTrial()

        assertEquals(ProTier.FREE, store.tier)
        assertEquals("unknown product", store.lastError)
    }

    @Test
    fun restorePurchase_updatesTierFromService() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(restoreResult = Result.success(ProTier.YEARLY)),
        )

        store.restorePurchase()

        assertEquals(ProTier.YEARLY, store.tier)
        assertEquals("restore_purchase", store.source)
        assertNull(store.lastError)
    }

    @Test
    fun restoreFailure_keepsCurrentTierAndStoresError() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(
                purchaseResult = Result.success(ProTier.MONTHLY),
                restoreResult = Result.failure(IllegalStateException("restore-fail")),
            ),
        )

        store.subscribeMonthly()
        store.restorePurchase()

        assertEquals(ProTier.MONTHLY, store.tier)
        assertEquals("restore-fail", store.lastError)
    }

    @Test
    fun restoreNil_setsFreeAndClearsError() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(
                purchaseResult = Result.success(ProTier.YEARLY),
                restoreResult = Result.success(null),
            ),
        )

        store.subscribeYearly()
        store.restorePurchase()

        assertEquals(ProTier.FREE, store.tier)
        assertEquals("restore_purchase", store.source)
        assertNull(store.lastError)
    }
}

private class InMemoryEntitlementStorage : EntitlementStorage {
    private var tierName: String = ProTier.FREE.name
    private var source: String = "none"
    private var updatedAtMillis: Long? = null

    override fun readTierName(): String = tierName

    override fun writeTierName(value: String) {
        tierName = value
    }

    override fun readSource(): String = source

    override fun writeSource(value: String) {
        source = value
    }

    override fun readUpdatedAtMillis(): Long? = updatedAtMillis

    override fun writeUpdatedAtMillis(value: Long) {
        updatedAtMillis = value
    }
}

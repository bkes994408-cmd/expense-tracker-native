package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ProEntitlementStoreTest {
    @Test
    fun subscribeMonthly_updatesTier() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.MONTHLY)),
        )

        store.subscribeMonthly()

        assertEquals(ProTier.MONTHLY, store.tier)
        assertNull(store.lastError)
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
    fun restorePurchase_updatesTierFromService() {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(restoreResult = Result.success(ProTier.YEARLY)),
        )

        store.restorePurchase()

        assertEquals(ProTier.YEARLY, store.tier)
        assertNull(store.lastError)
    }
}

private class InMemoryEntitlementStorage : EntitlementStorage {
    private var tierName: String = ProTier.FREE.name

    override fun readTierName(): String = tierName

    override fun writeTierName(value: String) {
        tierName = value
    }
}

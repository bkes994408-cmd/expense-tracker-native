package com.bkes994408.expensetracker.pro

import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ProEntitlementStoreTest {
    @Test
    fun subscribeMonthly_updatesTier() = runTest {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.MONTHLY)),
        )

        store.subscribeMonthly()

        assertEquals(ProTier.MONTHLY, store.tier)
        assertEquals(SubscriptionState.ACTIVE, store.subscriptionState)
        assertNull(store.lastError)
    }

    @Test
    fun trialExpires_changesStateToExpiredAndRevokesFeature() = runTest {
        val now = 1_000_000L
        val storage = InMemoryEntitlementStorage()
        val store = ProEntitlementStore(
            storage = storage,
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.TRIAL)),
            nowProvider = { now },
        )

        store.startTrial()
        assertTrue(store.canAccess(ProFeature.ADVANCED_REPORTS))

        val expiredStore = ProEntitlementStore(
            storage = storage,
            purchaseService = MockProPurchaseService(),
            nowProvider = { now + 8L * 24L * 60L * 60L * 1000L },
        )

        assertEquals(SubscriptionState.EXPIRED, expiredStore.subscriptionState)
        assertFalse(expiredStore.canAccess(ProFeature.PDF_EXPORT))
    }

    @Test
    fun purchaseFailure_keepsFreeAndStoresError() = runTest {
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
    fun restorePurchase_updatesTierFromService() = runTest {
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(restoreResult = Result.success(ProTier.YEARLY)),
        )

        store.restorePurchase()

        assertEquals(ProTier.YEARLY, store.tier)
        assertEquals(SubscriptionState.ACTIVE, store.subscriptionState)
        assertNull(store.lastError)
    }

    @Test
    fun restoreNil_setsFreeAndClearsError() = runTest {
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
        assertEquals(SubscriptionState.FREE, store.subscriptionState)
        assertNull(store.lastError)
    }

    @Test
    fun restoreTrial_preservesExistingTrialExpiry() = runTest {
        val now = 1_000_000L
        val storage = InMemoryEntitlementStorage()

        val starter = ProEntitlementStore(
            storage = storage,
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.TRIAL)),
            nowProvider = { now },
        )
        starter.startTrial()
        val originalExpiry = starter.trialExpireAtMillis

        val restored = ProEntitlementStore(
            storage = storage,
            purchaseService = MockProPurchaseService(restoreResult = Result.success(ProTier.TRIAL)),
            nowProvider = { now + 24L * 60L * 60L * 1000L },
        )
        restored.restorePurchase()

        assertEquals(originalExpiry, restored.trialExpireAtMillis)
    }

    @Test
    fun restoreTrial_withoutStoredExpiry_isImmediatelyExpired() = runTest {
        val now = 1_000_000L
        val store = ProEntitlementStore(
            storage = InMemoryEntitlementStorage(),
            purchaseService = MockProPurchaseService(restoreResult = Result.success(ProTier.TRIAL)),
            nowProvider = { now },
        )

        store.restorePurchase()

        assertEquals(SubscriptionState.EXPIRED, store.subscriptionState)
        assertFalse(store.isPro)
    }
}

private class InMemoryEntitlementStorage : EntitlementStorage {
    private var tierName: String = ProTier.FREE.name
    private var trialExpireAtMillis: Long? = null

    override fun readTierName(): String = tierName

    override fun writeTierName(value: String) {
        tierName = value
    }

    override fun readTrialExpireAtMillis(): Long? = trialExpireAtMillis

    override fun writeTrialExpireAtMillis(value: Long?) {
        trialExpireAtMillis = value
    }
}

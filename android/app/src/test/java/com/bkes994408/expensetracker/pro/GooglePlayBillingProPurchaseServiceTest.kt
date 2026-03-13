package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GooglePlayBillingProPurchaseServiceTest {
    @Test
    fun purchaseMonthly_mapsToProTierMonthly() {
        val service = GooglePlayBillingProPurchaseService(
            billingClient = FakePlayBillingClient(
                purchaseOutcome = PurchaseOutcome.Success(GooglePlayBillingProPurchaseService.MONTHLY_PRODUCT_ID),
            ),
        )

        val result = service.purchase(ProPlan.MONTHLY)

        assertTrue(result.isSuccess)
        assertEquals(ProTier.MONTHLY, result.getOrNull())
    }

    @Test
    fun purchasePending_returnsPendingError() {
        val service = GooglePlayBillingProPurchaseService(
            billingClient = FakePlayBillingClient(purchaseOutcome = PurchaseOutcome.Pending),
        )

        val result = service.purchase(ProPlan.YEARLY)

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is BillingError.Pending)
    }

    @Test
    fun restoreUnknownProduct_returnsFailure() {
        val service = GooglePlayBillingProPurchaseService(
            billingClient = FakePlayBillingClient(restoreProductId = "unknown.sku"),
        )

        val result = service.restore()

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is BillingError.UnknownProduct)
    }

    @Test
    fun restoreYearly_mapsToYearlyTier() {
        val service = GooglePlayBillingProPurchaseService(
            billingClient = FakePlayBillingClient(
                restoreProductId = GooglePlayBillingProPurchaseService.YEARLY_PRODUCT_ID,
            ),
        )

        val result = service.restore()

        assertTrue(result.isSuccess)
        assertEquals(ProTier.YEARLY, result.getOrNull())
    }
}

private class FakePlayBillingClient(
    private val purchaseOutcome: PurchaseOutcome = PurchaseOutcome.Success(
        GooglePlayBillingProPurchaseService.MONTHLY_PRODUCT_ID,
    ),
    private val restoreProductId: String? = null,
) : PlayBillingClient {
    override suspend fun purchase(plan: ProPlan): PurchaseOutcome = purchaseOutcome

    override suspend fun restore(): String? = restoreProductId
}

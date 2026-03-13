package com.bkes994408.expensetracker.pro

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GooglePlayBillingPurchaseServiceTest {
    @Test
    fun purchase_monthly_mapsToMonthlyTier() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(purchaseResult = Result.success(ProductIds.MONTHLY)),
        )

        val result = runBlocking { service.purchase(ProPlan.MONTHLY) }

        assertTrue(result.isSuccess)
        assertEquals(ProTier.MONTHLY, result.getOrNull())
    }

    @Test
    fun purchase_unknownProduct_returnsFailure() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(purchaseResult = Result.success("unknown.sku")),
        )

        val result = runBlocking { service.purchase(ProPlan.YEARLY) }

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is IllegalArgumentException)
    }

    @Test
    fun restore_multiplePurchases_returnsHighestTier() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(
                restoreResult = Result.success(
                    listOf(ProductIds.TRIAL, ProductIds.MONTHLY, ProductIds.YEARLY),
                ),
            ),
        )

        val result = runBlocking { service.restore() }

        assertTrue(result.isSuccess)
        assertEquals(ProTier.YEARLY, result.getOrNull())
    }

    @Test
    fun restore_noPurchase_returnsNullTier() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(restoreResult = Result.success(emptyList())),
        )

        val result = runBlocking { service.restore() }

        assertTrue(result.isSuccess)
        assertEquals(null, result.getOrNull())
    }

    @Test
    fun restore_unknownProducts_areIgnored() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(
                restoreResult = Result.success(
                    listOf("unknown.sku.1", "unknown.sku.2"),
                ),
            ),
        )

        val result = runBlocking { service.restore() }

        assertTrue(result.isSuccess)
        assertEquals(null, result.getOrNull())
    }

    @Test
    fun restore_mixedKnownAndUnknown_returnsHighestKnownTier() {
        val service = GooglePlayBillingPurchaseService(
            gateway = FakeGateway(
                restoreResult = Result.success(
                    listOf("unknown.sku", ProductIds.MONTHLY, ProductIds.TRIAL),
                ),
            ),
        )

        val result = runBlocking { service.restore() }

        assertTrue(result.isSuccess)
        assertEquals(ProTier.MONTHLY, result.getOrNull())
    }
}

private class FakeGateway(
    private val purchaseResult: Result<String> = Result.success(ProductIds.MONTHLY),
    private val restoreResult: Result<List<String>> = Result.success(emptyList()),
) : GooglePlayBillingGateway {
    override fun launchPurchase(productId: String): Result<String> = purchaseResult

    override fun queryActivePurchases(): Result<List<String>> = restoreResult
}

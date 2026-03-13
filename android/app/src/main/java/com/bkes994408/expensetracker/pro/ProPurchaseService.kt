package com.bkes994408.expensetracker.pro

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

enum class ProPlan {
    TRIAL,
    MONTHLY,
    YEARLY,
}

interface ProPurchaseService {
    fun purchase(plan: ProPlan): Result<ProTier>
    fun restore(): Result<ProTier?>
}

class MockProPurchaseService(
    private val purchaseResult: Result<ProTier> = Result.success(ProTier.MONTHLY),
    private val restoreResult: Result<ProTier?> = Result.success(null),
) : ProPurchaseService {
    override fun purchase(plan: ProPlan): Result<ProTier> = purchaseResult
    override fun restore(): Result<ProTier?> = restoreResult
}

class GooglePlayBillingProPurchaseService(
    private val billingClient: PlayBillingClient,
) : ProPurchaseService {
    override fun purchase(plan: ProPlan): Result<ProTier> = runCatching {
        when (val outcome = runBlocking { billingClient.purchase(plan) }) {
            is PurchaseOutcome.Success -> mapProductIdToTier(outcome.productId)
            PurchaseOutcome.Cancelled -> throw BillingError.UserCancelled
            PurchaseOutcome.Pending -> throw BillingError.Pending
        }
    }

    override fun restore(): Result<ProTier?> = runCatching {
        runBlocking { billingClient.restore() }?.let(::mapProductIdToTier)
    }

    fun mapProductIdToTier(productId: String): ProTier {
        return when (productId) {
            TRIAL_PRODUCT_ID -> ProTier.TRIAL
            MONTHLY_PRODUCT_ID -> ProTier.MONTHLY
            YEARLY_PRODUCT_ID -> ProTier.YEARLY
            else -> throw BillingError.UnknownProduct(productId)
        }
    }

    companion object {
        const val TRIAL_PRODUCT_ID = "com.bkes994408.expensetracker.pro.trial"
        const val MONTHLY_PRODUCT_ID = "com.bkes994408.expensetracker.pro.monthly"
        const val YEARLY_PRODUCT_ID = "com.bkes994408.expensetracker.pro.yearly"
    }
}

sealed interface PurchaseOutcome {
    data class Success(val productId: String) : PurchaseOutcome
    data object Cancelled : PurchaseOutcome
    data object Pending : PurchaseOutcome
}

sealed class BillingError(message: String) : IllegalStateException(message) {
    data object UserCancelled : BillingError("你已取消購買。")
    data object Pending : BillingError("付款正在等待處理中，完成後會自動更新。")
    data class UnknownProduct(val productId: String) : BillingError("收到未知商品：$productId")
    data class SdkError(val code: Int, val debugMessage: String) :
        BillingError("Google Play Billing 錯誤($code): $debugMessage")
}

interface PlayBillingClient {
    suspend fun purchase(plan: ProPlan): PurchaseOutcome
    suspend fun restore(): String?
}

class GooglePlayBillingClient(
    context: Context,
    private val activityProvider: () -> Activity?,
) : PlayBillingClient {
    private var purchaseContinuation: (Result<PurchaseOutcome>) -> Unit = {}

    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        if (billingResult.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            purchaseContinuation(Result.success(PurchaseOutcome.Cancelled))
            return@PurchasesUpdatedListener
        }
        if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            purchaseContinuation(Result.failure(BillingError.SdkError(billingResult.responseCode, billingResult.debugMessage)))
            return@PurchasesUpdatedListener
        }

        val purchase = purchases.orEmpty().firstOrNull()
            ?: return@PurchasesUpdatedListener purchaseContinuation(Result.failure(BillingError.SdkError(-1, "purchase-not-found")))

        if (purchase.purchaseState == Purchase.PurchaseState.PENDING) {
            purchaseContinuation(Result.success(PurchaseOutcome.Pending))
            return@PurchasesUpdatedListener
        }

        val productId = purchase.products.firstOrNull()
            ?: return@PurchasesUpdatedListener purchaseContinuation(Result.failure(BillingError.SdkError(-1, "product-not-found")))

        acknowledgeIfNeeded(purchase)
        purchaseContinuation(Result.success(PurchaseOutcome.Success(productId)))
    }

    private val client: BillingClient = BillingClient.newBuilder(context)
        .setListener(purchasesUpdatedListener)
        .enablePendingPurchases()
        .build()

    override suspend fun purchase(plan: ProPlan): PurchaseOutcome {
        val activity = activityProvider() ?: throw IllegalStateException("Activity unavailable for purchase flow")
        connectIfNeeded()

        val productId = when (plan) {
            ProPlan.TRIAL -> GooglePlayBillingProPurchaseService.TRIAL_PRODUCT_ID
            ProPlan.MONTHLY -> GooglePlayBillingProPurchaseService.MONTHLY_PRODUCT_ID
            ProPlan.YEARLY -> GooglePlayBillingProPurchaseService.YEARLY_PRODUCT_ID
        }

        val productDetails = queryProductDetails(productId)
        val detailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)
            .build()

        return suspendCancellableCoroutine { continuation ->
            purchaseContinuation = { result ->
                if (!continuation.isActive) return@purchaseContinuation
                result.onSuccess { continuation.resume(it) }
                    .onFailure { continuation.resumeWithException(it) }
            }

            val launchResult = client.launchBillingFlow(
                activity,
                BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(detailsParams)).build(),
            )

            if (launchResult.responseCode != BillingClient.BillingResponseCode.OK) {
                purchaseContinuation(Result.failure(BillingError.SdkError(launchResult.responseCode, launchResult.debugMessage)))
            }
        }
    }

    override suspend fun restore(): String? {
        connectIfNeeded()
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()

        val purchasesResult = client.queryPurchasesAsync(params)
        val billingResult = purchasesResult.billingResult
        if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            throw BillingError.SdkError(billingResult.responseCode, billingResult.debugMessage)
        }

        val purchase = purchasesResult.purchasesList.firstOrNull() ?: return null
        val productId = purchase.products.firstOrNull() ?: return null
        acknowledgeIfNeeded(purchase)
        return productId
    }

    private suspend fun connectIfNeeded() {
        if (client.isReady) return

        suspendCancellableCoroutine<Unit> { continuation ->
            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                        continuation.resume(Unit)
                    } else {
                        continuation.resumeWithException(BillingError.SdkError(result.responseCode, result.debugMessage))
                    }
                }

                override fun onBillingServiceDisconnected() {
                    if (continuation.isActive) {
                        continuation.resumeWithException(BillingError.SdkError(-1, "billing-service-disconnected"))
                    }
                }
            })
        }
    }

    private suspend fun queryProductDetails(productId: String): ProductDetails {
        val products = listOf(
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS)
                .build(),
        )
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(products)
            .build()

        return suspendCancellableCoroutine { continuation ->
            client.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
                if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    continuation.resumeWithException(BillingError.SdkError(billingResult.responseCode, billingResult.debugMessage))
                    return@queryProductDetailsAsync
                }

                val product = productDetailsList.firstOrNull()
                if (product == null) {
                    continuation.resumeWithException(IllegalStateException("找不到可購買商品：$productId"))
                } else {
                    continuation.resume(product)
                }
            }
        }
    }

    private fun acknowledgeIfNeeded(purchase: Purchase) {
        if (purchase.isAcknowledged) return

        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        client.acknowledgePurchase(params) {}
    }
}

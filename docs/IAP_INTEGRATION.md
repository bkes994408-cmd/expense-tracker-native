# 應用程式內購買（In-App Purchase）整合與測試（MVP-6）

## 範圍
- iOS：導入 StoreKit 2 購買抽象層 `InAppPurchaseService`，支援 trial / 月費 / 年費與 Restore。
- Android：已接入 **Google Play Billing v7**（`GooglePlayBillingClient` + `GooglePlayBillingProPurchaseService`），支援 trial / 月費 / 年費商品對應、購買結果處理（success / cancelled / pending）、Restore（`queryPurchases`）與必要 acknowledge。
- Paywall UI：購買失敗顯示錯誤訊息、購買成功才關閉 paywall。

## Android 整合深度（現況與下一步）
- 現況：
  - 已完成 `GooglePlayBillingClient`（BillingClient 連線、商品查詢、購買流程 callback、Restore 查詢）。
  - 已完成 `GooglePlayBillingProPurchaseService`（SKU -> `ProTier` 映射、pending/cancelled/unknown SKU 錯誤語義）。
  - `RootNavHost` 已改為注入真實 Billing service 至 `ProEntitlementStore`，不再只用 mock service。
- 下一步規劃：
  1. 在 Internal testing track 搭配 license tester 驗證真機購買/還原。
  2. 補上 billing service disconnect / retry 策略。
  3. 針對 pending transaction 長時間停留與多商品 restore 優先順序補強 instrumentation 測試。

## 商品 ID（iOS）
- `com.bkes994408.expensetracker.pro.trial`（獨立 trial SKU，entitlement = `trial`）
- `com.bkes994408.expensetracker.pro.monthly`
- `com.bkes994408.expensetracker.pro.yearly`

### trial entitlement 定義
- `trial` entitlement **只**代表購買到獨立 `trial` 商品（`...pro.trial`）。
- 若是 `yearly` 商品本身附帶 introductory offer（例如免費試用期），entitlement 仍視為 `yearly`，不會映射為 `trial`。
- `mapProductIdToTier` 與 StoreKit restore 流程都採用同一套定義，避免平台或流程間語意不一致。

> 實際上線前，請在 App Store Connect 與 Google Play Console 建立對應商品，並確認價格與試用週期一致。

## 測試
### iOS Unit Tests
- `ProEntitlementStoreTests.testSubscribeMonthlyUpdatesTierAndSource`
- `ProEntitlementStoreTests.testPurchaseFailureShowsErrorAndDoesNotUpgrade`
- `ProEntitlementStoreTests.testRestoreSetsTierFromService`
- `ProEntitlementStoreTests.testRestoreFailureKeepsCurrentTierAndShowsError`
- `ProEntitlementStoreTests.testRestoreWithNoPurchaseRecordKeepsFreeTier`
- `ProEntitlementStoreTests.testPendingPurchaseShowsPendingMessage`
- `ProEntitlementStoreTests.testStoreKitProductMappingDistinguishesTrialAndYearly`
- `ProEntitlementStoreTests.testStoreKitUnknownProductThrowsUnknownProductError`

### Android Unit Tests
- `ProEntitlementStoreTest.subscribeMonthly_updatesTier`
- `ProEntitlementStoreTest.purchaseFailure_keepsFreeAndStoresError`
- `ProEntitlementStoreTest.restorePurchase_updatesTierFromService`
- `ProEntitlementStoreTest.restoreFailure_keepsCurrentTierAndStoresError`
- `ProEntitlementStoreTest.restoreNil_setsFreeAndClearsError`
- `GooglePlayBillingProPurchaseServiceTest.purchaseMonthly_mapsToProTierMonthly`
- `GooglePlayBillingProPurchaseServiceTest.purchasePending_returnsPendingError`
- `GooglePlayBillingProPurchaseServiceTest.restoreUnknownProduct_returnsFailure`
- `GooglePlayBillingProPurchaseServiceTest.restoreYearly_mapsToYearlyTier`

## Sandbox / QA 建議
1. iOS 使用 StoreKit Configuration 或 Sandbox Apple ID 驗證購買與 Restore。
2. Android 於 Internal testing track 使用 license tester 驗證購買與 Restore。
3. 驗證情境：
   - 付款成功 -> entitlement 從 FREE 轉 PRO
   - 使用者取消 -> entitlement 不變、顯示錯誤
   - Restore 成功 -> entitlement 還原
   - Restore 無歷史購買 -> 維持 FREE

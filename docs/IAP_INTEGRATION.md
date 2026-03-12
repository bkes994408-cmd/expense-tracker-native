# 應用程式內購買（In-App Purchase）整合與測試（MVP-6）

## 範圍
- iOS：導入 StoreKit 2 購買抽象層 `InAppPurchaseService`，支援 trial / 月費 / 年費與 Restore。
- Android：已加入 **Billing adapter/domain 決策層**（`GooglePlayBillingPurchaseService` + `GooglePlayBillingGateway`），負責 plan/productId 映射、restore tier 判定與錯誤語意；目前 `Gateway` 預設為 `UnconfiguredGooglePlayBillingGateway`，待接入真實 Google Play Billing client。
- Paywall UI：購買失敗顯示錯誤訊息、購買成功才關閉 paywall。

## Android 整合深度（現況與下一步）
- 現況：
  - 已完成 `ProPurchaseService` 介面與 entitlement 流程串接。
  - 已新增 `GooglePlayBillingPurchaseService`（plan/productId 映射、restore 時多筆購買取最高 tier）。
  - 測試涵蓋 adapter 的映射與 restore 決策（不依賴 Google Play Billing SDK）。
- 尚未完成：
  - 真實 Google Play Billing client 連線、商品查詢、購買流程與 restore（query purchases）實作（可由 `GooglePlayBillingGateway` 實作銜接）。
- 下一步規劃：
  1. 新增 Google Play Billing adapter 並接到 `ProPurchaseService`。
  2. 在 Internal testing track 搭配 license tester 驗證購買/還原。
  3. 補上 billing 失敗重試、pending transaction 與未知商品處理的整合測試。

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
- `ProEntitlementStoreTest.pendingPurchase_keepsFreeAndStoresPendingError`
- `ProEntitlementStoreTest.unknownProduct_keepsFreeAndStoresError`
- `ProEntitlementStoreTest.restorePurchase_updatesTierFromService`
- `ProEntitlementStoreTest.restoreFailure_keepsCurrentTierAndStoresError`
- `ProEntitlementStoreTest.restoreNil_setsFreeAndClearsError`
- `GooglePlayBillingPurchaseServiceTest.purchase_monthly_mapsToMonthlyTier`
- `GooglePlayBillingPurchaseServiceTest.purchase_unknownProduct_returnsFailure`
- `GooglePlayBillingPurchaseServiceTest.restore_multiplePurchases_returnsHighestTier`
- `GooglePlayBillingPurchaseServiceTest.restore_noPurchase_returnsNullTier`

## Sandbox / QA 建議
1. iOS 使用 StoreKit Configuration 或 Sandbox Apple ID 驗證購買與 Restore。
2. Android 於 Internal testing track 使用 license tester 驗證購買與 Restore。
3. 驗證情境：
   - 付款成功 -> entitlement 從 FREE 轉 PRO
   - 使用者取消 -> entitlement 不變、顯示錯誤
   - Restore 成功 -> entitlement 還原
   - Restore 無歷史購買 -> 維持 FREE

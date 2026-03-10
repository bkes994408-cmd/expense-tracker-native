# 應用程式內購買（In-App Purchase）整合與測試（MVP-6）

## 範圍
- iOS：導入 StoreKit 2 購買抽象層 `InAppPurchaseService`，支援月費 / 年費（含試用入口）與 Restore。
- Android：導入購買抽象層 `ProPurchaseService`（可替換為 Google Play Billing adapter），並將 entitlement 更新流程集中在 `ProEntitlementStore`。
- Paywall UI：購買失敗顯示錯誤訊息、購買成功才關閉 paywall。

## 商品 ID（iOS）
- `com.bkes994408.expensetracker.pro.monthly`
- `com.bkes994408.expensetracker.pro.yearly`

> 實際上線前，請在 App Store Connect 與 Google Play Console 建立對應商品，並確認價格與試用週期一致。

## 測試
### iOS Unit Tests
- `ProEntitlementStoreTests.testSubscribeMonthlyUpdatesTierAndSource`
- `ProEntitlementStoreTests.testPurchaseFailureShowsErrorAndDoesNotUpgrade`
- `ProEntitlementStoreTests.testRestoreSetsTierFromService`

### Android Unit Tests
- `ProEntitlementStoreTest.subscribeMonthly_updatesTier`
- `ProEntitlementStoreTest.purchaseFailure_keepsFreeAndStoresError`
- `ProEntitlementStoreTest.restorePurchase_updatesTierFromService`

## Sandbox / QA 建議
1. iOS 使用 StoreKit Configuration 或 Sandbox Apple ID 驗證購買與 Restore。
2. Android 於 Internal testing track 使用 license tester 驗證購買與 Restore。
3. 驗證情境：
   - 付款成功 -> entitlement 從 FREE 轉 PRO
   - 使用者取消 -> entitlement 不變、顯示錯誤
   - Restore 成功 -> entitlement 還原
   - Restore 無歷史購買 -> 維持 FREE

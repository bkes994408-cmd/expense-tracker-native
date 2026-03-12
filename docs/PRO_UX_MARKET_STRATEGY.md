# Pro 功能用戶體驗優化與市場策略（MVP-6）

日期：2026-03-13

## 本輪交付

1. **情境化 Paywall 文案（Contextual Paywall Copy）**
   - 依觸發來源（預算上限 / 長區間報表 / PDF 匯出）動態調整標題、副標與推薦方案。
   - 降低 generic paywall 帶來的認知落差，提升轉換動機。

2. **CTA 行為事件追蹤**
   - 新增 `pro_paywall_viewed`、`pro_paywall_cta_tapped`（iOS / Android）。
   - 可用於後續漏斗分析：曝光 → 點擊 → 訂閱成功。

3. **推薦方案策略（Plan Recommendation）**
   - 預算與 PDF 場景推薦年付（高長期價值場景）。
   - 趨勢報表場景推薦月付（低門檻試用場景）。

## A/B 測試建議（下一步）

- 實驗 A：維持原始 paywall 文案
- 實驗 B：情境化文案 + 推薦方案
- 主要指標：
  - Paywall CTA CTR
  - Trial start rate
  - 7 日內付費轉換率
- 警戒指標：
  - 退款率
  - 訂閱後 3 日內流失率

## 驗收條件（DoD）

- iOS 與 Android paywall 皆顯示 trigger-aware 文案。
- CTA 皆有統一事件埋點。
- 相關單元測試通過（文案映射邏輯）。

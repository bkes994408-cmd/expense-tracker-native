import Foundation

struct RetentionStrategy: Equatable {
    let headline: String
    let cta: String
    let offerCode: String
}

extension ProEntitlementStore {
    var retentionStrategy: RetentionStrategy? {
        switch tier {
        case .monthly:
            return RetentionStrategy(
                headline: "改用年付，省下 2 個月費用",
                cta: "升級年付方案",
                offerCode: "annual_save_2m"
            )
        case .trial:
            guard let trialExpireAt else {
                return RetentionStrategy(
                    headline: "試用已到期，立即續訂解鎖完整功能",
                    cta: "立即續訂",
                    offerCode: "trial_expired_winback"
                )
            }

            let daysLeft = Int(ceil(trialExpireAt.timeIntervalSince(nowProvider()) / 86_400))
            if daysLeft <= 0 {
                return RetentionStrategy(
                    headline: "你的 Pro 試用已結束，回歸方案享限時折扣",
                    cta: "查看回流優惠",
                    offerCode: "trial_winback_40"
                )
            }

            if daysLeft <= 2 {
                return RetentionStrategy(
                    headline: "試用剩下 \(daysLeft) 天，現在續訂最划算",
                    cta: "續訂並保留所有進階功能",
                    offerCode: "trial_last48h"
                )
            }
            return nil
        case .yearly, .free:
            return nil
        }
    }
}

import Foundation

struct SubscriptionPlan: Identifiable, Equatable {
    let id: Int64
    let name: String
    let amount: Decimal
    let cycleDays: Int
    let nextChargeAt: Date
    let reminderDaysBefore: Int
    let reminderEnabled: Bool

    var reminderText: String {
        guard reminderEnabled else { return "提醒已關閉" }
        return "扣款前 \(reminderDaysBefore) 天提醒"
    }
}

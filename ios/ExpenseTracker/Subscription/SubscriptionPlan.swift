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
        guard reminderEnabled else { return String(localized: "subscription.reminderOff") }
        return String(format: String(localized: "subscription.reminderOn"), locale: Locale.current, reminderDaysBefore)
    }
}

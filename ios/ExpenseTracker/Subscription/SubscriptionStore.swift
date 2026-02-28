import Foundation

protocol SubscriptionStore {
    func fetchAll() throws -> [SubscriptionPlan]
    func add(name: String, amount: Decimal, cycleDays: Int, nextChargeAt: Date, reminderDaysBefore: Int, reminderEnabled: Bool) throws
}

import Foundation

struct InstallmentPlan: Identifiable, Equatable {
    let id: Int64
    let name: String
    let totalPeriods: Int
    let paidPeriods: Int
    let periodAmount: Decimal

    var remainingPeriods: Int { max(totalPeriods - paidPeriods, 0) }
}

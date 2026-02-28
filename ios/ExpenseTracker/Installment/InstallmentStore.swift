import Foundation

protocol InstallmentStore {
    func fetchAll() throws -> [InstallmentPlan]
    func add(name: String, periodAmount: Decimal, totalPeriods: Int, paidPeriods: Int) throws
}

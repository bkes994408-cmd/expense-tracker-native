import Foundation

protocol BudgetStore {
    func fetch(monthKey: String) throws -> [BudgetPlan]
    func upsert(monthKey: String, categoryName: String, amount: Decimal, carryOverMode: CarryOverMode) throws
    func delete(id: Int64) throws
    func copy(from fromMonthKey: String, to toMonthKey: String) throws
}

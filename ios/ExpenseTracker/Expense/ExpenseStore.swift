import Foundation

protocol ExpenseStore {
    func fetchAll(searchText: String?) throws -> [Expense]
    func add(title: String, amount: Decimal, categoryId: Int64?) throws
    func delete(id: Int64) throws
    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview

    // TODO(MVP-1.2): implement update flow in UI and concrete store.
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws
}

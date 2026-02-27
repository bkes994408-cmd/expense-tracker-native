import Foundation

struct Expense: Identifiable, Equatable {
    let id: Int64
    let title: String
    let amount: Decimal
    let createdAt: Date
    let categoryId: Int64?
}

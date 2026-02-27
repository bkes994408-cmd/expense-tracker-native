import Foundation

struct Expense: Identifiable, Equatable {
    let id: UUID
    let title: String
    let amount: Decimal
    let createdAt: Date

    init(id: UUID = UUID(), title: String, amount: Decimal, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.amount = amount
        self.createdAt = createdAt
    }
}

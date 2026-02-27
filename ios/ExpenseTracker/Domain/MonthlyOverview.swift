import Foundation

struct MonthlyOverview: Equatable {
    struct CategoryTotal: Identifiable, Equatable {
        let id: String
        let name: String
        let amount: Decimal
    }

    let month: Date
    let income: Decimal
    let expense: Decimal
    let categoryTotals: [CategoryTotal]

    var net: Decimal { income - expense }

    static func empty(month: Date) -> MonthlyOverview {
        MonthlyOverview(month: month, income: 0, expense: 0, categoryTotals: [])
    }
}

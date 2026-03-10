import Foundation

enum CarryOverMode: String, CaseIterable {
    case none
    case rollover
}

struct BudgetPlan: Identifiable, Equatable {
    let id: Int64
    let monthKey: String
    let categoryName: String
    let amount: Decimal
    let carryOverMode: CarryOverMode
}

struct BudgetProgress: Identifiable, Equatable {
    enum Status: Equatable {
        case healthy
        case warning
        case overspent
    }

    let id: Int64
    let categoryName: String
    let spent: Decimal
    let budget: Decimal

    var remaining: Decimal { budget - spent }
    var ratio: Double {
        guard budget > 0 else { return 0 }
        let spentDouble = NSDecimalNumber(decimal: spent).doubleValue
        let budgetDouble = NSDecimalNumber(decimal: budget).doubleValue
        return max(0, spentDouble / budgetDouble)
    }

    var status: Status {
        if ratio > 1 { return .overspent }
        if ratio >= 0.8 { return .warning }
        return .healthy
    }
}

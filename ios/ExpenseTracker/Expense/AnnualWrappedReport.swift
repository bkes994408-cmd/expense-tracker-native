import Foundation

struct AnnualWrappedReport {
    struct MonthSummary: Identifiable, Equatable {
        let id: String
        let month: Date
        let income: Decimal
        let expense: Decimal
        let net: Decimal
    }

    let year: Int
    let totalIncome: Decimal
    let totalExpense: Decimal
    let totalNet: Decimal
    let savingRate: Decimal
    let topExpenseCategory: MonthlyOverview.CategoryTotal?
    let bestMonth: MonthSummary?
    let toughestMonth: MonthSummary?
    let monthlySummaries: [MonthSummary]
}

final class AnnualWrappedReportBuilder {
    private let store: ExpenseStore
    private let calendar: Calendar

    init(store: ExpenseStore, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
    }

    func build(year: Int) -> AnnualWrappedReport? {
        var summaries: [AnnualWrappedReport.MonthSummary] = []
        var categoryExpenseTotals: [String: Decimal] = [:]

        for month in 1...12 {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let overview = try? store.fetchMonthlyOverview(for: date)
            else { continue }

            summaries.append(
                .init(
                    id: "\(year)-\(month)",
                    month: date,
                    income: overview.income,
                    expense: overview.expense,
                    net: overview.net
                )
            )

            overview.categoryTotals.forEach { item in
                if item.amount < .zero {
                    categoryExpenseTotals[item.name, default: .zero] += -item.amount
                }
            }
        }

        guard !summaries.isEmpty else { return nil }

        let totalIncome = summaries.reduce(Decimal.zero) { $0 + $1.income }
        let totalExpense = summaries.reduce(Decimal.zero) { $0 + $1.expense }
        let totalNet = summaries.reduce(Decimal.zero) { $0 + $1.net }

        let savingRate: Decimal
        if totalIncome == .zero {
            savingRate = .zero
        } else {
            savingRate = (totalNet / totalIncome) * 100
        }

        let topExpenseCategory = categoryExpenseTotals
            .max(by: { $0.value < $1.value })
            .map { MonthlyOverview.CategoryTotal(id: $0.key, name: $0.key, amount: -$0.value) }

        let bestMonth = summaries.max(by: { $0.net < $1.net })
        let toughestMonth = summaries.min(by: { $0.net < $1.net })

        return AnnualWrappedReport(
            year: year,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            totalNet: totalNet,
            savingRate: savingRate,
            topExpenseCategory: topExpenseCategory,
            bestMonth: bestMonth,
            toughestMonth: toughestMonth,
            monthlySummaries: summaries
        )
    }
}

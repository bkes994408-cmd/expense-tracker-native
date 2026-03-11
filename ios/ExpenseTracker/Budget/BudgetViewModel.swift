import Foundation

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published private(set) var month: Date
    @Published private(set) var progressItems: [BudgetProgress] = []
    @Published private(set) var expenseCategories: [String] = []

    @Published var selectedCategoryName: String = ""
    @Published var amountText: String = ""
    @Published var carryOverMode: CarryOverMode = .none
    @Published var errorMessage: String?

    private let budgetStore: BudgetStore
    private let expenseStore: ExpenseStore

    init(budgetStore: BudgetStore, expenseStore: ExpenseStore, month: Date = Date()) {
        self.budgetStore = budgetStore
        self.expenseStore = expenseStore
        self.month = month
        reload()
    }

    func refresh() {
        reload()
    }

    var monthKey: String { Self.monthFormatter.string(from: month) }
    var activeBudgetCount: Int { progressItems.count }

    func hasBudget(for categoryName: String) -> Bool {
        progressItems.contains(where: { $0.categoryName == categoryName })
    }

    func saveBudget() {
        errorMessage = nil
        let trimmedCategory = selectedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else {
            errorMessage = "請先選擇分類"
            return
        }
        guard let amount = Decimal(string: amountText), amount > 0 else {
            errorMessage = "預算金額需大於 0"
            return
        }

        do {
            try budgetStore.upsert(monthKey: monthKey, categoryName: trimmedCategory, amount: amount, carryOverMode: carryOverMode)
            amountText = ""
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteBudget(_ item: BudgetProgress) {
        do {
            try budgetStore.delete(id: item.id)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    enum CopyLastMonthResult: Equatable {
        case copied
        case requiresProUpgrade
        case failed
    }

    func copyLastMonth(isPro: Bool = true) -> CopyLastMonthResult {
        guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: month) else {
            return .failed
        }
        do {
            let previousMonthKey = Self.monthFormatter.string(from: previousMonth)
            let previousPlans = try budgetStore.fetch(monthKey: previousMonthKey)
            let currentPlans = try budgetStore.fetch(monthKey: monthKey)

            let wouldExceedFreeLimit = Self.requiresProUpgradeForCopy(
                isPro: isPro,
                currentMonthCategories: currentPlans.map(\.categoryName),
                copiedCategories: previousPlans.map(\.categoryName)
            )
            if wouldExceedFreeLimit {
                return .requiresProUpgrade
            }

            try budgetStore.copy(from: previousMonthKey, to: monthKey)
            reload()
            return .copied
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }
    }

    private func reload() {
        do {
            let plans = try budgetStore.fetch(monthKey: monthKey)
            let overview = try expenseStore.fetchMonthlyOverview(for: month)
            let spendingMap = Dictionary(uniqueKeysWithValues: overview.categoryTotals.map {
                ($0.name, max(0, -$0.amount))
            })

            expenseCategories = overview.categoryTotals
                .filter { $0.amount < 0 }
                .map(\.name)
                .sorted()

            if selectedCategoryName.isEmpty {
                selectedCategoryName = expenseCategories.first ?? ""
            }

            progressItems = plans.map { plan in
                BudgetProgress(
                    id: plan.id,
                    categoryName: plan.categoryName,
                    spent: spendingMap[plan.categoryName] ?? 0,
                    budget: plan.amount
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func requiresProUpgradeForCopy(
        isPro: Bool,
        currentMonthCategories: [String],
        copiedCategories: [String],
        freeCategoryLimit: Int = 2
    ) -> Bool {
        guard !isPro else { return false }
        let existing = Set(currentMonthCategories)
        let copied = Set(copiedCategories)
        return existing.union(copied).count > freeCategoryLimit
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}

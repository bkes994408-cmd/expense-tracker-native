import Foundation

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var monthlyOverview: MonthlyOverview = .empty(month: Date())
    @Published var newTitle = ""
    @Published var newAmount = ""
    @Published var isIncome = false
    @Published var searchText = "" {
        didSet { reload() }
    }

    private let store: ExpenseStore

    init(store: ExpenseStore) {
        self.store = store
        reload()
    }

    func reload() {
        expenses = (try? store.fetchAll(searchText: searchText)) ?? []
        monthlyOverview = (try? store.fetchMonthlyOverview(for: Date())) ?? .empty(month: Date())
    }

    func addExpense() {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let rawAmount = Decimal(string: newAmount), rawAmount > 0 else { return }

        let signedAmount = isIncome ? rawAmount : -rawAmount

        do {
            try store.add(title: trimmedTitle, amount: signedAmount, categoryId: nil)
            newTitle = ""
            newAmount = ""
            reload()
        } catch {
            // TODO(MVP-1.2): show user-facing error message.
        }
    }

    func deleteExpenses(at offsets: IndexSet) {
        for offset in offsets {
            let id = expenses[offset].id
            try? store.delete(id: id)
        }
        reload()
    }
}

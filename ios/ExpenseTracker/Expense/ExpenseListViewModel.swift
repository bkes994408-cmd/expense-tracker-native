import Foundation

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var newTitle = ""
    @Published var newAmount = ""
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
    }

    func addExpense() {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let amount = Decimal(string: newAmount), amount > 0 else { return }

        do {
            try store.add(title: trimmedTitle, amount: amount, categoryId: nil)
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

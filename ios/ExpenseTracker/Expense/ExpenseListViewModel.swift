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
        guard !trimmedTitle.isEmpty, let rawAmount = Decimal(string: newAmount), rawAmount > 0 else {
            Telemetry.shared.track(.expenseAddInvalid)
            return
        }

        let signedAmount = isIncome ? rawAmount : -rawAmount

        do {
            try store.add(title: trimmedTitle, amount: signedAmount, categoryId: nil)
            Telemetry.shared.track(.expenseAdded, metadata: ["type": isIncome ? "income" : "expense"])
            newTitle = ""
            newAmount = ""
            reload()
        } catch {
            Telemetry.shared.record(error: error, metadata: ["operation": "add_expense"])
            // TODO(MVP-1.2): show user-facing error message.
        }
    }

    func deleteExpenses(at offsets: IndexSet) {
        for offset in offsets {
            let id = expenses[offset].id
            do {
                try store.delete(id: id)
                Telemetry.shared.track(.expenseDeleted)
            } catch {
                Telemetry.shared.record(error: error, metadata: ["operation": "delete_expense", "expense_id": "\(id)"])
            }
        }
        reload()
    }

    func exportCSV() -> (filename: String, content: String)? {
        guard let all = try? store.fetchAll(searchText: nil), !all.isEmpty else { return nil }

        let formatter = ISO8601DateFormatter()
        let header = "id,title,amount,createdAt,categoryId"
        let rows = all.map { expense in
            let title = Self.csvEscaped(expense.title)
            let amount = NSDecimalNumber(decimal: expense.amount).stringValue
            let createdAt = formatter.string(from: expense.createdAt)
            let categoryId = expense.categoryId.map(String.init) ?? ""
            return "\(expense.id),\(title),\(amount),\(createdAt),\(categoryId)"
        }

        let filename = "expenses-\(Self.fileTimestamp()).csv"
        return (filename, ([header] + rows).joined(separator: "\n"))
    }

    private static func csvEscaped(_ raw: String) -> String {
        var escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

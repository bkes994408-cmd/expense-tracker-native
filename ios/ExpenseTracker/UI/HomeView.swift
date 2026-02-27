import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: ExpenseListViewModel
    let onOpenSettings: () -> Void

    init(store: ExpenseStore, onOpenSettings: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(store: store))
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        List {
            Section("新增帳目") {
                TextField("標題（例如：晚餐）", text: $viewModel.newTitle)
                TextField("金額", text: $viewModel.newAmount)
                    .keyboardType(.decimalPad)
                Button("新增") { viewModel.addExpense() }
            }

            Section("帳目列表") {
                if viewModel.expenses.isEmpty {
                    Text("目前沒有資料")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.expenses) { expense in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                            Text(expense.amount.formatted())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: viewModel.deleteExpenses)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜尋標題")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("設定", action: onOpenSettings)
            }
        }
        .navigationTitle("Expense Tracker")
    }
}

#Preview {
    NavigationStack {
        HomeView(store: PreviewExpenseStore(), onOpenSettings: {})
    }
}

private final class PreviewExpenseStore: ExpenseStore {
    func fetchAll(searchText: String?) throws -> [Expense] {
        [
            Expense(id: 1, title: "Lunch", amount: 120, createdAt: Date(), categoryId: nil),
            Expense(id: 2, title: "MRT", amount: 35, createdAt: Date(), categoryId: nil),
        ]
    }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {}
    func delete(id: Int64) throws {}
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

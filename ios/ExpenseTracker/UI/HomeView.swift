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
            Section("每月總覽") {
                LabeledContent("收入", value: viewModel.monthlyOverview.income.formatted())
                LabeledContent("支出", value: viewModel.monthlyOverview.expense.formatted())
                LabeledContent("淨額", value: viewModel.monthlyOverview.net.formatted())

                if viewModel.monthlyOverview.categoryTotals.isEmpty {
                    Text("本月尚無分類彙總")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.monthlyOverview.categoryTotals) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.amount.formatted())
                                .foregroundStyle(item.amount < 0 ? .red : .green)
                        }
                        .font(.caption)
                    }
                }
            }

            Section("新增帳目") {
                TextField("標題（例如：晚餐）", text: $viewModel.newTitle)
                TextField("金額", text: $viewModel.newAmount)
                    .keyboardType(.decimalPad)
                Picker("類型", selection: $viewModel.isIncome) {
                    Text("支出").tag(false)
                    Text("收入").tag(true)
                }
                .pickerStyle(.segmented)
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
                                .foregroundStyle(expense.amount < 0 ? .red : .green)
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
            Expense(id: 1, title: "Lunch", amount: -120, createdAt: Date(), categoryId: nil),
            Expense(id: 2, title: "Freelance", amount: 3500, createdAt: Date(), categoryId: nil),
        ]
    }

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        MonthlyOverview(
            month: month,
            income: 3500,
            expense: 120,
            categoryTotals: [
                .init(id: "未分類", name: "未分類", amount: 3380)
            ]
        )
    }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {}
    func delete(id: Int64) throws {}
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: ExpenseListViewModel
    @ObservedObject var proEntitlementStore: ProEntitlementStore
    let onOpenSettings: () -> Void

    @State private var paywallTrigger: String = ""
    @State private var isPaywallPresented = false

    init(store: ExpenseStore, proEntitlementStore: ProEntitlementStore, onOpenSettings: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(store: store))
        self.proEntitlementStore = proEntitlementStore
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

            Section("Pro 功能") {
                LabeledContent("方案狀態", value: proEntitlementStore.isPro ? "Pro（\(proEntitlementStore.tier.rawValue)）" : "Free")
                    .font(.caption)

                Button("建立第 3 個分類預算（示範）") {
                    openProFeature(trigger: "budget_limit")
                }

                Button("查看 3 個月以上趨勢圖（示範）") {
                    openProFeature(trigger: "advanced_report_3m")
                }

                Button("匯出 PDF 報表（示範）") {
                    openProFeature(trigger: "report_pdf_export")
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
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(trigger: paywallTrigger, entitlementStore: proEntitlementStore) {
                isPaywallPresented = false
            }
        }
        .navigationTitle("Expense Tracker")
    }

    private func openProFeature(trigger: String) {
        if !proEntitlementStore.isPro {
            paywallTrigger = trigger
            isPaywallPresented = true
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(store: PreviewExpenseStore(), proEntitlementStore: ProEntitlementStore(), onOpenSettings: {})
    }
}

struct PaywallView: View {
    let trigger: String
    @ObservedObject var entitlementStore: ProEntitlementStore
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("升級 Pro，解鎖進階理財能力")
                    .font(.title3.bold())

                Text("觸發來源：\(trigger)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("可建立不限數量分類預算", systemImage: "checkmark.circle.fill")
                    Label("可查看 3/6/12 個月趨勢圖", systemImage: "chart.xyaxis.line")
                    Label("可匯出 PDF 進階報表", systemImage: "doc.richtext")
                }
                .font(.subheadline)

                VStack(spacing: 10) {
                    Button("開始 7 天免費試用（年付）") {
                        entitlementStore.startTrial()
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("月付 NT$90") {
                        entitlementStore.subscribeMonthly()
                        onDismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("年付 NT$790") {
                        entitlementStore.subscribeYearly()
                        onDismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("恢復購買") {
                        entitlementStore.restorePurchase()
                        onDismiss()
                    }
                    .font(.footnote)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉", action: onDismiss)
                }
            }
        }
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

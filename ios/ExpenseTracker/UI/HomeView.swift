import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: ExpenseListViewModel
    @StateObject private var budgetViewModel: BudgetViewModel
    @ObservedObject var proEntitlementStore: ProEntitlementStore
    let onOpenSettings: () -> Void

    @State private var paywallTrigger: String = ""
    @State private var isPaywallPresented = false

    init(
        store: ExpenseStore,
        budgetStore: BudgetStore,
        proEntitlementStore: ProEntitlementStore,
        onOpenSettings: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(store: store))
        _budgetViewModel = StateObject(wrappedValue: BudgetViewModel(budgetStore: budgetStore, expenseStore: store))
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

            Section("Pro 預算系統") {
                LabeledContent("方案狀態", value: proEntitlementStore.isPro ? "Pro（\(proEntitlementStore.tier.rawValue)）" : "Free")
                    .font(.caption)

                if let errorMessage = budgetViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if budgetViewModel.expenseCategories.isEmpty {
                    Text("先建立支出帳目後即可設定分類預算")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("分類", selection: $budgetViewModel.selectedCategoryName) {
                        ForEach(budgetViewModel.expenseCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("預算金額", text: $budgetViewModel.amountText)
                        .keyboardType(.decimalPad)

                    Picker("結轉模式", selection: $budgetViewModel.carryOverMode) {
                        Text("不結轉").tag(CarryOverMode.none)
                        if proEntitlementStore.isPro {
                            Text("可結轉").tag(CarryOverMode.rollover)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("儲存本月分類預算") {
                        let addingNewCategory = !budgetViewModel.hasBudget(for: budgetViewModel.selectedCategoryName)
                        if !proEntitlementStore.isPro && addingNewCategory && budgetViewModel.activeBudgetCount >= 2 {
                            openProFeature(trigger: "budget_limit")
                            return
                        }
                        budgetViewModel.saveBudget()
                    }

                    Button("快速複製上月預算") {
                        let result = budgetViewModel.copyLastMonth(isPro: proEntitlementStore.isPro)
                        if result == .requiresProUpgrade {
                            openProFeature(trigger: "budget_limit_copy_last_month")
                        }
                    }
                    .font(.footnote)
                }

                if budgetViewModel.progressItems.isEmpty {
                    Text("本月尚未設定預算")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(budgetViewModel.progressItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.categoryName)
                                Spacer()
                                Text("剩餘 \(item.remaining.formatted())")
                                    .foregroundStyle(item.remaining < 0 ? .red : .secondary)
                            }

                            ProgressView(value: min(item.ratio, 1.2), total: 1.0)
                                .tint(progressColor(item.status))

                            Text("已花費 \(item.spent.formatted()) / 預算 \(item.budget.formatted())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { budgetViewModel.progressItems[$0] }.forEach(budgetViewModel.deleteBudget)
                    }
                }
            }

            Section("Pro 功能") {
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
                Button("新增") {
                    viewModel.addExpense()
                    budgetViewModel.refresh()
                }
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

    private func progressColor(_ status: BudgetProgress.Status) -> Color {
        switch status {
        case .healthy: return .green
        case .warning: return .orange
        case .overspent: return .red
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(
            store: PreviewExpenseStore(),
            budgetStore: PreviewBudgetStore(),
            proEntitlementStore: ProEntitlementStore(),
            onOpenSettings: {}
        )
    }
}

@MainActor
struct PaywallView: View {
    let trigger: String
    @ObservedObject private var entitlementStore: ProEntitlementStore
    let onDismiss: () -> Void

    init(trigger: String, entitlementStore: ProEntitlementStore, onDismiss: @escaping () -> Void) {
        self.trigger = trigger
        self._entitlementStore = ObservedObject(wrappedValue: entitlementStore)
        self.onDismiss = onDismiss
    }

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

                if let errorMessage = entitlementStore.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                VStack(spacing: 10) {
                    Button("開始 7 天免費試用（年付）") {
                        Task {
                            await entitlementStore.startTrial()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(entitlementStore.isProcessing)

                    Button("月付 NT$90") {
                        Task {
                            await entitlementStore.subscribeMonthly()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(entitlementStore.isProcessing)

                    Button("年付 NT$790") {
                        Task {
                            await entitlementStore.subscribeYearly()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(entitlementStore.isProcessing)

                    Button("恢復購買") {
                        Task {
                            await entitlementStore.restorePurchase()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .font(.footnote)
                    .disabled(entitlementStore.isProcessing)
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
                .init(id: "餐飲", name: "餐飲", amount: -120),
                .init(id: "未分類", name: "未分類", amount: 3380)
            ]
        )
    }

    func add(title: String, amount: Decimal, categoryId: Int64?) throws {}
    func delete(id: Int64) throws {}
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

private final class PreviewBudgetStore: BudgetStore {
    func fetch(monthKey: String) throws -> [BudgetPlan] {
        [BudgetPlan(id: 1, monthKey: monthKey, categoryName: "餐飲", amount: 3000, carryOverMode: .none)]
    }

    func upsert(monthKey: String, categoryName: String, amount: Decimal, carryOverMode: CarryOverMode) throws {}
    func delete(id: Int64) throws {}
    func copy(from fromMonthKey: String, to toMonthKey: String) throws {}
}

import SwiftUI

struct SettingsView: View {
    @StateObject private var categoryViewModel: CategoryManagementViewModel
    @StateObject private var subscriptionViewModel: SubscriptionManagementViewModel
    @StateObject private var installmentViewModel: InstallmentManagementViewModel
    @ObservedObject var proEntitlementStore: ProEntitlementStore
    private let expenseStore: ExpenseStore

    @State private var exportedCSVURL: URL?
    @State private var exportStatusMessage: String?

    init(
        categoryStore: CategoryStore,
        subscriptionStore: SubscriptionStore,
        installmentStore: InstallmentStore,
        expenseStore: ExpenseStore,
        proEntitlementStore: ProEntitlementStore
    ) {
        _categoryViewModel = StateObject(wrappedValue: CategoryManagementViewModel(store: categoryStore))
        _subscriptionViewModel = StateObject(wrappedValue: SubscriptionManagementViewModel(store: subscriptionStore))
        _installmentViewModel = StateObject(wrappedValue: InstallmentManagementViewModel(store: installmentStore))
        self.expenseStore = expenseStore
        self.proEntitlementStore = proEntitlementStore
    }

    var body: some View {
        List {
            Section("Pro") {
                LabeledContent("目前方案", value: proEntitlementStore.statusText)
                if proEntitlementStore.isPro {
                    Text("已解鎖 Pro 功能")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("重設為 Free（Debug）") {
                        proEntitlementStore.resetToFreeForDebug()
                    }
                } else {
                    Text("尚未解鎖，將在高意圖操作時顯示付費牆")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Category Management") {
                HStack {
                    TextField("New category", text: $categoryViewModel.newCategoryName)
                    Button("Add") { categoryViewModel.addCategory() }
                }

                ForEach(categoryViewModel.categories) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                        Button("Archive") {
                            categoryViewModel.archive(category.id)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove(perform: categoryViewModel.move)
            }

            Section("訂閱管理") {
                TextField("名稱", text: $subscriptionViewModel.newName)
                TextField("金額", text: $subscriptionViewModel.newAmount)
                    .keyboardType(.decimalPad)
                TextField("週期（天）", text: $subscriptionViewModel.cycleDays)
                    .keyboardType(.numberPad)
                DatePicker("下次扣款", selection: $subscriptionViewModel.nextChargeAt, displayedComponents: .date)
                Toggle("啟用提醒", isOn: $subscriptionViewModel.reminderEnabled)
                TextField("提前提醒天數", text: $subscriptionViewModel.reminderDaysBefore)
                    .keyboardType(.numberPad)
                Button("新增訂閱") { subscriptionViewModel.addPlan() }

                ForEach(subscriptionViewModel.plans) { plan in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(plan.name) · \(plan.amount.formatted())")
                        Text("每 \(plan.cycleDays) 天，下一次：\(plan.nextChargeAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(plan.reminderText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("分期管理") {
                TextField("名稱", text: $installmentViewModel.newName)
                TextField("每期金額", text: $installmentViewModel.periodAmount)
                    .keyboardType(.decimalPad)
                TextField("總期數", text: $installmentViewModel.totalPeriods)
                    .keyboardType(.numberPad)
                TextField("已繳期數", text: $installmentViewModel.paidPeriods)
                    .keyboardType(.numberPad)
                Button("新增分期") { installmentViewModel.addPlan() }

                ForEach(installmentViewModel.plans) { plan in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(plan.name) · 每期 \(plan.periodAmount.formatted())")
                        Text("已繳 \(plan.paidPeriods) / \(plan.totalPeriods) 期，剩餘 \(plan.remainingPeriods) 期")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Export") {
                Button("匯出 CSV") {
                    exportCSV()
                }

                if let exportedCSVURL {
                    ShareLink(item: exportedCSVURL) {
                        Label("分享最近匯出檔", systemImage: "square.and.arrow.up")
                    }
                    Text(exportedCSVURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let exportStatusMessage {
                    Text(exportStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "0.0.1")
            }
        }
        .toolbar { EditButton() }
        .navigationTitle("Settings")
    }

    private func exportCSV() {
        do {
            let expenses = try expenseStore.fetchAll(searchText: nil)
            let header = "id,title,amount,createdAt,categoryId"
            let rows = expenses.map { expense in
                let title = expense.title.replacingOccurrences(of: "\"", with: "\"\"")
                let category = expense.categoryId.map(String.init) ?? ""
                return "\(expense.id),\"\(title)\",\(expense.amount),\(expense.createdAt.ISO8601Format()),\(category)"
            }
            let csv = ([header] + rows).joined(separator: "\n")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("expenses-\(Int(Date().timeIntervalSince1970)).csv")
            guard let data = csv.data(using: .utf8) else {
                throw NSError(domain: "SettingsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "CSV encoding failed"])
            }
            try data.write(to: url)
            exportedCSVURL = url
            exportStatusMessage = "已匯出 \(expenses.count) 筆資料"
            Telemetry.shared.track(.csvExported, metadata: ["count": "\(expenses.count)"])
        } catch {
            exportStatusMessage = "匯出失敗：\(error.localizedDescription)"
            Telemetry.shared.track(.csvExportFailed)
            Telemetry.shared.record(error: error, metadata: ["operation": "export_csv"])
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            categoryStore: PreviewCategoryStore(),
            subscriptionStore: PreviewSubscriptionStore(),
            installmentStore: PreviewInstallmentStore(),
            expenseStore: PreviewExpenseStore(),
            proEntitlementStore: ProEntitlementStore()
        )
    }
}

private final class PreviewCategoryStore: CategoryStore {
    private var items: [Category] = [
        Category(id: 1, name: "Food", isArchived: false, sortOrder: 0),
        Category(id: 2, name: "Transport", isArchived: false, sortOrder: 1),
    ]

    func fetchActive() throws -> [Category] { items.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder } }
    func add(name: String) throws {}
    func archive(id: Int64) throws {}
    func move(from: Int, to: Int) throws {}
}

private final class PreviewSubscriptionStore: SubscriptionStore {
    func fetchAll() throws -> [SubscriptionPlan] {
        [
            SubscriptionPlan(id: 1, name: "Netflix", amount: 390, cycleDays: 30, nextChargeAt: Date(), reminderDaysBefore: 1, reminderEnabled: true)
        ]
    }

    func add(name: String, amount: Decimal, cycleDays: Int, nextChargeAt: Date, reminderDaysBefore: Int, reminderEnabled: Bool) throws {}
}

private final class PreviewInstallmentStore: InstallmentStore {
    func fetchAll() throws -> [InstallmentPlan] {
        [InstallmentPlan(id: 1, name: "iPhone", totalPeriods: 24, paidPeriods: 8, periodAmount: 1300)]
    }

    func add(name: String, periodAmount: Decimal, totalPeriods: Int, paidPeriods: Int) throws {}
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
    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview { .empty(month: month) }
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

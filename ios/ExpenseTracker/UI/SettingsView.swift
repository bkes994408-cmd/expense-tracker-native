import SwiftUI

struct SettingsView: View {
    @StateObject private var categoryViewModel: CategoryManagementViewModel
    @StateObject private var subscriptionViewModel: SubscriptionManagementViewModel
    @StateObject private var installmentViewModel: InstallmentManagementViewModel

    init(categoryStore: CategoryStore, subscriptionStore: SubscriptionStore, installmentStore: InstallmentStore) {
        _categoryViewModel = StateObject(wrappedValue: CategoryManagementViewModel(store: categoryStore))
        _subscriptionViewModel = StateObject(wrappedValue: SubscriptionManagementViewModel(store: subscriptionStore))
        _installmentViewModel = StateObject(wrappedValue: InstallmentManagementViewModel(store: installmentStore))
    }

    var body: some View {
        List {
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

            Section("About") {
                LabeledContent("Version", value: "0.0.1")
            }
        }
        .toolbar { EditButton() }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            categoryStore: PreviewCategoryStore(),
            subscriptionStore: PreviewSubscriptionStore(),
            installmentStore: PreviewInstallmentStore()
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

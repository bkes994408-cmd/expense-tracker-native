import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var categoryViewModel: CategoryManagementViewModel
    @StateObject private var subscriptionViewModel: SubscriptionManagementViewModel
    @StateObject private var installmentViewModel: InstallmentManagementViewModel
    @ObservedObject var proEntitlementStore: ProEntitlementStore
    private let expenseStore: ExpenseStore

    @State private var exportedCSVURL: URL?
    @State private var exportStatusMessage: String?
    @State private var importStatusMessage: String?
    @State private var isFileImporterPresented = false
    @State private var isImportWizardPresented = false
    @State private var importFileName = ""
    @State private var importFileContent = ""
    @State private var importFormat: ExpenseImportExportService.ImportFormat = .csv
    @State private var csvHeaders: [String] = []
    @State private var csvRows: [[String]] = []
    @State private var csvMapping: ExpenseImportExportService.CSVColumnMapping = .empty
    @State private var mergeSuggestions: [ExpenseImportExportService.DuplicateMergeSuggestion] = []
    @State private var syncLoading = false
    @State private var notificationEnabled = true

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
            Section("Settings / Pro") {
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
                ReplicaStateBox(title: "Loading", message: syncLoading ? "同步設定中..." : "設定同步已完成")
            }

            Section("Settings / Category Management") {
                HStack {
                    TextField("New category", text: $categoryViewModel.newCategoryName)
                    Button("Add") { categoryViewModel.addCategory() }
                }

                ForEach(categoryViewModel.categories) { category in
                    HStack {
                        ReplicaListRow(title: category.name, subtitle: "分類設定", trailing: nil)
                        Button("Archive") {
                            categoryViewModel.archive(category.id)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove(perform: categoryViewModel.move)

                if categoryViewModel.categories.isEmpty {
                    ReplicaStateBox(title: "Empty", message: "尚無分類，請先新增分類。")
                }
            }

            Section("Transaction / Recurring（訂閱管理）") {
                TextField("名稱", text: $subscriptionViewModel.newName)
                TextField("金額", text: $subscriptionViewModel.newAmount)
                    .keyboardType(.decimalPad)
                TextField("週期（天）", text: $subscriptionViewModel.cycleDays)
                    .keyboardType(.numberPad)
                DatePicker("下次扣款", selection: $subscriptionViewModel.nextChargeAt, displayedComponents: .date)
                Toggle("啟用提醒", isOn: $subscriptionViewModel.reminderEnabled)
                Toggle("推播通知", isOn: $notificationEnabled)
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

            Section("Transaction / Recurring（分期管理）") {
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

            Section("Report / Budget + Settings（Export / Import）") {
                Button("匯出 CSV") {
                    exportCSV()
                }

                Button("匯入 CSV / OFX / QIF") {
                    isFileImporterPresented = true
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

                if let importStatusMessage {
                    Text(importStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Settings / About") {
                LabeledContent("Version", value: "0.0.1")
                ReplicaEdgeStates(
                    loadingMessage: "同步設定中，請稍候...",
                    emptyMessage: "目前尚無偏好變更紀錄。",
                    errorMessage: "匯入資料解析失敗，請確認欄位與分隔符。",
                    longTextMessage: "這是一段較長的設定說明文字，用於驗證 iOS 與 Android 在 cell 間距、字級與換行策略的一致性。",
                    denseContentHint: "在大量設定項同時出現時，優先顯示狀態與操作按鈕。"
                )
            }
        }
        .toolbar { EditButton() }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.commaSeparatedText, .plainText, .json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $isImportWizardPresented) {
            importWizardView
        }
    }

    @ViewBuilder
    private var importWizardView: some View {
        NavigationStack {
            List {
                Section("檔案") {
                    LabeledContent("檔名", value: importFileName)
                    LabeledContent("格式", value: importFormat.rawValue.uppercased())
                }

                if importFormat == .csv {
                    Section("欄位映射") {
                        mappingPicker(title: "標題", field: .title)
                        mappingPicker(title: "金額", field: .amount)
                        mappingPicker(title: "日期", field: .createdAt)
                        mappingPicker(title: "分類 ID（可選）", field: .categoryId)
                    }

                    Section("資料預覽（前 5 筆）") {
                        ForEach(Array(csvRows.prefix(5).enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row[safe: csvMapping.titleIndex ?? -1] ?? "(無標題)")
                                Text("金額: \(row[safe: csvMapping.amountIndex ?? -1] ?? "-") · 日期: \(row[safe: csvMapping.createdAtIndex ?? -1] ?? "-")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !mergeSuggestions.isEmpty {
                    Section("重複交易合併建議") {
                        ForEach($mergeSuggestions) { $suggestion in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(suggestion.incoming.title) ↔︎ \(suggestion.existing.title)")
                                Text("相似度 \(NSDecimalNumber(decimal: suggestion.similarityScore).stringValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("處理方式", selection: $suggestion.recommendedAction) {
                                    ForEach(ExpenseImportExportService.DuplicateMergeSuggestion.MergeAction.allCases) { action in
                                        Text(action.label).tag(action)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
            }
            .navigationTitle("匯入精靈")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isImportWizardPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("開始匯入") { executeImport() }
                }
            }
        }
    }

    private func mappingPicker(title: String, field: ExpenseImportExportService.CSVColumnMapping.Field) -> some View {
        Picker(title, selection: Binding(
            get: { csvMapping[field] ?? -1 },
            set: { csvMapping[field] = $0 < 0 ? nil : $0 }
        )) {
            Text("未指定").tag(-1)
            ForEach(Array(csvHeaders.enumerated()), id: \.offset) { index, header in
                Text(header).tag(index)
            }
        }
        .pickerStyle(.menu)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let url = try result.get().first
            guard let url else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
            }

            let content = try String(contentsOf: url, encoding: .utf8)
            importFileName = url.lastPathComponent
            importFileContent = content
            importFormat = ExpenseImportExportService.detectImportFormat(fileName: url.lastPathComponent)

            if importFormat == .csv {
                let preview = ExpenseImportExportService.parseCSVPreview(content)
                csvHeaders = preview.headers
                csvRows = preview.rows
                csvMapping = ExpenseImportExportService.inferCSVMapping(headers: preview.headers)
            }

            let rows = ExpenseImportExportService.parseImportContent(content, format: importFormat, csvMapping: csvMapping)
            let existing = (try? expenseStore.fetchAll(searchText: nil)) ?? []
            mergeSuggestions = ExpenseImportExportService.duplicateSuggestions(rows: rows, existing: existing)
            isImportWizardPresented = true
        } catch {
            importStatusMessage = "匯入讀檔失敗：\(error.localizedDescription)"
            Telemetry.shared.record(error: error, metadata: ["operation": "import_read_file"])
        }
    }

    private func executeImport() {
        do {
            let rows = ExpenseImportExportService.parseImportContent(importFileContent, format: importFormat, csvMapping: csvMapping)
            let result = try ExpenseImportExportService.importRows(rows, to: expenseStore, mergeSuggestions: mergeSuggestions)
            importStatusMessage = "匯入完成：新增 \(result.importedCount) 筆，略過 \(result.skippedCount) 筆，重複 \(result.duplicateCount) 筆"
            isImportWizardPresented = false
        } catch {
            importStatusMessage = "匯入失敗：\(error.localizedDescription)"
            Telemetry.shared.record(error: error, metadata: ["operation": "import_execute"])
        }
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
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

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {}
    func delete(id: Int64) throws {}
    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview { .empty(month: month) }
    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

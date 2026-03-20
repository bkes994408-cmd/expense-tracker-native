import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel: ExpenseListViewModel
    @StateObject private var budgetViewModel: BudgetViewModel
    @StateObject private var reportViewModel: AdvancedReportViewModel
    @StateObject private var groupLedgerViewModel: GroupLedgerViewModel
    @ObservedObject var proEntitlementStore: ProEntitlementStore
    let onOpenSettings: () -> Void

    @State private var paywallTrigger: String = ""
    @State private var isPaywallPresented = false
    @State private var annualWrapped: AnnualWrappedReport?
    @State private var snapshotPayload: String = ""
    @State private var snapshotMessage: String?

    private let expenseStore: ExpenseStore

    init(
        store: ExpenseStore,
        budgetStore: BudgetStore,
        groupLedgerStore: GroupLedgerStore,
        categoryStore: CategoryStore? = nil,
        proEntitlementStore: ProEntitlementStore,
        onOpenSettings: @escaping () -> Void
    ) {
        self.expenseStore = store
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(store: store, categoryStore: categoryStore))
        _budgetViewModel = StateObject(wrappedValue: BudgetViewModel(budgetStore: budgetStore, expenseStore: store))
        _reportViewModel = StateObject(wrappedValue: AdvancedReportViewModel(expenseStore: store, proEntitlementStore: proEntitlementStore))
        _groupLedgerViewModel = StateObject(wrappedValue: GroupLedgerViewModel(store: groupLedgerStore))
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

            Section("家庭/群組帳本") {
                if let errorMessage = groupLedgerViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                HStack {
                    TextField("新帳本名稱（例如：家庭）", text: $groupLedgerViewModel.newLedgerName)
                    Button("建立") { groupLedgerViewModel.createLedger() }
                }

                if groupLedgerViewModel.ledgers.isEmpty {
                    Text("尚未建立群組帳本")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("帳本", selection: Binding(
                        get: { groupLedgerViewModel.selectedLedgerId ?? 0 },
                        set: {
                            groupLedgerViewModel.selectedLedgerId = $0
                            groupLedgerViewModel.refreshOverview()
                        }
                    )) {
                        ForEach(groupLedgerViewModel.ledgers) { ledger in
                            Text(ledger.name).tag(ledger.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let overview = groupLedgerViewModel.overview {
                        HStack {
                            TextField("新增成員", text: $groupLedgerViewModel.newMemberName)
                            Button("加入") { groupLedgerViewModel.addMember() }
                        }

                        if overview.members.isEmpty {
                            Text("至少加入 1 位成員才能共享記帳")
                                .foregroundStyle(.secondary)
                        } else {
                            Group {
                                TextField("共享支出標題", text: $groupLedgerViewModel.expenseTitle)
                                TextField("共享支出金額", text: $groupLedgerViewModel.expenseAmount)
                                    .keyboardType(.decimalPad)

                                Picker("由誰付款", selection: Binding(
                                    get: { groupLedgerViewModel.selectedPayerId ?? overview.members.first?.id ?? 0 },
                                    set: { groupLedgerViewModel.selectedPayerId = $0 }
                                )) {
                                    ForEach(overview.members) { member in
                                        Text(member.name).tag(member.id)
                                    }
                                }
                                .pickerStyle(.menu)

                                Picker("分攤規則", selection: $groupLedgerViewModel.splitRuleMode) {
                                    ForEach(SplitRuleMode.allCases) { mode in
                                        Text(mode.label).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: groupLedgerViewModel.splitRuleMode) { mode in
                                    groupLedgerViewModel.setSplitRuleMode(mode)
                                }

                                if groupLedgerViewModel.splitRuleMode != .equal {
                                    ForEach(overview.members) { member in
                                        TextField(
                                            groupLedgerViewModel.splitRuleMode == .proportion ? "\(member.name) 比例" : "\(member.name) 分攤金額",
                                            text: Binding(
                                                get: { groupLedgerViewModel.splitRuleInputs[member.id] ?? "" },
                                                set: { groupLedgerViewModel.splitRuleInputs[member.id] = $0 }
                                            )
                                        )
                                        .keyboardType(.decimalPad)
                                    }
                                }

                                Button("新增共享支出") {
                                    groupLedgerViewModel.addSharedExpense()
                                }
                            }

                            Group {
                                TextField("本月群組預算", text: $groupLedgerViewModel.monthlyBudgetAmount)
                                    .keyboardType(.decimalPad)
                                Button("儲存群組月預算") {
                                    groupLedgerViewModel.saveMonthlyBudget()
                                }
                                .font(.footnote)

                                LabeledContent("本月支出", value: overview.budgetSnapshot.spent.formatted())
                                LabeledContent("預算剩餘", value: overview.budgetSnapshot.remaining.formatted())
                            }

                            if overview.balances.isEmpty {
                                Text("尚無分攤紀錄")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("成員淨額")
                                    .font(.subheadline.bold())
                                ForEach(overview.balances) { item in
                                    HStack {
                                        Text(item.member.name)
                                        Spacer()
                                        Text(item.net.formatted())
                                            .foregroundStyle(item.net >= 0 ? .green : .red)
                                    }
                                    .font(.caption)
                                }

                                Text("建議結算（最少轉帳）")
                                    .font(.subheadline.bold())
                                if overview.settlements.isEmpty {
                                    Text("目前無需互轉")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(overview.settlements) { transfer in
                                        Text("\(transfer.fromMember.name) → \(transfer.toMember.name)：\(transfer.amount.formatted())")
                                            .font(.caption)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("群組月報")
                                    .font(.subheadline.bold())
                                LabeledContent("本月筆數", value: "\(overview.monthlyReport.expenseCount)")
                                LabeledContent("本月總支出", value: overview.monthlyReport.totalExpense.formatted())
                                LabeledContent("平均每筆", value: overview.monthlyReport.averageExpense.formatted())
                                LabeledContent("最大單筆", value: overview.monthlyReport.topExpenseTitle ?? "暫無")
                            }
                        }
                    }
                }
            }

            Section("Pro 預算系統") {
                LabeledContent("方案狀態", value: proEntitlementStore.statusText)
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
                        if proEntitlementStore.canAccess(.rolloverBudget) {
                            Text("可結轉").tag(CarryOverMode.rollover)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("儲存本月分類預算") {
                        let addingNewCategory = !budgetViewModel.hasBudget(for: budgetViewModel.selectedCategoryName)
                        if !proEntitlementStore.canAccess(.unlimitedBudgets) && addingNewCategory && budgetViewModel.activeBudgetCount >= 2 {
                            openProFeature(trigger: "budget_limit")
                            return
                        }
                        budgetViewModel.saveBudget()
                    }

                    Button("快速複製上月預算") {
                        let result = budgetViewModel.copyLastMonth(isPro: proEntitlementStore.canAccess(.unlimitedBudgets))
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

            Section("進階報表與數據分析") {
                Picker("區間", selection: $reportViewModel.selectedRange) {
                    ForEach(ReportRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: reportViewModel.selectedRange) { newValue in
                    if !proEntitlementStore.canAccess(.advancedReports) && newValue.months > 1 {
                        reportViewModel.selectedRange = .oneMonth
                        openProFeature(trigger: "advanced_report_3m")
                    } else {
                        reportViewModel.refresh()
                    }
                }

                Picker("圖表類型", selection: $reportViewModel.selectedChartType) {
                    ForEach(ReportChartType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Picker("資料篩選", selection: $reportViewModel.selectedMetricFilter) {
                    ForEach(ReportMetricFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                if let report = reportViewModel.report {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("趨勢摘要")
                            .font(.subheadline.bold())
                        LabeledContent("平均月收入", value: report.averageIncome.formatted())
                        LabeledContent("平均月支出", value: report.averageExpense.formatted())
                        LabeledContent("平均月淨額", value: report.averageNet.formatted())
                        LabeledContent("MoM（本月淨額較上月）", value: report.momNetDelta?.formatted() ?? "暫無")
                        LabeledContent("YoY（本月淨額較去年同月）", value: report.yoyNetDelta?.formatted() ?? "暫無")
                    }

                    let chartSeries = reportViewModel.chartSeries(for: report)
                    if chartSeries.isEmpty {
                        Text("資料不足，請先新增更多帳目")
                            .foregroundStyle(.secondary)
                    } else {
                        AdvancedReportTrendChart(series: chartSeries, chartType: reportViewModel.selectedChartType)
                            .frame(height: 220)

                        ForEach(report.monthlyTrend) { point in
                            HStack {
                                Text(point.monthLabel)
                                Spacer()
                                Text("收 \(point.income.formatted()) / 支 \(point.expense.formatted()) / 淨 \(point.net.formatted())")
                                    .font(.caption)
                            }
                        }
                    }

                    if !report.pieSlices.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("圓餅圖分析（收入/支出占比）")
                                .font(.subheadline.bold())
                            AdvancedReportPieChart(slices: report.pieSlices)
                                .frame(height: 220)
                            ForEach(report.pieSlices) { slice in
                                Text("• \(slice.label)：\(slice.value.formatted())")
                                    .font(.caption)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("分類變化分析（MoM）")
                            .font(.subheadline.bold())
                        if let growth = report.topGrowth {
                            Text("增長最多：\(growth.categoryName)（+\(growth.delta.formatted())）")
                                .font(.caption)
                        } else {
                            Text("增長最多：暫無")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let decline = report.topDecline {
                            Text("下降最多：\(decline.categoryName)（\(decline.delta.formatted())）")
                                .font(.caption)
                        } else {
                            Text("下降最多：暫無")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("尚無可分析資料")
                        .foregroundStyle(.secondary)
                }

                Button("匯出 PDF 報表（示範）") {
                    openProFeature(trigger: "report_pdf_export")
                }
            }

            Section("年度財務回顧（Wrapped）") {
                Button("產生今年 Wrapped") {
                    let year = Calendar.current.component(.year, from: Date())
                    annualWrapped = AnnualWrappedReportBuilder(store: expenseStore).build(year: year)
                }

                if let annualWrapped {
                    LabeledContent("年度淨額", value: annualWrapped.totalNet.formatted())
                    LabeledContent("儲蓄率", value: "\(annualWrapped.savingRate.formatted())%")
                    LabeledContent("支出最高分類", value: annualWrapped.topExpenseCategory?.name ?? "暫無")
                    LabeledContent("最佳月份", value: annualWrapped.bestMonth?.month.formatted(date: .abbreviated, time: .omitted) ?? "暫無")
                } else {
                    Text("尚未產生 Wrapped")
                        .foregroundStyle(.secondary)
                }
            }

            Section("歷史快照（Snapshot）") {
                Button("匯出 Snapshot") {
                    do {
                        snapshotPayload = try ExpenseSnapshotService(store: expenseStore).exportSnapshot()
                        snapshotMessage = "已產生快照，可直接貼上還原"
                    } catch {
                        snapshotMessage = error.localizedDescription
                    }
                }

                TextEditor(text: $snapshotPayload)
                    .frame(minHeight: 110)

                Button("還原 Snapshot") {
                    do {
                        try ExpenseSnapshotService(store: expenseStore).restoreSnapshot(from: snapshotPayload)
                        viewModel.reload()
                        budgetViewModel.refresh()
                        reportViewModel.refresh()
                        snapshotMessage = "還原完成"
                    } catch {
                        snapshotMessage = error.localizedDescription
                    }
                }

                if let snapshotMessage {
                    Text(snapshotMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("訂閱挽留與續訂策略") {
                if let retention = proEntitlementStore.retentionStrategy {
                    Text(retention.headline)
                        .font(.subheadline.bold())
                    Text("CTA：\(retention.cta)")
                        .font(.caption)
                    Text("Offer：\(retention.offerCode)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("目前無需挽留策略")
                        .foregroundStyle(.secondary)
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
                    reportViewModel.refresh()
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
                    .onDelete { offsets in
                        viewModel.deleteExpenses(at: offsets)
                        budgetViewModel.refresh()
                        reportViewModel.refresh()
                    }
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
        let feature: ProEntitlementStore.Feature
        switch trigger {
        case "report_pdf_export":
            feature = .pdfExport
        case "advanced_report_3m":
            feature = .advancedReports
        default:
            feature = .unlimitedBudgets
        }

        if !proEntitlementStore.canAccess(feature) {
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
            groupLedgerStore: PreviewGroupLedgerStore(),
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
        let content = PaywallExperience.content(for: trigger)

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(content.headline)
                    .font(.title3.bold())

                Text(content.subheadline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("觸發來源：\(trigger) · 建議：\(content.recommendedPlanLabel)")
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
                        Telemetry.shared.track(.proPaywallCtaTapped, metadata: ["trigger": trigger, "cta": "trial"])
                        Task {
                            await entitlementStore.startTrial()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(entitlementStore.isProcessing)

                    Button("月付 NT$90") {
                        Telemetry.shared.track(.proPaywallCtaTapped, metadata: ["trigger": trigger, "cta": "monthly"])
                        Task {
                            await entitlementStore.subscribeMonthly()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(entitlementStore.isProcessing)

                    Button("年付 NT$790") {
                        Telemetry.shared.track(.proPaywallCtaTapped, metadata: ["trigger": trigger, "cta": "yearly"])
                        Task {
                            await entitlementStore.subscribeYearly()
                            if entitlementStore.isPro { onDismiss() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(entitlementStore.isProcessing)

                    Button("恢復購買") {
                        Telemetry.shared.track(.proPaywallCtaTapped, metadata: ["trigger": trigger, "cta": "restore"])
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
            .onAppear {
                Telemetry.shared.track(.proPaywallViewed, metadata: ["trigger": trigger])
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉", action: onDismiss)
                }
            }
        }
    }
}

struct TrendChartSeriesPoint: Identifiable {
    var id: String { "\(seriesName)-\(monthLabel)" }
    let monthLabel: String
    let seriesName: String
    let value: Decimal
}

enum ReportChartType: String, CaseIterable, Identifiable {
    case line
    case bar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .line: return "折線圖"
        case .bar: return "長條圖"
        }
    }
}

enum ReportMetricFilter: String, CaseIterable, Identifiable {
    case all
    case income
    case expense
    case net

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "全部"
        case .income: return "僅收入"
        case .expense: return "僅支出"
        case .net: return "僅淨額"
        }
    }
}

struct AdvancedReportTrendChart: View {
    let series: [TrendChartSeriesPoint]
    let chartType: ReportChartType

    var body: some View {
        Chart(series) { point in
            switch chartType {
            case .line:
                LineMark(
                    x: .value("月份", point.monthLabel),
                    y: .value("金額", decimalValue(point.value))
                )
                .foregroundStyle(by: .value("序列", point.seriesName))
                PointMark(
                    x: .value("月份", point.monthLabel),
                    y: .value("金額", decimalValue(point.value))
                )
                .foregroundStyle(by: .value("序列", point.seriesName))
            case .bar:
                BarMark(
                    x: .value("月份", point.monthLabel),
                    y: .value("金額", decimalValue(point.value))
                )
                .foregroundStyle(by: .value("序列", point.seriesName))
                .position(by: .value("序列", point.seriesName))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private func decimalValue(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

struct AdvancedReportPieChart: View {
    let slices: [AdvancedReport.PieSlice]

    var body: some View {
        let total = slices.reduce(Decimal.zero) { $0 + $1.value }

        ZStack {
            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                let start = startFraction(at: index)
                let end = endFraction(at: index)

                Circle()
                    .trim(from: start, to: end)
                    .stroke(color(at: index), style: StrokeStyle(lineWidth: 30, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("總額")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(total.formatted())
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }

    private func startFraction(at index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        let numerator = slices.prefix(index).reduce(Decimal.zero) { $0 + $1.value }
        let denominator = slices.reduce(Decimal.zero) { $0 + $1.value }
        guard denominator != .zero else { return 0 }
        return CGFloat(NSDecimalNumber(decimal: numerator / denominator).doubleValue)
    }

    private func endFraction(at index: Int) -> CGFloat {
        let numerator = slices.prefix(index + 1).reduce(Decimal.zero) { $0 + $1.value }
        let denominator = slices.reduce(Decimal.zero) { $0 + $1.value }
        guard denominator != .zero else { return 0 }
        return CGFloat(NSDecimalNumber(decimal: numerator / denominator).doubleValue)
    }

    private func color(at index: Int) -> Color {
        let palette: [Color] = [.blue, .red, .green, .orange]
        return palette[index % palette.count]
    }
}

enum ReportRange: String, CaseIterable, Identifiable {
    case oneMonth
    case threeMonths
    case sixMonths
    case twelveMonths

    var id: String { rawValue }

    var months: Int {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .twelveMonths: return 12
        }
    }

    var label: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .twelveMonths: return "12M"
        }
    }
}

struct AdvancedReport {
    struct TrendPoint: Identifiable {
        var id: String { monthLabel }
        let monthLabel: String
        let income: Decimal
        let expense: Decimal
        let net: Decimal
    }

    struct CategoryDelta {
        let categoryName: String
        let delta: Decimal
    }

    struct PieSlice: Identifiable {
        var id: String { label }
        let label: String
        let value: Decimal
    }

    let monthlyTrend: [TrendPoint]
    let averageIncome: Decimal
    let averageExpense: Decimal
    let averageNet: Decimal
    let topGrowth: CategoryDelta?
    let topDecline: CategoryDelta?
    let momNetDelta: Decimal?
    let yoyNetDelta: Decimal?
    let pieSlices: [PieSlice]
}

@MainActor
final class AdvancedReportViewModel: ObservableObject {
    @Published var selectedRange: ReportRange = .oneMonth
    @Published var selectedChartType: ReportChartType = .line
    @Published var selectedMetricFilter: ReportMetricFilter = .all
    @Published private(set) var report: AdvancedReport?

    private let expenseStore: ExpenseStore
    private let proEntitlementStore: ProEntitlementStore

    init(expenseStore: ExpenseStore, proEntitlementStore: ProEntitlementStore) {
        self.expenseStore = expenseStore
        self.proEntitlementStore = proEntitlementStore
        refresh()
    }

    func refresh() {
        let monthCount = proEntitlementStore.canAccess(.advancedReports) ? selectedRange.months : 1
        let now = Date()
        var snapshots: [MonthlyOverview] = []

        for offset in stride(from: monthCount - 1, through: 0, by: -1) {
            guard let targetMonth = Calendar.current.date(byAdding: .month, value: -offset, to: now),
                  let overview = try? expenseStore.fetchMonthlyOverview(for: targetMonth)
            else { continue }
            snapshots.append(overview)
        }

        guard !snapshots.isEmpty else {
            report = nil
            return
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"

        let trend = snapshots.map { snapshot in
            AdvancedReport.TrendPoint(
                monthLabel: formatter.string(from: snapshot.month),
                income: snapshot.income,
                expense: snapshot.expense,
                net: snapshot.net
            )
        }

        let count = Decimal(snapshots.count)
        let totalIncome = snapshots.reduce(Decimal.zero) { $0 + $1.income }
        let totalExpense = snapshots.reduce(Decimal.zero) { $0 + $1.expense }
        let totalNet = snapshots.reduce(Decimal.zero) { $0 + $1.net }

        let currentMonthOverview = snapshots.last
        let previousMonthOverview = Calendar.current.date(byAdding: .month, value: -1, to: now).flatMap {
            try? expenseStore.fetchMonthlyOverview(for: $0)
        }
        let previousYearOverview = Calendar.current.date(byAdding: .year, value: -1, to: now).flatMap {
            try? expenseStore.fetchMonthlyOverview(for: $0)
        }

        report = AdvancedReport(
            monthlyTrend: trend,
            averageIncome: totalIncome / count,
            averageExpense: totalExpense / count,
            averageNet: totalNet / count,
            topGrowth: topCategoryDelta(from: snapshots, highest: true),
            topDecline: topCategoryDelta(from: snapshots, highest: false),
            momNetDelta: netDelta(current: currentMonthOverview?.net, baseline: previousMonthOverview?.net),
            yoyNetDelta: netDelta(current: currentMonthOverview?.net, baseline: previousYearOverview?.net),
            pieSlices: [
                .init(label: "收入", value: totalIncome),
                .init(label: "支出", value: totalExpense)
            ].filter { $0.value > .zero }
        )
    }

    func chartSeries(for report: AdvancedReport) -> [TrendChartSeriesPoint] {
        report.monthlyTrend.flatMap { point in
            switch selectedMetricFilter {
            case .all:
                return [
                    TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "收入", value: point.income),
                    TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "支出", value: point.expense),
                    TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "淨額", value: point.net)
                ]
            case .income:
                return [TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "收入", value: point.income)]
            case .expense:
                return [TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "支出", value: point.expense)]
            case .net:
                return [TrendChartSeriesPoint(monthLabel: point.monthLabel, seriesName: "淨額", value: point.net)]
            }
        }
    }

    private func topCategoryDelta(from snapshots: [MonthlyOverview], highest: Bool) -> AdvancedReport.CategoryDelta? {
        guard snapshots.count >= 2,
              let previous = snapshots.dropLast().last,
              let current = snapshots.last
        else { return nil }

        let previousMap = Dictionary(uniqueKeysWithValues: previous.categoryTotals.map { ($0.name, absDecimal($0.amount)) })
        let currentMap = Dictionary(uniqueKeysWithValues: current.categoryTotals.map { ($0.name, absDecimal($0.amount)) })
        let allCategories = Set(previousMap.keys).union(currentMap.keys)

        let deltas = allCategories.map { name in
            AdvancedReport.CategoryDelta(
                categoryName: name,
                delta: (currentMap[name] ?? .zero) - (previousMap[name] ?? .zero)
            )
        }

        if highest {
            let growth = deltas.filter { $0.delta > .zero }
            return growth.max(by: { $0.delta < $1.delta })
        }

        let decline = deltas.filter { $0.delta < .zero }
        return decline.min(by: { $0.delta < $1.delta })
    }

    private func absDecimal(_ value: Decimal) -> Decimal {
        value < 0 ? -value : value
    }

    private func netDelta(current: Decimal?, baseline: Decimal?) -> Decimal? {
        guard let current else { return nil }
        guard let baseline else {
            return current == .zero ? nil : current
        }
        if current == .zero && baseline == .zero { return nil }
        return current - baseline
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

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {}
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

private final class PreviewGroupLedgerStore: GroupLedgerStore {
    func fetchLedgers() throws -> [GroupLedger] {
        [GroupLedger(id: 1, name: "家庭帳本", createdAt: Date())]
    }

    func createLedger(name: String) throws -> GroupLedger {
        GroupLedger(id: 1, name: name, createdAt: Date())
    }

    func fetchMembers(ledgerId: Int64) throws -> [LedgerMember] {
        [
            LedgerMember(id: 1, ledgerId: ledgerId, name: "Bruce", createdAt: Date()),
            LedgerMember(id: 2, ledgerId: ledgerId, name: "Alex", createdAt: Date())
        ]
    }

    func addMember(ledgerId: Int64, name: String) throws -> LedgerMember {
        LedgerMember(id: 3, ledgerId: ledgerId, name: name, createdAt: Date())
    }

    func addSharedExpense(ledgerId: Int64, title: String, amount: Decimal, paidByMemberId: Int64, splits: [(memberId: Int64, amount: Decimal)]) throws {}

    func upsertMonthlyBudget(ledgerId: Int64, month: Date, amount: Decimal) throws {}

    func fetchOverview(ledgerId: Int64, month: Date) throws -> GroupLedgerOverview {
        let ledger = GroupLedger(id: ledgerId, name: "家庭帳本", createdAt: Date())
        let members = try fetchMembers(ledgerId: ledgerId)
        let balances = [
            LedgerBalance(member: members[0], paid: 1000, owed: 500),
            LedgerBalance(member: members[1], paid: 500, owed: 1000)
        ]
        return GroupLedgerOverview(
            ledger: ledger,
            members: members,
            recentExpenses: [],
            balances: balances,
            settlements: [SettlementTransfer(fromMember: members[1], toMember: members[0], amount: 500)],
            budgetSnapshot: GroupBudgetSnapshot(monthStart: month, budget: 6000, spent: 1500),
            monthlyReport: GroupMonthlyReport(monthStart: month, expenseCount: 4, totalExpense: 1500, averageExpense: 375, topExpenseTitle: "採買", payerBreakdown: [
                MemberAmountBreakdown(member: members[0], amount: 1000),
                MemberAmountBreakdown(member: members[1], amount: 500)
            ])
        )
    }
}

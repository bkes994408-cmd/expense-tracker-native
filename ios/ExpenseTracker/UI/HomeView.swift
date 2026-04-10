import SwiftUI
import Charts
import UIKit

struct HomeView: View {
    enum ScreenTab: String, CaseIterable, Identifiable {
        case dashboard
        case transactions
        case reports

        var id: String { rawValue }
        var label: String {
            switch self {
            case .dashboard: return "Home"
            case .transactions: return "交易"
            case .reports: return "報表"
            }
        }
    }

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
    @State private var reportPDFURL: URL?
    @State private var reportPDFMessage: String?
    @State private var selectedTab: ScreenTab

    private let expenseStore: ExpenseStore

    init(
        store: ExpenseStore,
        budgetStore: BudgetStore,
        groupLedgerStore: GroupLedgerStore,
        categoryStore: CategoryStore? = nil,
        proEntitlementStore: ProEntitlementStore,
        initialTab: ScreenTab = .dashboard,
        onOpenSettings: @escaping () -> Void
    ) {
        self.expenseStore = store
        _ = categoryStore
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(store: store))
        _budgetViewModel = StateObject(wrappedValue: BudgetViewModel(budgetStore: budgetStore, expenseStore: store))
        _reportViewModel = StateObject(wrappedValue: AdvancedReportViewModel(expenseStore: store, proEntitlementStore: proEntitlementStore))
        _groupLedgerViewModel = StateObject(wrappedValue: GroupLedgerViewModel(store: groupLedgerStore))
        self.proEntitlementStore = proEntitlementStore
        _selectedTab = State(initialValue: initialTab)
        self.onOpenSettings = onOpenSettings
    }

    @State private var selectedTransactionChip: String = "全部"
    @State private var selectedReportRange: String = "1M"

    var body: some View {
        let summary = viewModel.monthlyOverview

        ZStack(alignment: .bottom) {
            Color(red: 244/255, green: 246/255, blue: 251/255)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good evening")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Bruce")
                                .font(.title3.bold())
                        }
                        Spacer()
                        Button(action: onOpenSettings) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color(red: 44/255, green: 48/255, blue: 120/255))
                                .padding(10)
                                .background(.white, in: Circle())
                        }
                    }

                    heroCard(summary: summary)

                    HStack(spacing: 10) {
                        miniStatCard(title: "交易", value: "\(viewModel.expenses.count)", emphasized: true)
                        VStack(spacing: 10) {
                            miniStatCard(title: "分類", value: "\(summary.categoryTotals.count)")
                            miniStatCard(title: "方案", value: proEntitlementStore.isPro ? "Pro" : "Free")
                        }
                    }

                    Picker("頁面", selection: $selectedTab) {
                        Text("Home").tag(ScreenTab.dashboard)
                        Text("交易").tag(ScreenTab.transactions)
                        Text("報表").tag(ScreenTab.reports)
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(red: 228/255, green: 233/255, blue: 245/255), lineWidth: 1)
                    )
                    .tint(Color(red: 47/255, green: 60/255, blue: 150/255))

                    if selectedTab == .dashboard {
                        sectionCard(title: "本月分類摘要") {
                            if summary.categoryTotals.isEmpty {
                                Text("本月尚無分類資料")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(summary.categoryTotals.prefix(4)) { item in
                                    HStack {
                                        Circle()
                                            .fill(Color(red: 225/255, green: 230/255, blue: 255/255))
                                            .frame(width: 28, height: 28)
                                            .overlay {
                                                Text(String(item.name.prefix(1)))
                                                    .font(.caption.bold())
                                            }
                                        Text(item.name)
                                        Spacer()
                                        Text(item.amount.formatted())
                                            .foregroundStyle(item.amount < 0 ? .red : .green)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }

                        sectionCard(title: "最近交易") {
                            recentTransactionRows(limit: 5)
                        }
                    } else if selectedTab == .transactions {
                        HStack(spacing: 8) {
                            ForEach(["全部", "固定", "最近7天", "Recurring"], id: \.self) { chip in
                                let selected = selectedTransactionChip == chip
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                                        selectedTransactionChip = chip
                                    }
                                } label: {
                                    Text(chip)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 8)
                                        .background(
                                            selected
                                                ? Color(red: 47/255, green: 60/255, blue: 150/255)
                                                : Color.white,
                                            in: Capsule()
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(selected ? Color.clear : Color(red: 226/255, green: 231/255, blue: 244/255), lineWidth: 1)
                                        )
                                        .foregroundStyle(selected ? .white : Color(red: 78/255, green: 88/255, blue: 106/255))
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }

                        sectionCard(title: "新增交易") {
                            TextField("標題（例如：晚餐）", text: $viewModel.newTitle)
                                .textFieldStyle(.roundedBorder)
                            TextField("金額", text: $viewModel.newAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)

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
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                        }

                        sectionCard(title: "交易列表") {
                            recentTransactionRows(limit: 20)
                        }

                        sectionCard(title: "Recurring") {
                            recurringRows(limit: 3)
                        }
                    } else {
                        sectionCard(title: "Reports") {
                            HStack(spacing: 8) {
                                ForEach(["1M", "3M", "6M", "12M"], id: \.self) { range in
                                    let selected = selectedReportRange == range
                                    Button {
                                        selectedReportRange = range
                                    } label: {
                                        Text(range)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selected ? Color(red: 47/255, green: 60/255, blue: 150/255) : .white, in: Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(selected ? Color.clear : Color(red: 228/255, green: 233/255, blue: 245/255), lineWidth: 1)
                                            )
                                            .foregroundStyle(selected ? .white : Color(red: 76/255, green: 86/255, blue: 105/255))
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }

                        sectionCard(title: "摘要") {
                            HStack(spacing: 10) {
                                miniStatCard(title: "平均收入", value: summary.income.formatted())
                                miniStatCard(title: "平均支出", value: summary.expense.formatted())
                            }
                            let topCategory = summary.categoryTotals.max { abs($0.amount) < abs($1.amount) }
                            transactionRow(
                                title: "最多支出分類",
                                subtitle: topCategory?.name ?? "尚無資料",
                                amount: topCategory?.amount ?? 0,
                                bubbleText: "#"
                            )
                        }

                        sectionCard(title: "圖表與洞察") {
                            if summary.categoryTotals.isEmpty {
                                emptyState("尚無資料，新增交易後即可生成趨勢圖")
                            } else {
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach([0.35, 0.62, 0.48, 0.78, 0.55], id: \.self) { value in
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(red: 220/255, green: 227/255, blue: 255/255))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 96 * value)
                                    }
                                }
                                ReplicaStateBox(title: "Insight", message: "本月淨額 \(summary.net.formatted())，較上月變化待接入正式資料。")
                            }
                        }

                        sectionCard(title: "Edge States") {
                            ReplicaEdgeStates(
                                loadingMessage: "正在整理跨月份資料，請稍候...",
                                emptyMessage: "目前區間沒有可視化資料，請切換月份或新增交易。",
                                errorMessage: "報表資料暫時不可用，請稍後重試。",
                                longTextMessage: "這是一段很長的報表說明文字，用來驗證 iOS 與 Android 在字級、間距與換行策略的一致性。",
                                denseContentHint: "當資料密度較高時，優先保留標題與金額資訊，其餘內容以省略方式呈現。"
                            )
                        }
                    }

                    Spacer(minLength: 96)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(trigger: paywallTrigger, entitlementStore: proEntitlementStore) {
                isPaywallPresented = false
            }
        }
    }

    @ViewBuilder
    private func heroCard(summary: MonthlyOverview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Balance")
                .foregroundStyle(Color.white.opacity(0.82))
                .font(.callout.weight(.medium))
            Text(summary.net.formatted())
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 26) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Income").foregroundStyle(Color.white.opacity(0.78)).font(.caption)
                    Text(summary.income.formatted()).foregroundStyle(.white).font(.subheadline.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Expense").foregroundStyle(Color.white.opacity(0.78)).font(.caption)
                    Text(summary.expense.formatted()).foregroundStyle(.white).font(.subheadline.weight(.semibold))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 30/255, green: 37/255, blue: 95/255),
                    Color(red: 62/255, green: 67/255, blue: 168/255),
                    Color(red: 106/255, green: 95/255, blue: 240/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, y: 10)
    }

    @ViewBuilder
    private func miniStatCard(title: String, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .system(size: 30, weight: .bold, design: .rounded) : .title3.bold())
                .foregroundStyle(emphasized ? Color(red: 46/255, green: 42/255, blue: 115/255) : Color(red: 33/255, green: 38/255, blue: 64/255))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, emphasized ? 18 : 12)
        .background(.white, in: RoundedRectangle(cornerRadius: emphasized ? 22 : 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: emphasized ? 22 : 18, style: .continuous)
                .stroke(Color(red: 228/255, green: 233/255, blue: 245/255), lineWidth: 1)
        )
        .shadow(color: .black.opacity(emphasized ? 0.09 : 0.035), radius: emphasized ? 12 : 5, y: 4)
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ReplicaDesign.cardPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: ReplicaDesign.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ReplicaDesign.cardRadius, style: .continuous)
                .stroke(ReplicaDesign.cardBorder, lineWidth: 1)
        )
        .shadow(color: ReplicaDesign.cardShadow, radius: 8, y: 4)
    }

    @ViewBuilder
    private func recentTransactionRows(limit: Int) -> some View {
        if viewModel.expenses.isEmpty {
            emptyState("目前沒有資料")
        } else {
            ForEach(viewModel.expenses.prefix(limit)) { expense in
                transactionRow(
                    title: expense.title,
                    subtitle: expense.createdAt.formatted(date: .abbreviated, time: .omitted),
                    amount: expense.amount,
                    bubbleText: String(expense.title.prefix(1))
                )
            }
        }
    }

    @ViewBuilder
    private func recurringRows(limit: Int) -> some View {
        if viewModel.expenses.isEmpty {
            emptyState("目前沒有固定交易")
        } else {
            ForEach(viewModel.expenses.prefix(limit)) { expense in
                transactionRow(
                    title: expense.title,
                    subtitle: "每月 · \(expense.createdAt.formatted(date: .abbreviated, time: .omitted))",
                    amount: expense.amount,
                    bubbleText: "R"
                )
            }
        }
    }

    @ViewBuilder
    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(red: 246/255, green: 248/255, blue: 255/255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 228/255, green: 233/255, blue: 245/255), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func transactionRow(title: String, subtitle: String, amount: Decimal, bubbleText: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(red: 230/255, green: 235/255, blue: 255/255))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(bubbleText)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(red: 47/255, green: 60/255, blue: 150/255))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(amount.formatted())
                .font(.title3.weight(.heavy))
                .foregroundStyle(amount < 0 ? .red : .green)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(red: 247/255, green: 248/255, blue: 255/255), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 232/255, green: 236/255, blue: 246/255), lineWidth: 1)
        )
        .scaleEffect(1)
        .animation(.easeOut(duration: 0.18), value: amount)
    }

    private var bottomBar: some View {
        ZStack(alignment: .center) {
            HStack {
                bottomItem(icon: "house.fill", title: "Home", tab: .dashboard)
                Spacer(minLength: 0)
                bottomItem(icon: "list.bullet.rectangle", title: "交易", tab: .transactions)
                Spacer(minLength: 0)
                bottomItem(icon: "chart.bar.xaxis", title: "報表", tab: .reports)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.95), in: Capsule())
            .overlay(
                Capsule().stroke(Color(red: 228/255, green: 233/255, blue: 245/255), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)

            Button {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                    selectedTab = .transactions
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color(red: 46/255, green: 42/255, blue: 115/255), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.15), radius: 11, y: 6)
            }
            .offset(y: -28)
        }
        .frame(height: 94)
    }

    @ViewBuilder
    private func bottomItem(icon: String, title: String, tab: ScreenTab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(selectedTab == tab ? Color(red: 50/255, green: 56/255, blue: 141/255) : .secondary)
            .frame(width: 62)
        }
        .buttonStyle(.plain)
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

struct ReportPDFExporter {
    func export(report: AdvancedReport, range: ReportRange, directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let fileURL = directory.appendingPathComponent("expense-report-\(Int(Date().timeIntervalSince1970)).pdf")
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            var y: CGFloat = 44

            func draw(_ text: String, font: UIFont = .systemFont(ofSize: 12, weight: .regular)) {
                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                text.draw(in: CGRect(x: 32, y: y, width: pageBounds.width - 64, height: 24), withAttributes: attributes)
                y += 22
            }

            draw("Expense Tracker 月報", font: .systemFont(ofSize: 20, weight: .bold))
            draw("期間：最近 \(range.months) 個月")
            draw("產生時間：\(formatter.string(from: Date()))")
            y += 8
            draw("平均月收入：\(report.averageIncome.formatted())")
            draw("平均月支出：\(report.averageExpense.formatted())")
            draw("平均月淨額：\(report.averageNet.formatted())")
            draw("MoM：\(report.momNetDelta?.formatted() ?? "暫無")")
            draw("YoY：\(report.yoyNetDelta?.formatted() ?? "暫無")")
            y += 8
            draw("趨勢資料", font: .systemFont(ofSize: 16, weight: .semibold))
            for point in report.monthlyTrend.prefix(12) {
                draw("\(point.monthLabel) 收\(point.income.formatted()) / 支\(point.expense.formatted()) / 淨\(point.net.formatted())")
            }
            y += 8
            draw("分類變化（MoM）", font: .systemFont(ofSize: 16, weight: .semibold))
            draw("增長最多：\(report.topGrowth.map { "\($0.categoryName) (+\($0.delta.formatted()))" } ?? "暫無")")
            draw("下降最多：\(report.topDecline.map { "\($0.categoryName) (\($0.delta.formatted()))" } ?? "暫無")")
        }

        return fileURL
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

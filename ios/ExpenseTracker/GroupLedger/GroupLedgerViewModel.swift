import Foundation

enum SplitRuleMode: String, CaseIterable, Identifiable {
    case equal
    case proportion
    case fixedAmount

    var id: String { rawValue }

    var label: String {
        switch self {
        case .equal: return "平均"
        case .proportion: return "比例"
        case .fixedAmount: return "金額"
        }
    }
}

@MainActor
final class GroupLedgerViewModel: ObservableObject {
    @Published var ledgers: [GroupLedger] = []
    @Published var selectedLedgerId: Int64?
    @Published var overview: GroupLedgerOverview?

    @Published var newLedgerName = ""
    @Published var newMemberName = ""
    @Published var expenseTitle = ""
    @Published var expenseAmount = ""
    @Published var selectedPayerId: Int64?

    @Published var splitRuleMode: SplitRuleMode = .equal
    @Published var splitRuleInputs: [Int64: String] = [:]
    @Published var monthlyBudgetAmount = ""

    @Published var errorMessage: String?

    private let store: GroupLedgerStore

    init(store: GroupLedgerStore) {
        self.store = store
        reloadLedgers()
    }

    func reloadLedgers() {
        do {
            ledgers = try store.fetchLedgers()
            if selectedLedgerId == nil {
                selectedLedgerId = ledgers.first?.id
            }
            refreshOverview()
        } catch {
            errorMessage = "讀取群組帳本失敗"
        }
    }

    func createLedger() {
        do {
            let ledger = try store.createLedger(name: newLedgerName)
            newLedgerName = ""
            selectedLedgerId = ledger.id
            reloadLedgers()
        } catch {
            errorMessage = "建立群組帳本失敗"
        }
    }

    func addMember() {
        guard let ledgerId = selectedLedgerId else { return }
        do {
            let member = try store.addMember(ledgerId: ledgerId, name: newMemberName)
            newMemberName = ""
            if selectedPayerId == nil {
                selectedPayerId = member.id
            }
            splitRuleInputs[member.id] = splitRuleMode == .proportion ? "1" : "0"
            refreshOverview()
        } catch {
            errorMessage = "新增成員失敗"
        }
    }

    func addSharedExpense() {
        guard let ledgerId = selectedLedgerId,
              let payerId = selectedPayerId,
              let amount = Decimal(string: expenseAmount), amount > 0,
              let members = overview?.members,
              !members.isEmpty
        else {
            errorMessage = "請先選擇群組、付款人與有效金額"
            return
        }

        guard let splits = buildSplits(for: members, totalAmount: amount) else { return }

        do {
            try store.addSharedExpense(
                ledgerId: ledgerId,
                title: expenseTitle,
                amount: amount,
                paidByMemberId: payerId,
                splits: splits
            )
            expenseTitle = ""
            expenseAmount = ""
            refreshOverview()
        } catch {
            errorMessage = "新增共享支出失敗"
        }
    }

    func saveMonthlyBudget() {
        guard let ledgerId = selectedLedgerId,
              let amount = Decimal(string: monthlyBudgetAmount), amount >= 0
        else {
            errorMessage = "請輸入有效的群組月預算"
            return
        }

        do {
            try store.upsertMonthlyBudget(ledgerId: ledgerId, month: Date(), amount: amount)
            refreshOverview()
        } catch {
            errorMessage = "儲存群組月預算失敗"
        }
    }

    func setSplitRuleMode(_ mode: SplitRuleMode) {
        splitRuleMode = mode
        applyDefaultSplitInputs(for: overview?.members ?? [])
    }

    func refreshOverview() {
        guard let ledgerId = selectedLedgerId else {
            overview = nil
            return
        }

        do {
            let loaded = try store.fetchOverview(ledgerId: ledgerId, month: Date())
            overview = loaded
            if selectedPayerId == nil {
                selectedPayerId = loaded.members.first?.id
            }
            monthlyBudgetAmount = loaded.budgetSnapshot.budget.formattedPlain
            applyDefaultSplitInputs(for: loaded.members)
        } catch {
            errorMessage = "讀取群組帳本詳細資料失敗"
        }
    }

    private func buildSplits(for members: [LedgerMember], totalAmount: Decimal) -> [(memberId: Int64, amount: Decimal)]? {
        switch splitRuleMode {
        case .equal:
            var splits = members.map { (memberId: $0.id, amount: totalAmount / Decimal(members.count)) }
            let diff = totalAmount - splits.reduce(Decimal.zero) { $0 + $1.amount }
            if diff != .zero, let lastIndex = splits.indices.last {
                splits[lastIndex].amount += diff
            }
            return splits

        case .proportion:
            let ratioPairs = members.compactMap { member -> (Int64, Decimal)? in
                guard let raw = splitRuleInputs[member.id],
                      let ratio = Decimal(string: raw), ratio > 0
                else { return nil }
                return (member.id, ratio)
            }

            guard ratioPairs.count == members.count else {
                errorMessage = "比例分攤需為每位成員填入大於 0 的比例"
                return nil
            }

            let ratioSum = ratioPairs.reduce(Decimal.zero) { $0 + $1.1 }
            guard ratioSum > .zero else {
                errorMessage = "比例總和需大於 0"
                return nil
            }

            var splits = ratioPairs.map { pair in
                (memberId: pair.0, amount: (totalAmount * pair.1) / ratioSum)
            }
            let diff = totalAmount - splits.reduce(Decimal.zero) { $0 + $1.amount }
            if diff != .zero, let lastIndex = splits.indices.last {
                splits[lastIndex].amount += diff
            }
            return splits

        case .fixedAmount:
            var splits: [(memberId: Int64, amount: Decimal)] = []
            for member in members {
                guard let raw = splitRuleInputs[member.id],
                      let splitAmount = Decimal(string: raw), splitAmount >= 0
                else {
                    errorMessage = "金額分攤需填入有效數字"
                    return nil
                }
                splits.append((memberId: member.id, amount: splitAmount))
            }

            let splitTotal = splits.reduce(Decimal.zero) { $0 + $1.amount }
            guard splitTotal == totalAmount else {
                errorMessage = "金額分攤總和需等於支出金額"
                return nil
            }
            return splits
        }
    }

    private func applyDefaultSplitInputs(for members: [LedgerMember]) {
        for member in members {
            if splitRuleInputs[member.id] == nil {
                splitRuleInputs[member.id] = splitRuleMode == .proportion ? "1" : "0"
            }
        }
        splitRuleInputs = splitRuleInputs.filter { key, _ in members.contains(where: { $0.id == key }) }
    }
}

private extension Decimal {
    var formattedPlain: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}

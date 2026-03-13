import Foundation

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

        let splitAmount = amount / Decimal(members.count)
        var splits = members.map { (memberId: $0.id, amount: splitAmount) }
        let diff = amount - splits.reduce(Decimal.zero) { $0 + $1.amount }
        if diff != .zero, let lastIndex = splits.indices.last {
            splits[lastIndex].amount += diff
        }

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

    func refreshOverview() {
        guard let ledgerId = selectedLedgerId else {
            overview = nil
            return
        }

        do {
            let loaded = try store.fetchOverview(ledgerId: ledgerId)
            overview = loaded
            if selectedPayerId == nil {
                selectedPayerId = loaded.members.first?.id
            }
        } catch {
            errorMessage = "讀取群組帳本詳細資料失敗"
        }
    }
}

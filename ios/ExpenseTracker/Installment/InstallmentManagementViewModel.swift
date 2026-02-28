import Foundation

@MainActor
final class InstallmentManagementViewModel: ObservableObject {
    @Published var plans: [InstallmentPlan] = []
    @Published var newName = ""
    @Published var periodAmount = ""
    @Published var totalPeriods = "12"
    @Published var paidPeriods = "0"

    private let store: InstallmentStore

    init(store: InstallmentStore) {
        self.store = store
        reload()
    }

    func reload() {
        plans = (try? store.fetchAll()) ?? []
    }

    func addPlan() {
        guard
            let amount = Decimal(string: periodAmount), amount > 0,
            let total = Int(totalPeriods), total > 0,
            let paid = Int(paidPeriods), paid >= 0
        else { return }

        try? store.add(name: newName, periodAmount: amount, totalPeriods: total, paidPeriods: paid)
        newName = ""
        periodAmount = ""
        reload()
    }
}

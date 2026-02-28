import Foundation

@MainActor
final class SubscriptionManagementViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlan] = []
    @Published var newName = ""
    @Published var newAmount = ""
    @Published var cycleDays = "30"
    @Published var nextChargeAt = Date()
    @Published var reminderDaysBefore = "1"
    @Published var reminderEnabled = true

    private let store: SubscriptionStore

    init(store: SubscriptionStore) {
        self.store = store
        reload()
    }

    func reload() {
        plans = (try? store.fetchAll()) ?? []
    }

    func addPlan() {
        guard
            let amount = Decimal(string: newAmount), amount > 0,
            let cycle = Int(cycleDays), cycle > 0,
            let reminder = Int(reminderDaysBefore), reminder >= 0
        else { return }

        try? store.add(
            name: newName,
            amount: amount,
            cycleDays: cycle,
            nextChargeAt: nextChargeAt,
            reminderDaysBefore: reminder,
            reminderEnabled: reminderEnabled
        )

        newName = ""
        newAmount = ""
        reload()
    }
}

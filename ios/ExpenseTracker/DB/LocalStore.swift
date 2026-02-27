import Foundation
import GRDB

final class LocalStore {
    static let shared = LocalStore()

    let categoryStore: CategoryStore
    let expenseStore: ExpenseStore
    let subscriptionStore: SubscriptionStore
    let installmentStore: InstallmentStore

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let dbPath = appSupport.appendingPathComponent("expense-tracker.sqlite").path

        do {
            let dbQueue = try DatabaseQueue(path: dbPath)
            self.categoryStore = try GRDBCategoryStore(dbQueue: dbQueue)
            self.expenseStore = try GRDBExpenseStore(dbQueue: dbQueue)
            self.subscriptionStore = try GRDBSubscriptionStore(dbQueue: dbQueue)
            self.installmentStore = try GRDBInstallmentStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize local stores: \(error)")
        }
    }
}

import Foundation
import GRDB

final class LocalStore {
    static let shared = LocalStore()

    /// Auth 不依賴 DB，避免啟動就初始化整個資料層。
    let authService: AuthService = MockAuthService()

    lazy var syncStateStore: SyncStateStore = InMemorySyncStateStore()

    lazy var categoryStore: CategoryStore = {
        SyncingCategoryStore(base: rawCategoryStore, syncStateStore: syncStateStore)
    }()

    lazy var expenseStore: ExpenseStore = {
        SyncingExpenseStore(base: rawExpenseStore, syncStateStore: syncStateStore)
    }()

    lazy var subscriptionStore: SubscriptionStore = {
        do {
            return try GRDBSubscriptionStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize subscription store: \(error)")
        }
    }()

    lazy var installmentStore: InstallmentStore = {
        do {
            return try GRDBInstallmentStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize installment store: \(error)")
        }
    }()

    lazy var budgetStore: BudgetStore = {
        do {
            return try GRDBBudgetStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize budget store: \(error)")
        }
    }()

    lazy var groupLedgerStore: GroupLedgerStore = {
        do {
            return try GRDBGroupLedgerStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize group ledger store: \(error)")
        }
    }()

    lazy var repositorySyncBridge: IOSRepositorySyncBridge = {
        IOSRepositorySyncBridge(
            expenseStore: rawExpenseStore,
            categoryStore: rawCategoryStore,
            syncStateStore: syncStateStore,
            puller: NoopCloudSyncPuller()
        )
    }()

    private lazy var rawCategoryStore: CategoryStore = {
        do {
            return try GRDBCategoryStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize category store: \(error)")
        }
    }()

    private lazy var rawExpenseStore: ExpenseStore = {
        do {
            return try GRDBExpenseStore(dbQueue: dbQueue)
        } catch {
            fatalError("Failed to initialize expense store: \(error)")
        }
    }()

    private lazy var dbQueue: DatabaseQueue = {
        do {
            if ProcessInfo.processInfo.arguments.contains("UITEST_IN_MEMORY_DB") {
                return try DatabaseQueue()
            }

            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let dbPath = appSupport.appendingPathComponent("expense-tracker.sqlite").path
            return try DatabaseQueue(path: dbPath)
        } catch {
            fatalError("Failed to initialize database queue: \(error)")
        }
    }()

    private var hasPerformedInitialSyncPull = false

    func performInitialSyncPullIfNeeded() {
        guard !hasPerformedInitialSyncPull else { return }
        hasPerformedInitialSyncPull = true
        repositorySyncBridge.pullAndApplyOnce()
    }

    private init() {}
}

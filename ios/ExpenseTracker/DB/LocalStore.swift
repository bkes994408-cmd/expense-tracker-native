import Foundation

final class LocalStore {
    static let shared = LocalStore()

    let categoryStore: CategoryStore

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let dbPath = appSupport.appendingPathComponent("expense-tracker.sqlite").path

        if let store = try? GRDBCategoryStore(path: dbPath) {
            self.categoryStore = store
        } else {
            fatalError("Failed to initialize GRDBCategoryStore")
        }
    }
}

import Foundation

@MainActor
final class CategoryManagementViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var newCategoryName = ""

    private let store: CategoryStore

    init(store: CategoryStore) {
        self.store = store
        reload()
    }

    func reload() {
        categories = (try? store.fetchActive()) ?? []
    }

    func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            try store.add(name: trimmedName)
            newCategoryName = ""
            reload()
        } catch {
            // TODO: user-facing error in later issue
        }
    }

    func archive(_ id: Int64) {
        do {
            try store.archive(id: id)
            reload()
        } catch {
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let from = source.first else { return }
        var to = destination
        if destination > from { to -= 1 }

        do {
            try store.move(from: from, to: to)
            reload()
        } catch {
        }
    }
}

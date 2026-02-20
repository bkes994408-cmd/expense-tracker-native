import XCTest
@testable import ExpenseTracker

@MainActor
final class CategoryManagementViewModelTests: XCTestCase {
    func testAddCategory() {
        let store = FakeCategoryStore()
        let vm = CategoryManagementViewModel(store: store)

        vm.newCategoryName = "Food"
        vm.addCategory()

        XCTAssertEqual(vm.categories.map(\.name), ["Food"])
    }

    func testArchiveCategory() {
        let store = FakeCategoryStore(seed: [
            Category(id: 1, name: "Food", isArchived: false, sortOrder: 0),
            Category(id: 2, name: "Transport", isArchived: false, sortOrder: 1),
        ])
        let vm = CategoryManagementViewModel(store: store)

        vm.archive(1)

        XCTAssertEqual(vm.categories.map(\.name), ["Transport"])
    }
}

private final class FakeCategoryStore: CategoryStore {
    private var categories: [Category]

    init(seed: [Category] = []) {
        self.categories = seed
    }

    func fetchActive() throws -> [Category] {
        categories.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func add(name: String) throws {
        let nextId = (categories.map(\.id).max() ?? 0) + 1
        let nextOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
        categories.append(Category(id: nextId, name: name, isArchived: false, sortOrder: nextOrder))
    }

    func archive(id: Int64) throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index] = Category(
            id: categories[index].id,
            name: categories[index].name,
            isArchived: true,
            sortOrder: categories[index].sortOrder
        )
    }

    func move(from: Int, to: Int) throws {
        var active = categories.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        let moved = active.remove(at: from)
        active.insert(moved, at: to)

        for (idx, item) in active.enumerated() {
            if let original = categories.firstIndex(where: { $0.id == item.id }) {
                categories[original] = Category(id: item.id, name: item.name, isArchived: false, sortOrder: idx)
            }
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: CategoryManagementViewModel

    init(store: CategoryStore) {
        _viewModel = StateObject(wrappedValue: CategoryManagementViewModel(store: store))
    }

    var body: some View {
        List {
            Section("Category Management") {
                HStack {
                    TextField("New category", text: $viewModel.newCategoryName)
                    Button("Add") { viewModel.addCategory() }
                }

                ForEach(viewModel.categories) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                        Button("Archive") {
                            viewModel.archive(category.id)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove(perform: viewModel.move)
            }

            Section("About") {
                LabeledContent("Version", value: "0.0.1")
            }
        }
        .toolbar { EditButton() }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView(store: PreviewCategoryStore()) }
}

private final class PreviewCategoryStore: CategoryStore {
    private var items: [Category] = [
        Category(id: 1, name: "Food", isArchived: false, sortOrder: 0),
        Category(id: 2, name: "Transport", isArchived: false, sortOrder: 1),
    ]

    func fetchActive() throws -> [Category] { items.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder } }
    func add(name: String) throws {}
    func archive(id: Int64) throws {}
    func move(from: Int, to: Int) throws {}
}

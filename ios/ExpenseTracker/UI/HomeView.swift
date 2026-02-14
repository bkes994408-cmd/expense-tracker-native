import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    private let repository: TransactionRepository
    let onAdd: () -> Void

    init(repository: TransactionRepository, onAdd: @escaping () -> Void) {
        self.repository = repository
        self.onAdd = onAdd
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        List {
            if viewModel.transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.transactions) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formatCurrency(cents: item.amountCents))
                            .font(.headline)
                        if !item.note.isEmpty {
                            Text(item.note)
                                .foregroundStyle(.secondary)
                        }
                        Text(item.occurredAt.formatted())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.delete(id: item.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Home")
        .toolbar {
            Button {
                onAdd()
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .onAppear { viewModel.load() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func formatCurrency(cents: Int64) -> String {
        let value = Double(cents) / 100.0
        return value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

#Preview {
    // Preview uses a dummy in-memory repo.
    struct DummyRepo: TransactionRepository {
        func list() throws -> [Transaction] { [] }
        func add(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64 { 1 }
        func delete(id: Int64) throws {}
    }

    NavigationStack {
        HomeView(repository: DummyRepo(), onAdd: {})
    }
}

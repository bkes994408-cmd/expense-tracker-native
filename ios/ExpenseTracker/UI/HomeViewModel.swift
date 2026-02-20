import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published var errorMessage: String?

    private let listUseCase: ListTransactionsUseCase
    private let deleteUseCase: DeleteTransactionUseCase

    init(repository: TransactionRepository) {
        self.listUseCase = ListTransactionsUseCase(repository: repository)
        self.deleteUseCase = DeleteTransactionUseCase(repository: repository)
    }

    func load() {
        Task.detached(priority: .userInitiated) { [listUseCase] in
            do {
                let loaded = try listUseCase()
                await MainActor.run {
                    self.transactions = loaded
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(describing: error)
                }
            }
        }
    }

    func delete(id: Int64) {
        Task.detached(priority: .userInitiated) { [deleteUseCase, listUseCase] in
            do {
                try deleteUseCase(id: id)
                let loaded = try listUseCase()
                await MainActor.run {
                    self.transactions = loaded
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(describing: error)
                }
            }
        }
    }
}

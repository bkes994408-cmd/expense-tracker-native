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
        do {
            transactions = try listUseCase()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func delete(id: Int64) {
        do {
            try deleteUseCase(id: id)
            load()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

import Foundation

struct ListTransactionsUseCase {
    let repository: TransactionRepository

    func callAsFunction() throws -> [Transaction] {
        try repository.list()
    }
}

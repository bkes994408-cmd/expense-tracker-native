import Foundation

struct DeleteTransactionUseCase {
    let repository: TransactionRepository

    func callAsFunction(id: Int64) throws {
        try repository.delete(id: id)
    }
}

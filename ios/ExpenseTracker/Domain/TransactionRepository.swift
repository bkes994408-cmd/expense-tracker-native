import Foundation

protocol TransactionRepository {
    func list() throws -> [Transaction]
    func add(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64
    func delete(id: Int64) throws
}

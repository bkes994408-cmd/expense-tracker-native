import Foundation

struct AddTransactionUseCase {
    let repository: TransactionRepository

    func callAsFunction(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64 {
        precondition(amountCents != 0, "amountCents must not be 0")
        return try repository.add(amountCents: amountCents, note: note.trimmingCharacters(in: .whitespacesAndNewlines), occurredAt: occurredAt)
    }
}

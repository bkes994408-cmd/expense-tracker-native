import Foundation

enum AddTransactionValidationError: LocalizedError, Equatable {
    case zeroAmount

    var errorDescription: String? {
        switch self {
        case .zeroAmount:
            return "Amount must not be zero."
        }
    }
}

struct AddTransactionUseCase {
    let repository: TransactionRepository

    func callAsFunction(amountCents: Int64, note: String, occurredAt: Date) throws -> Int64 {
        guard amountCents != 0 else {
            throw AddTransactionValidationError.zeroAmount
        }
        return try repository.add(amountCents: amountCents, note: note.trimmingCharacters(in: .whitespacesAndNewlines), occurredAt: occurredAt)
    }
}

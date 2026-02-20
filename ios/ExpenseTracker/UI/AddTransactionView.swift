import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    let repository: TransactionRepository
    let onSaved: () -> Void

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Amount") {
                TextField("e.g. 12.34", text: $amountText)
                    .keyboardType(.decimalPad)
            }

            Section("Note") {
                TextField("Optional", text: $note)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                Button("Save") { save() }
                    .disabled(amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Add")
    }

    private func save() {
        do {
            let cents = try parseAmountToCents(amountText)
            _ = try AddTransactionUseCase(repository: repository)(
                amountCents: cents,
                note: note,
                occurredAt: .now
            )
            errorMessage = nil
            onSaved()
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    private func parseAmountToCents(_ input: String) throws -> Int64 {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AmountParseError.invalidNumber
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) else {
            throw AmountParseError.invalidNumber
        }

        var centsDecimal = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &centsDecimal, 0, .plain) // round half up

        let number = NSDecimalNumber(decimal: rounded)
        let max = NSDecimalNumber(value: Int64.max)
        let min = NSDecimalNumber(value: Int64.min)
        guard number.compare(max) != .orderedDescending, number.compare(min) != .orderedAscending else {
            throw AmountParseError.outOfRange
        }
        return number.int64Value
    }
}

private enum AmountParseError: LocalizedError {
    case invalidNumber
    case outOfRange

    var errorDescription: String? {
        switch self {
        case .invalidNumber:
            return "Please enter a valid amount."
        case .outOfRange:
            return "Amount is out of supported range."
        }
    }
}

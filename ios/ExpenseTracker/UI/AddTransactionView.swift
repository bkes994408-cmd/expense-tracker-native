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
            let amount = Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let cents = Int64((amount * 100).rounded())
            _ = try AddTransactionUseCase(repository: repository)(
                amountCents: cents,
                note: note,
                occurredAt: .now
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

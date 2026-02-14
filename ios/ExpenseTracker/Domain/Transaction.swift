import Foundation

struct Transaction: Identifiable, Equatable {
    let id: Int64
    var amountCents: Int64
    var note: String
    var occurredAt: Date
}

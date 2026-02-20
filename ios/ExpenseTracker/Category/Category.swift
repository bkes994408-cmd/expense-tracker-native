import Foundation

struct Category: Identifiable, Equatable {
    let id: Int64
    let name: String
    let isArchived: Bool
    let sortOrder: Int
}

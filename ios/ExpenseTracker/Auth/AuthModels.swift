import Foundation

struct AuthUser: Equatable {
    let id: UUID
    let email: String
    let displayName: String
}

enum AuthMode: Hashable {
    case login
    case register
}

import Foundation

protocol AuthService {
    func register(email: String, password: String, displayName: String) throws -> AuthUser
    func login(email: String, password: String) throws -> AuthUser
    func logout()
    func currentUser() -> AuthUser?
}

enum AuthError: LocalizedError {
    case invalidInput
    case userExists
    case userNotFound
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .invalidInput: return String(localized: "auth.error.invalidInput")
        case .userExists: return String(localized: "auth.error.userExists")
        case .userNotFound: return String(localized: "auth.error.userNotFound")
        case .wrongPassword: return String(localized: "auth.error.wrongPassword")
        }
    }
}

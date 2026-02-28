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
        case .invalidInput: return "請輸入有效帳號密碼"
        case .userExists: return "此 Email 已註冊"
        case .userNotFound: return "找不到使用者"
        case .wrongPassword: return "密碼錯誤"
        }
    }
}

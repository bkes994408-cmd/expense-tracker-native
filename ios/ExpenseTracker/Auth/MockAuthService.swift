import Foundation

final class MockAuthService: AuthService {
    private struct Account {
        let user: AuthUser
        let password: String
    }

    private var accountsByEmail: [String: Account] = [:]
    private var signedInUser: AuthUser?

    func register(email: String, password: String, displayName: String) throws -> AuthUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedEmail.contains("@"), trimmedPassword.count >= 4 else { throw AuthError.invalidInput }
        guard accountsByEmail[normalizedEmail] == nil else { throw AuthError.userExists }

        let user = AuthUser(id: UUID(), email: normalizedEmail, displayName: name.isEmpty ? "User" : name)
        accountsByEmail[normalizedEmail] = Account(user: user, password: trimmedPassword)
        signedInUser = user
        return user
    }

    func login(email: String, password: String) throws -> AuthUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let account = accountsByEmail[normalizedEmail] else { throw AuthError.userNotFound }
        guard account.password == trimmedPassword else { throw AuthError.wrongPassword }

        signedInUser = account.user
        return account.user
    }

    func logout() {
        signedInUser = nil
    }

    func currentUser() -> AuthUser? {
        signedInUser
    }
}

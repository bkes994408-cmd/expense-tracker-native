import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mode: AuthMode = .login
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var currentUser: AuthUser?
    @Published var statusMessage: String?
    @Published var auditLogMessage: String?

    private let service: AuthService

    var isAuthenticated: Bool { currentUser != nil }

    init(service: AuthService) {
        self.service = service
        self.currentUser = service.currentUser()
    }

    func submit() {
        do {
            switch mode {
            case .register:
                currentUser = try service.register(email: email, password: password, displayName: displayName)
                statusMessage = String(localized: "auth.registerSuccess")
            case .login:
                currentUser = try service.login(email: email, password: password)
                statusMessage = String(localized: "auth.loginSuccess")
            }
            auditLogMessage = SecurityLogRedactor.redact(
                "auth success for \(email) token=\(password)",
                email: email,
                token: password
            )
            password = ""
        } catch {
            statusMessage = (error as? LocalizedError)?.errorDescription ?? String(localized: "auth.failed")
            auditLogMessage = SecurityLogRedactor.redact(
                "auth failed for \(email) token=\(password)",
                email: email,
                token: password
            )
        }
    }

    func logout() {
        service.logout()
        currentUser = nil
        statusMessage = String(localized: "auth.logoutSuccess")
        auditLogMessage = "auth logout"
    }
}

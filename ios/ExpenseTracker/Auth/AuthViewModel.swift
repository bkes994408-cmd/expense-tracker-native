import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var mode: AuthMode = .login
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var currentUser: AuthUser?
    @Published var statusMessage: String?

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
                statusMessage = "註冊成功"
            case .login:
                currentUser = try service.login(email: email, password: password)
                statusMessage = "登入成功"
            }
            password = ""
        } catch {
            statusMessage = (error as? LocalizedError)?.errorDescription ?? "驗證失敗"
        }
    }

    func logout() {
        service.logout()
        currentUser = nil
        statusMessage = "已登出"
    }
}

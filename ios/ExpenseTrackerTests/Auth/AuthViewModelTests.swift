import XCTest
@testable import ExpenseTracker

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testRegisterThenLogoutFlow() {
        let service = MockAuthService()
        let vm = AuthViewModel(service: service)

        vm.mode = .register
        vm.email = "demo@example.com"
        vm.password = "1234"
        vm.displayName = "Demo"
        vm.submit()

        XCTAssertEqual(vm.currentUser?.email, "demo@example.com")
        XCTAssertTrue(vm.isAuthenticated)

        vm.logout()

        XCTAssertFalse(vm.isAuthenticated)
    }

    func testLogRedactorMasksEmail() {
        XCTAssertEqual(SecurityLogRedactor.maskEmail("demo@example.com"), "d***@example.com")
        XCTAssertEqual(SecurityLogRedactor.maskEmail("invalid"), "***")
    }

    func testLogRedactorMasksToken() {
        XCTAssertEqual(SecurityLogRedactor.maskToken("abcdef123456"), "abc***456")
        XCTAssertEqual(SecurityLogRedactor.maskToken("short"), "***")
    }

    func testSubmitProducesSanitizedAuditLog() {
        let service = MockAuthService()
        let vm = AuthViewModel(service: service)

        vm.mode = .register
        vm.email = "demo@example.com"
        vm.password = "abcdef123456"
        vm.displayName = "Demo"
        vm.submit()

        XCTAssertEqual(vm.auditLogMessage, "auth success for d***@example.com token=abc***456")
    }
}

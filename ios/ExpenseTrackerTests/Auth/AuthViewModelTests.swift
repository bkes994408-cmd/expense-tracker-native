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
}

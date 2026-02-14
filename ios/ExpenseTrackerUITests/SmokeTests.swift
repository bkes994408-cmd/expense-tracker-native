import XCTest

final class SmokeTests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        // Basic smoke assertion: home screen content exists.
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5) || app.staticTexts["No transactions yet"].exists)
    }
}

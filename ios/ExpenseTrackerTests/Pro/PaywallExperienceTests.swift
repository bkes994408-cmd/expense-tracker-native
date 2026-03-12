import XCTest
@testable import ExpenseTracker

final class PaywallExperienceTests: XCTestCase {
    func testBudgetTriggerShowsBudgetHeadlineAndYearlyRecommendation() {
        let content = PaywallExperience.content(for: "budget_limit")

        XCTAssertEqual(content.headline, "解鎖不限分類預算")
        XCTAssertTrue(content.recommendedPlanLabel.contains("年付"))
    }

    func testAdvancedReportTriggerShowsTrendMessage() {
        let content = PaywallExperience.content(for: "advanced_report_3m")

        XCTAssertEqual(content.headline, "解鎖長區間趨勢分析")
        XCTAssertTrue(content.subheadline.contains("3/6/12"))
    }
}

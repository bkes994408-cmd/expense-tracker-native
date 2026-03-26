import XCTest
@testable import ExpenseTracker

final class ExpenseAIIntelligenceTests: XCTestCase {
    func testKeywordCategorizerMatchesTransport() {
        let categorizer = KeywordExpenseCategorizer()

        let prediction = categorizer.predictCategory(for: "Uber to office")

        XCTAssertEqual(prediction.category, "交通")
        XCTAssertEqual(prediction.source, .heuristic)
    }

    func testBuildBudgetDraftIncludesTrend() {
        let now = Date(timeIntervalSince1970: 1773984000) // 2026-03-19
        let expenses = [
            Expense(id: 1, title: "Food", amount: -200, createdAt: now.addingTimeInterval(-60 * 60 * 24 * 30), categoryId: 10),
            Expense(id: 2, title: "Food", amount: -400, createdAt: now.addingTimeInterval(-60 * 60 * 24 * 60), categoryId: 10),
            Expense(id: 3, title: "Food", amount: -600, createdAt: now.addingTimeInterval(-60 * 60 * 24 * 90), categoryId: 10)
        ]

        let drafts = ExpenseAIIntelligence.buildBudgetDraft(from: expenses, at: now)

        XCTAssertFalse(drafts.isEmpty)
        XCTAssertEqual(drafts.first?.category, "分類#10")
    }

    func testForecastOverspendReturnsHighRiskItem() {
        let now = Date(timeIntervalSince1970: 1773984000)
        let drafts = [
            BudgetDraftSuggestion(id: "分類#10", category: "分類#10", baseline: 1000, trend: 100, suggestedBudget: 1200)
        ]
        let expenses = [
            Expense(id: 1, title: "Food", amount: -1100, createdAt: now.addingTimeInterval(-60 * 60 * 24 * 2), categoryId: 10)
        ]

        let forecasts = ExpenseAIIntelligence.forecastOverspend(from: expenses, drafts: drafts, at: now)

        XCTAssertTrue(forecasts.contains(where: { $0.category == "分類#10" }))
    }
}

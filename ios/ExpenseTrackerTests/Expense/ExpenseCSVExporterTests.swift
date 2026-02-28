import XCTest
@testable import ExpenseTracker

final class ExpenseCSVExporterTests: XCTestCase {
    func testMakeCSVContainsHeaderAndEscapedRows() {
        let expenses = [
            Expense(id: 1, title: "Lunch, team", amount: 120.5, createdAt: Date(timeIntervalSince1970: 1_700_000_000), categoryId: nil),
            Expense(id: 2, title: "Taxi \"night\"", amount: 350, createdAt: Date(timeIntervalSince1970: 1_700_000_100), categoryId: 9),
        ]

        let csv = ExpenseCSVExporter.makeCSV(expenses: expenses)

        XCTAssertTrue(csv.hasPrefix("id,title,amount,createdAt,categoryId\n"))
        XCTAssertTrue(csv.contains("1,\"Lunch, team\",120.5,"))
        XCTAssertTrue(csv.contains("2,\"Taxi \"\"night\"\"\",350,"))
        XCTAssertTrue(csv.contains(",9\n"))
    }

    func testExportToTemporaryFileWritesUTF8Content() throws {
        let expenses = [Expense(id: 1, title: "早餐", amount: 80, createdAt: Date(), categoryId: nil)]

        let url = try ExpenseCSVExporter.exportToTemporaryFile(expenses: expenses)
        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(content.contains("\"早餐\""))
    }
}

import XCTest
@testable import ExpenseTracker

final class ExpenseCSVExporterTests: XCTestCase {
    func testMakeOFXContainsStatementTransactions() {
        let expenses = [
            Expense(id: 7, title: "午餐", amount: -120, createdAt: Date(timeIntervalSince1970: 1_700_000_000), categoryId: nil),
            Expense(id: 8, title: "薪水", amount: 30_000, createdAt: Date(timeIntervalSince1970: 1_700_086_400), categoryId: nil),
        ]

        let ofx = ExpenseImportExportService.makeOFX(expenses: expenses)

        XCTAssertFalse(ofx.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(ofx.contains("-120"))
        XCTAssertTrue(ofx.contains("午餐"))
    }

    func testParseOFXReturnsImportRows() {
        let content = """
        <OFX>
        <BANKMSGSRSV1>
        <STMTTRNRS>
        <STMTRS>
        <BANKTRANLIST>
        <STMTTRN>
        <TRNTYPE>DEBIT
        <DTPOSTED>20260201090000
        <TRNAMT>-99.5
        <NAME>Coffee
        </STMTTRN>
        <STMTTRN>
        <TRNTYPE>CREDIT
        <DTPOSTED>20260202083000
        <TRNAMT>888
        <MEMO>Refund
        </STMTTRN>
        </BANKTRANLIST>
        </STMTRS>
        </STMTTRNRS>
        </BANKMSGSRSV1>
        </OFX>
        """

        let rows = ExpenseImportExportService.parseOFX(content)

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].title, "Coffee")
        XCTAssertEqual(rows[0].amount, Decimal(string: "-99.5"))
        XCTAssertEqual(rows[1].title, "Refund")
        XCTAssertEqual(rows[1].amount, Decimal(string: "888"))
    }

    func testParseQIFReturnsImportRows() {
        let content = """
        !Type:Bank
        D03/15'26
        T-120.5
        PMorning Coffee
        ^
        D03/16'26
        T30000
        PSalary
        ^
        """

        let rows = ExpenseImportExportService.parseQIF(content)

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].title, "Morning Coffee")
        XCTAssertEqual(rows[0].amount, Decimal(string: "-120.5"))
        XCTAssertEqual(rows[1].title, "Salary")
    }

    func testCSVPreviewMappingAndRowConversion() {
        let csv = """
        txn_date,desc,amt
        2026-03-01,Coffee,-90
        2026-03-02,Salary,30000
        """

        let preview = ExpenseImportExportService.parseCSVPreview(csv)
        let mapping = ExpenseImportExportService.inferCSVMapping(headers: preview.headers)
        let rows = ExpenseImportExportService.mapCSVRows(preview.rows, mapping: mapping)

        XCTAssertEqual(preview.headers, ["txn_date", "desc", "amt"])
        XCTAssertEqual(rows.count, 2)
        guard rows.count == 2 else { return }
        XCTAssertEqual(rows[0].title, "Coffee")
        XCTAssertEqual(rows[0].amount, Decimal(string: "-90"))
    }

    func testImportRowsSkipsDuplicatesFromExistingAndBatch() throws {
        let sameDay = Date(timeIntervalSince1970: 1_700_000_000)
        let store = FakeImportExpenseStore(seed: [
            Expense(id: 1, title: "Coffee", amount: -99.5, createdAt: sameDay, categoryId: nil)
        ])

        let rows = [
            ExpenseImportExportService.ImportRow(title: "Coffee", amount: -99.5, createdAt: sameDay, categoryId: nil),
            ExpenseImportExportService.ImportRow(title: "Taxi", amount: -250, createdAt: sameDay, categoryId: nil),
            ExpenseImportExportService.ImportRow(title: "Taxi", amount: -250, createdAt: sameDay, categoryId: nil)
        ]

        let result = try ExpenseImportExportService.importRows(rows, to: store)

        XCTAssertEqual(result.importedCount, 1)
        XCTAssertEqual(result.duplicateCount, 2)
        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertEqual(store.items.count, 2)
    }
    func testDuplicateSuggestionsDetectExactMatch() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let rows = [ExpenseImportExportService.ImportRow(title: "Coffee", amount: -99.5, createdAt: date, categoryId: nil)]
        let existing = [Expense(id: 1, title: "coffee", amount: -99.5, createdAt: date, categoryId: nil)]

        let suggestions = ExpenseImportExportService.duplicateSuggestions(rows: rows, existing: existing)

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions[0].matchType, .exact)
        XCTAssertEqual(suggestions[0].recommendedAction, .keepExisting)
    }

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

private final class FakeImportExpenseStore: ExpenseStore {
    var items: [Expense]

    init(seed: [Expense]) {
        self.items = seed
    }

    func fetchAll(searchText: String?) throws -> [Expense] {
        items
    }

    func add(title: String, amount: Decimal, categoryId: Int64?, createdAt: Date) throws {
        let nextId = (items.map(\.id).max() ?? 0) + 1
        items.append(Expense(id: nextId, title: title, amount: amount, createdAt: createdAt, categoryId: categoryId))
    }

    func delete(id: Int64) throws {}

    func fetchMonthlyOverview(for month: Date) throws -> MonthlyOverview {
        .empty(month: month)
    }

    func update(id: Int64, title: String, amount: Decimal, categoryId: Int64?) throws {}
}

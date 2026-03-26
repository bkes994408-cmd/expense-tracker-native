import Foundation

enum ExpenseCSVExporter {
    static func makeCSV(expenses: [Expense]) -> String {
        ExpenseImportExportService.makeEnhancedCSV(expenses: expenses)
    }

    static func exportToTemporaryFile(expenses: [Expense]) throws -> URL {
        try ExpenseImportExportService.exportToTemporaryFile(content: makeCSV(expenses: expenses), ext: "csv")
    }
}

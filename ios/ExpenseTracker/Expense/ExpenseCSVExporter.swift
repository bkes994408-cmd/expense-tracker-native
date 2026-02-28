import Foundation

enum ExpenseCSVExporter {
    static func makeCSV(expenses: [Expense]) -> String {
        var lines = ["id,title,amount,createdAt,categoryId"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for expense in expenses {
            let row = [
                String(expense.id),
                escapeCSV(expense.title),
                NSDecimalNumber(decimal: expense.amount).stringValue,
                formatter.string(from: expense.createdAt),
                expense.categoryId.map(String.init) ?? ""
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    static func exportToTemporaryFile(expenses: [Expense]) throws -> URL {
        let content = makeCSV(expenses: expenses)
        let fileName = "expenses-\(timestampForFileName()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func timestampForFileName() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func escapeCSV(_ raw: String) -> String {
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

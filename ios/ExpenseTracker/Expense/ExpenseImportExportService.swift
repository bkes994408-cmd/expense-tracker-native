import Foundation

enum ExpenseImportExportService {
    struct ImportResult {
        let importedCount: Int
        let skippedCount: Int
    }

    struct BudgetSuggestion: Identifiable, Equatable {
        let id: String
        let category: String
        let suggestedBudget: Decimal
        let averageSpend: Decimal
    }

    struct OverspendAlert: Identifiable, Equatable {
        enum Level: String { case warning, danger }

        let id: String
        let category: String
        let spent: Decimal
        let budget: Decimal
        let ratio: Decimal
        let level: Level
    }

    struct ImportRow {
        let title: String
        let amount: Decimal
        let createdAt: Date
        let categoryId: Int64?
    }

    static func makeEnhancedCSV(expenses: [Expense]) -> String {
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

    static func makeJSON(expenses: [Expense]) throws -> String {
        let payload = expenses.map {
            JSONExpense(
                title: $0.title,
                amount: NSDecimalNumber(decimal: $0.amount).stringValue,
                createdAt: iso8601String($0.createdAt),
                categoryId: $0.categoryId
            )
        }
        let data = try JSONEncoder().encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    static func exportToTemporaryFile(content: String, ext: String) throws -> URL {
        let fileName = "expenses-\(timestampForFileName()).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func parseCSV(_ content: String) -> [ImportRow] {
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { return [] }
        let rows = lines.first?.lowercased().contains("title") == true ? Array(lines.dropFirst()) : lines

        return rows.compactMap { line in
            let columns = parseCSVLine(line)
            guard columns.count >= 4 else { return nil }
            return ImportRow(
                title: columns[1],
                amount: Decimal(string: columns[2]) ?? 0,
                createdAt: parseDate(columns[3]),
                categoryId: Int64(columns[safe: 4] ?? "")
            )
        }
    }

    static func parseJSON(_ content: String) -> [ImportRow] {
        guard let data = content.data(using: .utf8),
              let items = try? JSONDecoder().decode([JSONExpense].self, from: data) else {
            return []
        }

        return items.map {
            ImportRow(
                title: $0.title,
                amount: Decimal(string: $0.amount) ?? 0,
                createdAt: parseDate($0.createdAt),
                categoryId: $0.categoryId
            )
        }
    }

    static func importRows(_ rows: [ImportRow], to store: ExpenseStore) throws -> ImportResult {
        var imported = 0
        var skipped = 0

        for row in rows {
            let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, row.amount != 0 else {
                skipped += 1
                continue
            }
            try store.add(title: title, amount: row.amount, categoryId: row.categoryId, createdAt: row.createdAt)
            imported += 1
        }

        return ImportResult(importedCount: imported, skippedCount: skipped)
    }

    static func makeBudgetSuggestion(from expenses: [Expense], at now: Date = Date()) -> [BudgetSuggestion] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        guard let lookbackStart = calendar.date(byAdding: .month, value: -3, to: monthStart) else { return [] }

        var grouped: [String: [Decimal]] = [:]
        for expense in expenses where expense.amount < 0 && expense.createdAt >= lookbackStart && expense.createdAt < monthStart {
            let key = expense.categoryId.map { "分類#\($0)" } ?? "未分類"
            grouped[key, default: []].append(-expense.amount)
        }

        return grouped.map { key, values in
            let total = values.reduce(Decimal.zero, +)
            let avg = values.isEmpty ? Decimal.zero : total / Decimal(values.count)
            let suggested = roundToCurrency(avg * Decimal(string: "1.10")!)
            return BudgetSuggestion(
                id: key,
                category: key,
                suggestedBudget: max(Decimal(500), suggested),
                averageSpend: roundToCurrency(avg)
            )
        }
        .sorted { $0.suggestedBudget > $1.suggestedBudget }
    }

    static func detectOverspend(currentMonthExpenses: [Expense], suggestions: [BudgetSuggestion]) -> [OverspendAlert] {
        var spentByCategory: [String: Decimal] = [:]
        for expense in currentMonthExpenses where expense.amount < 0 {
            let key = expense.categoryId.map { "分類#\($0)" } ?? "未分類"
            spentByCategory[key, default: .zero] += -expense.amount
        }

        return suggestions.compactMap { suggestion in
            let spent = spentByCategory[suggestion.category] ?? 0
            guard suggestion.suggestedBudget > 0 else { return nil }
            let ratio = spent / suggestion.suggestedBudget
            if ratio >= 1 {
                return OverspendAlert(
                    id: suggestion.id,
                    category: suggestion.category,
                    spent: roundToCurrency(spent),
                    budget: suggestion.suggestedBudget,
                    ratio: ratio,
                    level: .danger
                )
            }
            if ratio >= Decimal(string: "0.8")! {
                return OverspendAlert(
                    id: suggestion.id,
                    category: suggestion.category,
                    spent: roundToCurrency(spent),
                    budget: suggestion.suggestedBudget,
                    ratio: ratio,
                    level: .warning
                )
            }
            return nil
        }
        .sorted { $0.ratio > $1.ratio }
    }

    private struct JSONExpense: Codable {
        let title: String
        let amount: String
        let createdAt: String
        let categoryId: Int64?
    }

    private static func timestampForFileName() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func parseDate(_ raw: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw) ?? Date()
    }

    private static func iso8601String(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func escapeCSV(_ raw: String) -> String {
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var idx = 0

        while idx < chars.count {
            let char = chars[idx]
            if char == "\"" {
                if inQuotes, idx + 1 < chars.count, chars[idx + 1] == "\"" {
                    current.append("\"")
                    idx += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == ",", !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
            idx += 1
        }
        fields.append(current)
        return fields
    }

    private static func roundToCurrency(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

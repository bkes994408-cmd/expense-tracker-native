import Foundation

enum ExpenseImportExportService {
    struct ImportResult {
        let importedCount: Int
        let skippedCount: Int
        let duplicateCount: Int

        init(importedCount: Int, skippedCount: Int, duplicateCount: Int = 0) {
            self.importedCount = importedCount
            self.skippedCount = skippedCount
            self.duplicateCount = duplicateCount
        }
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

    enum ImportFormat: String {
        case csv
        case ofx
        case qif
        case json
    }

    struct CSVColumnMapping: Equatable {
        enum Field: String, CaseIterable, Identifiable {
            case title
            case amount
            case createdAt
            case categoryId

            var id: String { rawValue }
            var label: String {
                switch self {
                case .title: return "標題"
                case .amount: return "金額"
                case .createdAt: return "日期"
                case .categoryId: return "分類 ID"
                }
            }
        }

        var titleIndex: Int?
        var amountIndex: Int?
        var createdAtIndex: Int?
        var categoryIdIndex: Int?

        subscript(field: Field) -> Int? {
            get {
                switch field {
                case .title: return titleIndex
                case .amount: return amountIndex
                case .createdAt: return createdAtIndex
                case .categoryId: return categoryIdIndex
                }
            }
            set {
                switch field {
                case .title: titleIndex = newValue
                case .amount: amountIndex = newValue
                case .createdAt: createdAtIndex = newValue
                case .categoryId: categoryIdIndex = newValue
                }
            }
        }

        static let empty = CSVColumnMapping(titleIndex: nil, amountIndex: nil, createdAtIndex: nil, categoryIdIndex: nil)
    }

    struct DuplicateMergeSuggestion: Identifiable {
        enum MatchType: String {
            case exact
            case near
        }

        enum MergeAction: String, CaseIterable, Identifiable {
            case keepExisting
            case replaceExisting
            case importAsNew

            var id: String { rawValue }

            var label: String {
                switch self {
                case .keepExisting: return "保留既有"
                case .replaceExisting: return "以匯入資料覆蓋"
                case .importAsNew: return "仍匯入新交易"
                }
            }
        }

        let id: String
        let matchType: MatchType
        let similarityScore: Decimal
        let incoming: ImportRow
        let existing: Expense
        var recommendedAction: MergeAction
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

    static func makeOFX(expenses: [Expense]) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmmss"

        let dtServer = formatter.string(from: Date())
        let dtStart = formatter.string(from: expenses.map(\.createdAt).min() ?? Date())
        let dtEnd = formatter.string(from: expenses.map(\.createdAt).max() ?? Date())

        let transactions = expenses.sorted { $0.createdAt < $1.createdAt }.map { expense in
            let type = expense.amount < 0 ? "DEBIT" : "CREDIT"
            let amount = NSDecimalNumber(decimal: expense.amount).stringValue
            let date = formatter.string(from: expense.createdAt)
            let name = xmlEscaped(expense.title)
            return """
            <STMTTRN>
            <TRNTYPE>\(type)
            <DTPOSTED>\(date)
            <TRNAMT>\(amount)
            <FITID>exp-\(expense.id)-\(date)
            <NAME>\(name)
            </STMTTRN>
            """
        }.joined(separator: "\n")

        return """
        OFXHEADER:100
        DATA:OFXSGML
        VERSION:102
        SECURITY:NONE
        ENCODING:UTF-8
        CHARSET:UTF-8
        COMPRESSION:NONE
        OLDFILEUID:NONE
        NEWFILEUID:NONE

        <OFX>
        <SIGNONMSGSRSV1>
        <SONRS>
        <STATUS><CODE>0<SEVERITY>INFO</STATUS>
        <DTSERVER>\(dtServer)
        <LANGUAGE>ENG
        </SONRS>
        </SIGNONMSGSRSV1>
        <BANKMSGSRSV1>
        <STMTTRNRS>
        <TRNUID>1
        <STATUS><CODE>0<SEVERITY>INFO</STATUS>
        <STMTRS>
        <CURDEF>TWD
        <BANKTRANLIST>
        <DTSTART>\(dtStart)
        <DTEND>\(dtEnd)
        \(transactions)
        </BANKTRANLIST>
        </STMTRS>
        </STMTTRNRS>
        </BANKMSGSRSV1>
        </OFX>
        """
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

    static func detectImportFormat(fileName: String) -> ImportFormat {
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        switch ext {
        case "csv": return .csv
        case "ofx": return .ofx
        case "qif": return .qif
        case "json": return .json
        default: return .csv
        }
    }

    static func parseCSVPreview(_ content: String) -> (headers: [String], rows: [[String]]) {
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { return ([], []) }

        let allRows = lines.map(parseCSVLine)
        let hasHeader = looksLikeHeader(allRows[0])
        let headers = hasHeader
            ? allRows[0]
            : allRows[0].indices.map { "欄位\($0 + 1)" }
        let rows = hasHeader ? Array(allRows.dropFirst()) : allRows
        return (headers, rows)
    }

    static func inferCSVMapping(headers: [String]) -> CSVColumnMapping {
        func find(_ keywords: [String]) -> Int? {
            headers.firstIndex { header in
                let normalized = header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return keywords.contains { normalized.contains($0) }
            }
        }

        return CSVColumnMapping(
            titleIndex: find(["title", "name", "memo", "description", "desc", "標題"]),
            amountIndex: find(["amount", "amt", "money", "金額"]),
            createdAtIndex: find(["date", "created", "time", "posted", "日期"]),
            categoryIdIndex: find(["category", "分類"])
        )
    }

    static func parseCSV(_ content: String) -> [ImportRow] {
        let preview = parseCSVPreview(content)
        let mapping = inferCSVMapping(headers: preview.headers)
        return mapCSVRows(preview.rows, mapping: mapping)
    }

    static func mapCSVRows(_ rows: [[String]], mapping: CSVColumnMapping) -> [ImportRow] {
        rows.compactMap { columns in
            guard let titleIndex = mapping.titleIndex,
                  let amountIndex = mapping.amountIndex,
                  let dateIndex = mapping.createdAtIndex
            else { return nil }

            return ImportRow(
                title: columns[safe: titleIndex] ?? "",
                amount: Decimal(string: columns[safe: amountIndex] ?? "") ?? 0,
                createdAt: parseDate(columns[safe: dateIndex] ?? ""),
                categoryId: mapping.categoryIdIndex.flatMap { Int64(columns[safe: $0] ?? "") }
            )
        }
    }

    static func parseOFX(_ content: String) -> [ImportRow] {
        let blocks = content.components(separatedBy: "<STMTTRN>")
            .dropFirst()
            .map { segment in
                segment.components(separatedBy: "</STMTTRN>").first ?? segment
            }

        return blocks.compactMap { block in
            let amountRaw = extractOFXField("TRNAMT", from: block)
            let dateRaw = extractOFXField("DTPOSTED", from: block)
            let name = extractOFXField("NAME", from: block) ?? extractOFXField("MEMO", from: block) ?? ""

            guard let amountRaw, let dateRaw else { return nil }
            let amount = Decimal(string: amountRaw.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .zero
            let createdAt = parseOFXDate(dateRaw)

            return ImportRow(
                title: name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                createdAt: createdAt,
                categoryId: nil
            )
        }
    }

    static func parseQIF(_ content: String) -> [ImportRow] {
        let blocks = content
            .components(separatedBy: "^")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return blocks.compactMap { block in
            var title = ""
            var amount: Decimal = .zero
            var createdAt = Date()

            for line in block.split(whereSeparator: \.isNewline).map(String.init) {
                guard let type = line.first else { continue }
                let value = String(line.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)

                switch type {
                case "D": createdAt = parseQIFDate(value)
                case "T": amount = Decimal(string: value.replacingOccurrences(of: ",", with: "")) ?? .zero
                case "P", "M": if title.isEmpty { title = value }
                default: break
                }
            }

            guard !title.isEmpty, amount != .zero else { return nil }
            return ImportRow(title: title, amount: amount, createdAt: createdAt, categoryId: nil)
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

    static func parseImportContent(_ content: String, format: ImportFormat, csvMapping: CSVColumnMapping? = nil) -> [ImportRow] {
        switch format {
        case .csv:
            if let csvMapping {
                return mapCSVRows(parseCSVPreview(content).rows, mapping: csvMapping)
            }
            return parseCSV(content)
        case .ofx: return parseOFX(content)
        case .qif: return parseQIF(content)
        case .json: return parseJSON(content)
        }
    }

    static func duplicateSuggestions(rows: [ImportRow], existing: [Expense]) -> [DuplicateMergeSuggestion] {
        var suggestions: [DuplicateMergeSuggestion] = []

        for row in rows {
            for expense in existing {
                let score = duplicateScore(row: row, expense: expense)
                guard score >= Decimal(string: "0.75")! else { continue }
                let matchType: DuplicateMergeSuggestion.MatchType = score >= Decimal(string: "0.95")! ? .exact : .near
                let recommended: DuplicateMergeSuggestion.MergeAction = matchType == .exact ? .keepExisting : .replaceExisting
                suggestions.append(
                    DuplicateMergeSuggestion(
                        id: "\(expense.id)-\(duplicateKey(for: row))",
                        matchType: matchType,
                        similarityScore: score,
                        incoming: row,
                        existing: expense,
                        recommendedAction: recommended
                    )
                )
                break
            }
        }

        return suggestions
    }

    static func importRows(
        _ rows: [ImportRow],
        to store: ExpenseStore,
        mergeSuggestions: [DuplicateMergeSuggestion] = []
    ) throws -> ImportResult {
        var imported = 0
        var skipped = 0
        var duplicates = 0

        let suggestionMap = Dictionary(uniqueKeysWithValues: mergeSuggestions.map { (duplicateKey(for: $0.incoming), $0) })
        let existing = (try? store.fetchAll(searchText: nil)) ?? []
        var seenKeys = Set(existing.map(duplicateKey(for:)))

        for row in rows {
            let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, row.amount != 0 else {
                skipped += 1
                continue
            }

            let key = duplicateKey(for: row)
            if seenKeys.contains(key) {
                if let suggestion = suggestionMap[key], suggestion.recommendedAction == .replaceExisting {
                    try store.update(id: suggestion.existing.id, title: title, amount: row.amount, categoryId: row.categoryId)
                    imported += 1
                } else if suggestionMap[key]?.recommendedAction == .importAsNew {
                    try store.add(title: title, amount: row.amount, categoryId: row.categoryId, createdAt: row.createdAt)
                    imported += 1
                } else {
                    duplicates += 1
                }
                continue
            }

            try store.add(title: title, amount: row.amount, categoryId: row.categoryId, createdAt: row.createdAt)
            seenKeys.insert(key)
            imported += 1
        }

        return ImportResult(importedCount: imported, skippedCount: skipped, duplicateCount: duplicates)
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

    private static func looksLikeHeader(_ row: [String]) -> Bool {
        let normalized = row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let keywords = ["title", "name", "amount", "date", "category", "標題", "金額", "日期", "分類"]
        return normalized.contains { value in
            keywords.contains { value.contains($0) }
        }
    }

    private static func parseQIFDate(_ raw: String) -> Date {
        let candidates = ["MM/dd'yy", "MM/dd/yyyy", "yyyy-MM-dd", "dd/MM/yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        for format in candidates {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) { return date }
        }

        return Date()
    }

    private static func duplicateScore(row: ImportRow, expense: Expense) -> Decimal {
        let amountDistance = absDecimal(row.amount - expense.amount)
        let amountScore: Decimal = amountDistance <= Decimal(string: "0.01")! ? 1 : (amountDistance <= 1 ? Decimal(string: "0.8")! : 0)

        let titleScore: Decimal = normalizeTitle(row.title) == normalizeTitle(expense.title) ? 1 : (normalizeTitle(row.title).contains(normalizeTitle(expense.title)) || normalizeTitle(expense.title).contains(normalizeTitle(row.title)) ? Decimal(string: "0.75")! : 0)

        let dayDiff = abs(Calendar.current.dateComponents([.day], from: row.createdAt, to: expense.createdAt).day ?? 999)
        let dateScore: Decimal = dayDiff == 0 ? 1 : (dayDiff <= 1 ? Decimal(string: "0.8")! : 0)

        return roundToCurrency((amountScore * Decimal(string: "0.5")!) + (titleScore * Decimal(string: "0.3")!) + (dateScore * Decimal(string: "0.2")!))
    }

    private static func absDecimal(_ value: Decimal) -> Decimal {
        value < 0 ? -value : value
    }

    private static func duplicateKey(for row: ImportRow) -> String {
        let amount = normalizeAmountString(row.amount)
        let title = normalizeTitle(row.title)
        let day = duplicateDayString(from: row.createdAt)
        let category = row.categoryId.map(String.init) ?? "nil"
        return "\(title)|\(amount)|\(day)|\(category)"
    }

    private static func duplicateKey(for expense: Expense) -> String {
        let amount = normalizeAmountString(expense.amount)
        let title = normalizeTitle(expense.title)
        let day = duplicateDayString(from: expense.createdAt)
        let category = expense.categoryId.map(String.init) ?? "nil"
        return "\(title)|\(amount)|\(day)|\(category)"
    }

    private static func duplicateDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private static func normalizeTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private static func normalizeAmountString(_ amount: Decimal) -> String {
        var rounded = Decimal()
        var input = amount
        NSDecimalRound(&rounded, &input, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }

    private static func extractOFXField(_ field: String, from block: String) -> String? {
        guard let range = block.range(of: "<\(field)>", options: .caseInsensitive) else { return nil }
        let tail = block[range.upperBound...]
        if let lineEnd = tail.firstIndex(where: \.isNewline) {
            return String(tail[..<lineEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let candidates: [Character] = ["<", "\r"]
        let endIndex = candidates.compactMap { token in
            tail.firstIndex(of: token)
        }.min() ?? tail.endIndex

        return String(tail[..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseOFXDate(_ raw: String) -> Date {
        let digits = raw.prefix(14)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = digits.count >= 14 ? "yyyyMMddHHmmss" : "yyyyMMdd"

        if digits.count >= 14, let date = formatter.date(from: String(digits)) {
            return date
        }

        let day = raw.prefix(8)
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: String(day)) ?? Date()
    }

    private static func xmlEscaped(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
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

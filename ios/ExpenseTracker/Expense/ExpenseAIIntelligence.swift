import Foundation
#if canImport(CoreML)
import CoreML
#endif

enum ModelSource: String {
    case coreML
    case heuristic
}

struct CategoryPrediction: Equatable {
    let category: String
    let confidence: Decimal
    let source: ModelSource
}

protocol OnDeviceExpenseCategorizing {
    func predictCategory(for title: String) -> CategoryPrediction
}

struct HybridOnDeviceExpenseCategorizer: OnDeviceExpenseCategorizing {
    private let coreML: CoreMLExpenseCategorizer
    private let fallback: KeywordExpenseCategorizer

    init(modelName: String = "ExpenseCategoryClassifier") {
        self.coreML = CoreMLExpenseCategorizer(modelName: modelName)
        self.fallback = KeywordExpenseCategorizer()
    }

    func predictCategory(for title: String) -> CategoryPrediction {
        if let prediction = coreML.predictIfAvailable(for: title) {
            return prediction
        }
        return fallback.predictCategory(for: title)
    }
}

struct KeywordExpenseCategorizer: OnDeviceExpenseCategorizing {
    func predictCategory(for title: String) -> CategoryPrediction {
        let text = title.lowercased()
        let category: String
        switch true {
        case text.contains("uber"), text.contains("taxi"), text.contains("捷運"), text.contains("公車"):
            category = "交通"
        case text.contains("早餐"), text.contains("午餐"), text.contains("晚餐"), text.contains("咖啡"), text.contains("food"):
            category = "餐飲"
        case text.contains("netflix"), text.contains("spotify"), text.contains("電影"), text.contains("遊戲"):
            category = "娛樂"
        case text.contains("房租"), text.contains("電費"), text.contains("水費"):
            category = "居家"
        case text.contains("診所"), text.contains("醫院"), text.contains("藥"):
            category = "醫療"
        default:
            category = "未分類"
        }

        return CategoryPrediction(
            category: category,
            confidence: category == "未分類" ? Decimal(string: "0.45")! : Decimal(string: "0.78")!,
            source: .heuristic
        )
    }
}

struct CoreMLExpenseCategorizer {
    let modelName: String

    func predictIfAvailable(for title: String) -> CategoryPrediction? {
        #if canImport(CoreML)
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            return nil
        }

        guard let model = try? MLModel(contentsOf: modelURL),
              let input = try? MLDictionaryFeatureProvider(dictionary: ["text": title]),
              let output = try? model.prediction(from: input),
              let category = output.featureValue(for: "label")?.stringValue,
              let confidenceDict = output.featureValue(for: "labelProbabilities")?.dictionaryValue as? [String: Double]
        else {
            return nil
        }

        let confidence = Decimal(confidenceDict[category] ?? 0)
        return CategoryPrediction(category: category, confidence: confidence, source: .coreML)
        #else
        return nil
        #endif
    }
}

struct BudgetDraftSuggestion: Identifiable, Equatable {
    let id: String
    let category: String
    let baseline: Decimal
    let trend: Decimal
    let suggestedBudget: Decimal
}

struct OverspendForecast: Identifiable, Equatable {
    let id: String
    let category: String
    let currentSpent: Decimal
    let projectedMonthSpend: Decimal
    let budget: Decimal
    let riskRatio: Decimal
}

enum ExpenseAIIntelligence {
    static func buildBudgetDraft(from expenses: [Expense], at now: Date = Date()) -> [BudgetDraftSuggestion] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        var categoryMonthBuckets: [String: [Date: Decimal]] = [:]

        for expense in expenses where expense.amount < 0 {
            guard let month = calendar.date(from: calendar.dateComponents([.year, .month], from: expense.createdAt)),
                  month < monthStart,
                  month >= calendar.date(byAdding: .month, value: -6, to: monthStart) ?? monthStart else { continue }
            let category = expense.categoryId.map { "分類#\($0)" } ?? "未分類"
            categoryMonthBuckets[category, default: [:]][month, default: .zero] += -expense.amount
        }

        let weights: [Decimal] = [1, 2, 3, 4, 5, 6]

        return categoryMonthBuckets.compactMap { category, monthMap in
            var monthlyValues: [Decimal] = []
            for offset in stride(from: 6, to: 0, by: -1) {
                guard let month = calendar.date(byAdding: .month, value: -offset, to: monthStart) else { continue }
                monthlyValues.append(monthMap[month] ?? .zero)
            }
            guard monthlyValues.contains(where: { $0 > 0 }) else { return nil }

            let weightedSum = zip(monthlyValues, weights).reduce(Decimal.zero) { $0 + ($1.0 * $1.1) }
            let baseline = weightedSum / weights.reduce(.zero, +)
            let trend = (monthlyValues.last ?? .zero) - (monthlyValues.dropLast().last ?? .zero)
            let suggested = max(Decimal(300), roundToCurrency((baseline * Decimal(string: "1.05")!) + (trend * Decimal(string: "0.30")!)))

            return BudgetDraftSuggestion(
                id: category,
                category: category,
                baseline: roundToCurrency(baseline),
                trend: roundToCurrency(trend * Decimal(string: "0.30")!),
                suggestedBudget: suggested
            )
        }
        .sorted { $0.suggestedBudget > $1.suggestedBudget }
    }

    static func forecastOverspend(from expenses: [Expense], drafts: [BudgetDraftSuggestion], at now: Date = Date()) -> [OverspendForecast] {
        let calendar = Calendar.current
        let day = max(1, calendar.component(.day, from: now))
        let dayCount = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        var currentSpent: [String: Decimal] = [:]

        for expense in expenses where expense.amount < 0 && expense.createdAt >= start {
            let category = expense.categoryId.map { "分類#\($0)" } ?? "未分類"
            currentSpent[category, default: .zero] += -expense.amount
        }

        return drafts.compactMap { draft in
            guard draft.suggestedBudget > 0 else { return nil }
            let spent = currentSpent[draft.category] ?? .zero
            let projected = spent / Decimal(day) * Decimal(dayCount)
            let risk = projected / draft.suggestedBudget
            guard risk >= Decimal(string: "0.8")! else { return nil }

            return OverspendForecast(
                id: draft.id,
                category: draft.category,
                currentSpent: roundToCurrency(spent),
                projectedMonthSpend: roundToCurrency(projected),
                budget: draft.suggestedBudget,
                riskRatio: risk
            )
        }
        .sorted { $0.riskRatio > $1.riskRatio }
    }

    private static func roundToCurrency(_ value: Decimal) -> Decimal {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, 2, .bankers)
        return result
    }
}

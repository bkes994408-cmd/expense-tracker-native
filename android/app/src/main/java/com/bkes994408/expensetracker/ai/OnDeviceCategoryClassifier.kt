package com.bkes994408.expensetracker.ai

import java.util.Locale

/**
 * On-device category classification abstraction.
 *
 * Priority:
 * 1) TFLite model (if loaded)
 * 2) Lightweight keyword fallback (always available)
 */
interface OnDeviceCategoryClassifier {
    fun classify(title: String): Prediction

    data class Prediction(
        val category: String,
        val confidence: Double,
        val source: Source,
    )

    enum class Source {
        TFLITE,
        HEURISTIC,
    }
}

class HybridCategoryClassifier(
    private val tflite: TFLiteCategoryClassifier = TFLiteCategoryClassifier.unavailable(),
    private val fallback: OnDeviceCategoryClassifier = KeywordCategoryClassifier(),
) : OnDeviceCategoryClassifier {
    override fun classify(title: String): OnDeviceCategoryClassifier.Prediction {
        val modelPrediction = tflite.classifyOrNull(title)
        if (modelPrediction != null) {
            return modelPrediction
        }
        return fallback.classify(title)
    }
}

class KeywordCategoryClassifier : OnDeviceCategoryClassifier {
    override fun classify(title: String): OnDeviceCategoryClassifier.Prediction {
        val normalized = title.lowercase(Locale.getDefault())
        val category = when {
            normalized.contains("uber") || normalized.contains("taxi") || normalized.contains("捷運") || normalized.contains("bus") -> "交通"
            normalized.contains("咖啡") || normalized.contains("早餐") || normalized.contains("午餐") || normalized.contains("晚餐") || normalized.contains("food") -> "餐飲"
            normalized.contains("netflix") || normalized.contains("spotify") || normalized.contains("movie") || normalized.contains("遊戲") -> "娛樂"
            normalized.contains("電費") || normalized.contains("水費") || normalized.contains("房租") || normalized.contains("租") -> "居家"
            normalized.contains("診所") || normalized.contains("藥") || normalized.contains("醫院") -> "醫療"
            else -> "未分類"
        }

        val confidence = if (category == "未分類") 0.45 else 0.78
        return OnDeviceCategoryClassifier.Prediction(
            category = category,
            confidence = confidence,
            source = OnDeviceCategoryClassifier.Source.HEURISTIC,
        )
    }
}

class TFLiteCategoryClassifier private constructor() {
    fun classifyOrNull(title: String): OnDeviceCategoryClassifier.Prediction? {
        // Iteration-4: keep contract ready; real model mapping should be injected via assets.
        // Returning null will gracefully fallback to keyword classifier.
        if (title.isBlank()) return null
        return null
    }

    companion object {
        fun unavailable(): TFLiteCategoryClassifier = TFLiteCategoryClassifier()
    }
}

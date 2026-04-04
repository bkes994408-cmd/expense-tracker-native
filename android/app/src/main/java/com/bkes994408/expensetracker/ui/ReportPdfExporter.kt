package com.bkes994408.expensetracker.ui

import android.content.Context
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import com.bkes994408.expensetracker.pro.AdvancedReport
import java.io.File
import java.time.LocalDate

class ReportPdfExporter(private val context: Context) {
    fun exportMonthlyReport(report: AdvancedReport, rangeMonths: Int): String {
        val document = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
        val page = document.startPage(pageInfo)
        val canvas = page.canvas

        val titlePaint = Paint().apply { textSize = 20f; isFakeBoldText = true }
        val bodyPaint = Paint().apply { textSize = 13f }

        var y = 64f
        canvas.drawText("Expense Tracker 月報", 40f, y, titlePaint)
        y += 28f
        canvas.drawText("期間：最近 ${rangeMonths} 個月", 40f, y, bodyPaint)
        y += 24f
        canvas.drawText("產生日期：${LocalDate.now()}", 40f, y, bodyPaint)

        y += 32f
        canvas.drawText("平均月收入：${report.averageIncome}", 40f, y, bodyPaint)
        y += 20f
        canvas.drawText("平均月支出：${report.averageExpense}", 40f, y, bodyPaint)
        y += 20f
        canvas.drawText("平均月淨額：${report.averageNet}", 40f, y, bodyPaint)
        y += 20f
        canvas.drawText("MoM：${report.momDelta ?: "暫無"}", 40f, y, bodyPaint)
        y += 20f
        canvas.drawText("YoY：${report.yoyDelta ?: "暫無"}", 40f, y, bodyPaint)

        y += 28f
        canvas.drawText("趨勢資料", 40f, y, titlePaint)
        y += 24f
        report.monthlyTrend.take(12).forEach { point ->
            canvas.drawText("${point.monthLabel} 收${point.income} / 支${point.expense} / 淨${point.net}", 40f, y, bodyPaint)
            y += 18f
        }

        y += 20f
        canvas.drawText("分類占比（區間累計）", 40f, y, titlePaint)
        y += 22f
        if (report.pieSlices.isEmpty()) {
            canvas.drawText("暫無資料", 40f, y, bodyPaint)
            y += 18f
        } else {
            report.pieSlices.forEach { slice ->
                canvas.drawText("${slice.label}：${slice.value}", 40f, y, bodyPaint)
                y += 18f
            }
        }

        document.finishPage(page)

        val output = File(context.cacheDir, "expense-report-${System.currentTimeMillis()}.pdf")
        output.outputStream().use { document.writeTo(it) }
        document.close()
        return output.absolutePath
    }
}

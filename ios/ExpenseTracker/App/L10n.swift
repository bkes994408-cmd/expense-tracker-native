import Foundation

enum L10n {
    private static var isTraditionalChinese: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
    }

    static func text(_ key: String) -> String {
        if isTraditionalChinese {
            return zhTW[key] ?? en[key] ?? key
        }
        return en[key] ?? key
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }

    private static let en: [String: String] = [
        "home.monthlyOverview": "Monthly Overview",
        "home.income": "Income",
        "home.expense": "Expense",
        "home.net": "Net",
        "home.emptyCategorySummary": "No category summary for this month yet",
        "home.addExpense": "Add Expense",
        "home.titlePlaceholder": "Title (e.g. Dinner)",
        "home.amount": "Amount",
        "home.type": "Type",
        "home.type.expense": "Expense",
        "home.type.income": "Income",
        "home.add": "Add",
        "home.expenseList": "Expense List",
        "home.emptyData": "No data yet",
        "home.searchTitle": "Search title",
        "home.exportCsv": "Export CSV",
        "home.noExportData": "No data available for export",
        "home.exportReady": "Export file is ready: %@",
        "home.settings": "Settings",
        "home.csvAlertTitle": "CSV Export",
        "common.ok": "OK",
        "home.navTitle": "Expense Tracker",
        "common.uncategorized": "Uncategorized",

        "settings.categoryManagement": "Category Management",
        "settings.newCategory": "New category",
        "common.add": "Add",
        "common.archive": "Archive",
        "settings.subscriptionManagement": "Subscription Management",
        "settings.name": "Name",
        "settings.amount": "Amount",
        "settings.cycleDays": "Cycle (days)",
        "settings.nextChargeDate": "Next charge",
        "settings.enableReminder": "Enable reminder",
        "settings.reminderDaysBefore": "Reminder days before",
        "settings.addSubscription": "Add subscription",
        "settings.subscriptionRow": "%@ · %@",
        "settings.subscriptionCycle": "Every %d days, next: %@",
        "settings.installmentManagement": "Installment Management",
        "settings.periodAmount": "Per-period amount",
        "settings.totalPeriods": "Total periods",
        "settings.paidPeriods": "Paid periods",
        "settings.addInstallment": "Add installment",
        "settings.installmentRow": "%@ · Per period %@",
        "settings.installmentStatus": "Paid %d / %d, remaining %d",
        "settings.feedbackSection": "Feedback",
        "settings.feedbackHint": "Tell us what went well or what can be improved.",
        "settings.sendFeedback": "Send Feedback",
        "settings.feedbackAlertTitle": "Feedback",
        "settings.feedbackUnavailable": "Unable to open email app. Please try again later.",
        "settings.about": "About",
        "settings.version": "Version",
        "settings.navTitle": "Settings",

        "auth.mode": "Mode",
        "auth.login": "Login",
        "auth.register": "Register",
        "auth.displayName": "Display name",
        "auth.email": "Email",
        "auth.password": "Password",
        "auth.navTitle": "Account",
        "auth.alertTitle": "Auth",
        "auth.error.invalidInput": "Please enter a valid account and password",
        "auth.error.userExists": "This email has already been registered",
        "auth.error.userNotFound": "User not found",
        "auth.error.wrongPassword": "Wrong password",

        "subscription.reminderOff": "Reminder is off",
        "subscription.reminderOn": "Remind %d day(s) before charge"
    ]

    private static let zhTW: [String: String] = [
        "home.monthlyOverview": "每月總覽",
        "home.income": "收入",
        "home.expense": "支出",
        "home.net": "淨額",
        "home.emptyCategorySummary": "本月尚無分類彙總",
        "home.addExpense": "新增帳目",
        "home.titlePlaceholder": "標題（例如：晚餐）",
        "home.amount": "金額",
        "home.type": "類型",
        "home.type.expense": "支出",
        "home.type.income": "收入",
        "home.add": "新增",
        "home.expenseList": "帳目列表",
        "home.emptyData": "目前沒有資料",
        "home.searchTitle": "搜尋標題",
        "home.exportCsv": "匯出CSV",
        "home.noExportData": "目前沒有可匯出的資料",
        "home.exportReady": "已準備匯出檔案：%@",
        "home.settings": "設定",
        "home.csvAlertTitle": "CSV 匯出",
        "common.ok": "確定",
        "home.navTitle": "記帳小幫手",
        "common.uncategorized": "未分類",

        "settings.categoryManagement": "分類管理",
        "settings.newCategory": "新分類",
        "common.add": "新增",
        "common.archive": "封存",
        "settings.subscriptionManagement": "訂閱管理",
        "settings.name": "名稱",
        "settings.amount": "金額",
        "settings.cycleDays": "週期（天）",
        "settings.nextChargeDate": "下次扣款",
        "settings.enableReminder": "啟用提醒",
        "settings.reminderDaysBefore": "提前提醒天數",
        "settings.addSubscription": "新增訂閱",
        "settings.subscriptionRow": "%@ · %@",
        "settings.subscriptionCycle": "每 %d 天，下一次：%@",
        "settings.installmentManagement": "分期管理",
        "settings.periodAmount": "每期金額",
        "settings.totalPeriods": "總期數",
        "settings.paidPeriods": "已繳期數",
        "settings.addInstallment": "新增分期",
        "settings.installmentRow": "%@ · 每期 %@",
        "settings.installmentStatus": "已繳 %d / %d 期，剩餘 %d 期",
        "settings.feedbackSection": "意見回饋",
        "settings.feedbackHint": "告訴我們哪些地方好用，或有哪些可以改進。",
        "settings.sendFeedback": "送出回饋",
        "settings.feedbackAlertTitle": "意見回饋",
        "settings.feedbackUnavailable": "無法開啟 Email App，請稍後再試。",
        "settings.about": "關於",
        "settings.version": "版本",
        "settings.navTitle": "設定",

        "auth.mode": "模式",
        "auth.login": "登入",
        "auth.register": "註冊",
        "auth.displayName": "顯示名稱",
        "auth.email": "Email",
        "auth.password": "密碼",
        "auth.navTitle": "帳號",
        "auth.alertTitle": "Auth",
        "auth.error.invalidInput": "請輸入有效帳號密碼",
        "auth.error.userExists": "此 Email 已註冊",
        "auth.error.userNotFound": "找不到使用者",
        "auth.error.wrongPassword": "密碼錯誤",

        "subscription.reminderOff": "提醒已關閉",
        "subscription.reminderOn": "扣款前 %d 天提醒"
    ]
}

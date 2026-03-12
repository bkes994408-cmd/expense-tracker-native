import Foundation
import os

enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case expenseAdded = "expense_added"
    case expenseAddInvalid = "expense_add_invalid"
    case expenseDeleted = "expense_deleted"
    case csvExported = "csv_exported"
    case csvExportFailed = "csv_export_failed"
    case proPaywallViewed = "pro_paywall_viewed"
    case proPaywallCtaTapped = "pro_paywall_cta_tapped"
}

protocol AnalyticsService {
    func track(event: AnalyticsEvent, metadata: [String: String])
}

protocol CrashReportingService {
    func install()
    func record(error: Error, fatal: Bool, metadata: [String: String])
    func recordFatal(message: String, metadata: [String: String])
}

final class ConsoleAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "com.bkes994408.expensetracker", category: "analytics")

    func track(event: AnalyticsEvent, metadata: [String: String]) {
        logger.log("event=\(event.rawValue, privacy: .public) metadata=\(String(describing: metadata), privacy: .public)")
    }
}

final class ConsoleCrashReporter: CrashReportingService {
    private let logger = Logger(subsystem: "com.bkes994408.expensetracker", category: "crash")

    func install() {
        NSSetUncaughtExceptionHandler { exception in
            Telemetry.shared.recordFatal(
                message: "\(exception.name.rawValue): \(exception.reason ?? "")",
                metadata: ["source": "uncaught_exception"]
            )
        }
    }

    func record(error: Error, fatal: Bool, metadata: [String: String]) {
        logger.error("fatal=\(fatal, privacy: .public) error=\(error.localizedDescription, privacy: .public) metadata=\(String(describing: metadata), privacy: .public)")
    }

    func recordFatal(message: String, metadata: [String: String]) {
        logger.fault("fatal=1 message=\(message, privacy: .public) metadata=\(String(describing: metadata), privacy: .public)")
    }
}

final class Telemetry {
    static let shared = Telemetry()

    private let analytics: AnalyticsService = ConsoleAnalyticsService()
    private let crashReporter: CrashReportingService = ConsoleCrashReporter()

    private init() {}

    func install() {
        crashReporter.install()
        track(.appLaunched)
    }

    func track(_ event: AnalyticsEvent, metadata: [String: String] = [:]) {
        analytics.track(event: event, metadata: metadata)
    }

    func record(error: Error, fatal: Bool = false, metadata: [String: String] = [:]) {
        crashReporter.record(error: error, fatal: fatal, metadata: metadata)
    }

    func recordFatal(message: String, metadata: [String: String] = [:]) {
        crashReporter.recordFatal(message: message, metadata: metadata)
    }
}

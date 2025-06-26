import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

/// Crash reporting service for automatic error tracking
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class CrashReportingService: ObservableObject {
    public static let shared = CrashReportingService()
    
    // MARK: - Properties
    
    @Published public private(set) var isEnabled = false
    @Published public private(set) var pendingReportsCount = 0
    
    private let logger = Logger(subsystem: "com.homeinventory", category: "CrashReporting")
    private let reportQueue = DispatchQueue(label: "com.homeinventory.crashreporting", qos: .background)
    private let reportDirectory: URL
    private let maxReportsToStore = 100
    private let maxReportAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Initialization
    
    private init() {
        // Set up crash report directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.reportDirectory = documentsPath.appendingPathComponent("CrashReports", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: reportDirectory, withIntermediateDirectories: true)
        
        // Set up exception and signal handlers
        setupCrashHandlers()
        
        // Load pending reports count
        updatePendingReportsCount()
        
        // Clean old reports
        cleanOldReports()
    }
    
    // MARK: - Public Methods
    
    /// Enable or disable crash reporting
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("Crash reporting \(enabled ? "enabled" : "disabled")")
        
        if enabled {
            registerExceptionHandler()
        } else {
            unregisterExceptionHandler()
        }
    }
    
    /// Manually report an error
    public func reportError(
        _ error: Error,
        userInfo: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        
        let report = CrashReport(
            type: .error,
            reason: error.localizedDescription,
            callStack: Thread.callStackSymbols,
            userInfo: userInfo,
            file: file,
            function: function,
            line: line
        )
        
        saveReport(report)
    }
    
    /// Report a non-fatal issue
    public func reportNonFatal(
        _ message: String,
        userInfo: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        
        let report = CrashReport(
            type: .nonFatal,
            reason: message,
            callStack: Thread.callStackSymbols,
            userInfo: userInfo,
            file: file,
            function: function,
            line: line
        )
        
        saveReport(report)
    }
    
    /// Get all pending crash reports
    public func getPendingReports() async -> [CrashReport] {
        await withCheckedContinuation { continuation in
            reportQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                let reports = self.loadPendingReports()
                continuation.resume(returning: reports)
            }
        }
    }
    
    /// Send pending reports to server
    public func sendPendingReports() async throws {
        let reports = await getPendingReports()
        guard !reports.isEmpty else { return }
        
        logger.info("Sending \(reports.count) crash reports")
        
        // In a real app, this would send to a crash reporting service
        // For now, we'll simulate sending
        for report in reports {
            try await sendReport(report)
            deleteReport(report)
        }
        
        await MainActor.run {
            updatePendingReportsCount()
        }
    }
    
    /// Delete all pending reports
    public func clearPendingReports() {
        reportQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.reportDirectory, includingPropertiesForKeys: nil)
                for file in files where file.pathExtension == "crash" {
                    try FileManager.default.removeItem(at: file)
                }
                
                Task { @MainActor in
                    self.pendingReportsCount = 0
                }
            } catch {
                self.logger.error("Failed to clear reports: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCrashHandlers() {
        // Set up signal handlers for crashes
        installSignalHandlers()
    }
    
    private func registerExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let report = CrashReport(
                type: .exception,
                reason: exception.reason ?? "Unknown exception",
                callStack: exception.callStackSymbols,
                userInfo: exception.userInfo as? [String: Any],
                file: nil,
                function: nil,
                line: nil
            )
            
            // Save synchronously since we're about to crash
            CrashReportingService.shared.saveReportSynchronously(report)
        }
    }
    
    private func unregisterExceptionHandler() {
        NSSetUncaughtExceptionHandler(nil)
    }
    
    private func installSignalHandlers() {
        // Install signal handlers for common crash signals
        var action = sigaction()
        action.__sigaction_u.__sa_handler = { signal in
            CrashReportingService.handleSignal(signal, name: CrashReportingService.signalName(for: signal))
        }
        sigemptyset(&action.sa_mask)
        action.sa_flags = 0
        
        sigaction(SIGABRT, &action, nil)
        sigaction(SIGILL, &action, nil)
        sigaction(SIGSEGV, &action, nil)
        sigaction(SIGFPE, &action, nil)
        sigaction(SIGBUS, &action, nil)
        sigaction(SIGPIPE, &action, nil)
    }
    
    private static func signalName(for signal: Int32) -> String {
        switch signal {
        case SIGABRT: return "SIGABRT"
        case SIGILL: return "SIGILL"
        case SIGSEGV: return "SIGSEGV"
        case SIGFPE: return "SIGFPE"
        case SIGBUS: return "SIGBUS"
        case SIGPIPE: return "SIGPIPE"
        default: return "Unknown"
        }
    }
    
    private static func handleSignal(_ signal: Int32, name: String) {
        let report = CrashReport(
            type: .signal,
            reason: "Signal \(name) (\(signal))",
            callStack: Thread.callStackSymbols,
            userInfo: ["signal": signal, "signal_name": name],
            file: nil,
            function: nil,
            line: nil
        )
        
        CrashReportingService.shared.saveReportSynchronously(report)
        
        // Re-raise the signal to let the default handler run
        var action = sigaction()
        action.__sigaction_u.__sa_handler = SIG_DFL
        sigemptyset(&action.sa_mask)
        action.sa_flags = 0
        sigaction(signal, &action, nil)
        raise(signal)
    }
    
    private func saveReport(_ report: CrashReport) {
        reportQueue.async { [weak self] in
            self?.saveReportSynchronously(report)
            
            Task { @MainActor in
                self?.updatePendingReportsCount()
            }
        }
    }
    
    private func saveReportSynchronously(_ report: CrashReport) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            
            let filename = "\(report.id.uuidString).crash"
            let fileURL = reportDirectory.appendingPathComponent(filename)
            
            try data.write(to: fileURL)
            logger.info("Saved crash report: \(report.id)")
        } catch {
            logger.error("Failed to save crash report: \(error)")
        }
    }
    
    private func loadPendingReports() -> [CrashReport] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: reportDirectory, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return files.compactMap { file in
                guard file.pathExtension == "crash" else { return nil }
                
                do {
                    let data = try Data(contentsOf: file)
                    return try decoder.decode(CrashReport.self, from: data)
                } catch {
                    logger.error("Failed to load report \(file.lastPathComponent): \(error)")
                    return nil
                }
            }
        } catch {
            logger.error("Failed to load reports: \(error)")
            return []
        }
    }
    
    private func deleteReport(_ report: CrashReport) {
        let filename = "\(report.id.uuidString).crash"
        let fileURL = reportDirectory.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func updatePendingReportsCount() {
        reportQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.reportDirectory, includingPropertiesForKeys: nil)
                let count = files.filter { $0.pathExtension == "crash" }.count
                
                Task { @MainActor in
                    self.pendingReportsCount = count
                }
            } catch {
                self.logger.error("Failed to count reports: \(error)")
            }
        }
    }
    
    private func cleanOldReports() {
        reportQueue.async { [weak self] in
            guard let self = self else { return }
            
            let reports = self.loadPendingReports()
            let cutoffDate = Date().addingTimeInterval(-self.maxReportAge)
            
            // Delete old reports
            let oldReports = reports.filter { $0.timestamp < cutoffDate }
            for report in oldReports {
                self.deleteReport(report)
            }
            
            // If we still have too many, delete oldest
            let remainingReports = reports.filter { $0.timestamp >= cutoffDate }
                .sorted { $0.timestamp < $1.timestamp }
            
            if remainingReports.count > self.maxReportsToStore {
                let reportsToDelete = remainingReports.prefix(remainingReports.count - self.maxReportsToStore)
                for report in reportsToDelete {
                    self.deleteReport(report)
                }
            }
            
            Task { @MainActor in
                self.updatePendingReportsCount()
            }
        }
    }
    
    private func sendReport(_ report: CrashReport) async throws {
        // In a real app, this would send to a crash reporting service
        // For now, we'll just log it
        logger.info("Would send crash report: \(report.id)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}

// MARK: - CrashReport Model

public struct CrashReport: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: CrashType
    public let reason: String
    public let callStack: [String]
    public let userInfo: [String: String]?
    public let deviceInfo: CrashDeviceInfo
    public let appInfo: AppInfo
    public let sourceLocation: SourceLocation?
    
    init(
        type: CrashType,
        reason: String,
        callStack: [String],
        userInfo: [String: Any]?,
        file: String?,
        function: String?,
        line: Int?
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.reason = reason
        self.callStack = callStack
        self.userInfo = userInfo?.compactMapValues { "\($0)" }
        self.deviceInfo = CrashDeviceInfo.current
        self.appInfo = AppInfo.current
        
        if let file = file, let function = function, let line = line {
            self.sourceLocation = SourceLocation(file: file, function: function, line: line)
        } else {
            self.sourceLocation = nil
        }
    }
}

public enum CrashType: String, Codable {
    case exception
    case signal
    case error
    case nonFatal
}

public struct CrashDeviceInfo: Codable {
    public let model: String
    public let systemName: String
    public let systemVersion: String
    public let isSimulator: Bool
    
    static var current: CrashDeviceInfo {
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        
        #if canImport(UIKit)
        return CrashDeviceInfo(
            model: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            isSimulator: isSimulator
        )
        #else
        return CrashDeviceInfo(
            model: "Unknown",
            systemName: "Unknown",
            systemVersion: "Unknown",
            isSimulator: isSimulator
        )
        #endif
    }
}

public struct AppInfo: Codable {
    public let version: String
    public let build: String
    public let bundleIdentifier: String
    
    static var current: AppInfo {
        let bundle = Bundle.main
        return AppInfo(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown",
            bundleIdentifier: bundle.bundleIdentifier ?? "Unknown"
        )
    }
}

public struct SourceLocation: Codable {
    public let file: String
    public let function: String
    public let line: Int
}
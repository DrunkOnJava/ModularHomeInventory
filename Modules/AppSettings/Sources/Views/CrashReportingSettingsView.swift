import SwiftUI
import Core
import SharedUI

/// Settings view for crash reporting configuration
struct CrashReportingSettingsView: View {
    @StateObject private var settingsWrapper: SettingsStorageWrapper
    
    init(settingsStorage: any SettingsStorageProtocol) {
        self._settingsWrapper = StateObject(wrappedValue: SettingsStorageWrapper(storage: settingsStorage))
    }
    @StateObject private var crashService = CrashReportingService.shared
    @State private var showingReportDetails = false
    @State private var showingPrivacyInfo = false
    @State private var isSendingReports = false
    @State private var selectedReport: CrashReport?
    
    var body: some View {
        List {
            statusSection
            settingsSection
            pendingReportsSection
            privacySection
            testingSection
        }
        .navigationTitle("Crash Reporting")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPrivacyInfo) {
            NavigationView {
                CrashReportingPrivacyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingPrivacyInfo = false
                            }
                        }
                    }
            }
        }
        .sheet(item: $selectedReport) { report in
            NavigationView {
                CrashReportDetailView(report: report)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedReport = nil
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Crash Reporting")
                        .dynamicTextStyle(.bodyMedium)
                    
                    Text(crashService.isEnabled ? "Enabled" : "Disabled")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(crashService.isEnabled ? AppColors.success : AppColors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: bindingForCrashReporting())
                    .labelsHidden()
            }
            
            if crashService.pendingReportsCount > 0 {
                HStack {
                    Label("\(crashService.pendingReportsCount) pending reports", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(AppColors.warning)
                        .dynamicTextStyle(.bodySmall)
                    
                    Spacer()
                    
                    Button("Send Now") {
                        sendPendingReports()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isSendingReports)
                }
            }
        } header: {
            Text("Status")
        } footer: {
            Text("Automatically collect and send crash reports to help improve the app")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var settingsSection: some View {
        Section {
            Toggle(isOn: bindingForBool(key: .crashReportingAutoSend, defaultValue: true)) {
                Label("Auto-send Reports", systemImage: "paperplane")
            }
            .disabled(!crashService.isEnabled)
            
            Toggle(isOn: bindingForBool(key: .crashReportingIncludeDeviceInfo, defaultValue: true)) {
                Label("Include Device Info", systemImage: "iphone")
            }
            .disabled(!crashService.isEnabled)
            
            Toggle(isOn: bindingForBool(key: .crashReportingIncludeAppState, defaultValue: true)) {
                Label("Include App State", systemImage: "app.badge")
            }
            .disabled(!crashService.isEnabled)
            
            Picker("Report Detail Level", selection: bindingForDetailLevel()) {
                Text("Basic").tag(CrashReportDetailLevel.basic.rawValue)
                Text("Standard").tag(CrashReportDetailLevel.standard.rawValue)
                Text("Detailed").tag(CrashReportDetailLevel.detailed.rawValue)
            }
            .disabled(!crashService.isEnabled)
        } header: {
            Text("Settings")
        } footer: {
            Text("Configure what information is included in crash reports")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    private var pendingReportsSection: some View {
        Section {
            if crashService.pendingReportsCount == 0 {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(AppColors.success)
                    Text("No pending crash reports")
                        .dynamicTextStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .appPadding(.vertical)
            } else {
                ForEach(0..<min(3, crashService.pendingReportsCount), id: \.self) { _ in
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(AppColors.warning)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Crash Report")
                                .dynamicTextStyle(.bodyMedium)
                            Text("Tap to view details")
                                .dynamicTextStyle(.bodySmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Load and show report details
                        Task {
                            await loadReportDetails()
                        }
                    }
                }
                
                if crashService.pendingReportsCount > 3 {
                    Text("And \(crashService.pendingReportsCount - 3) more...")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Button(action: clearPendingReports) {
                    Label("Clear All Reports", systemImage: "trash")
                        .foregroundStyle(AppColors.error)
                }
            }
        } header: {
            Text("Pending Reports")
        }
    }
    
    private var privacySection: some View {
        Section {
            Button(action: { showingPrivacyInfo = true }) {
                HStack {
                    Label("Privacy Information", systemImage: "hand.raised")
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            
            Text("Your privacy is important. Crash reports never include personal data like item names, values, or photos.")
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
        } header: {
            Text("Privacy")
        }
    }
    
    private var testingSection: some View {
        Section {
            Button(action: generateTestCrash) {
                Label("Generate Test Crash", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Button(action: generateNonFatalError) {
                Label("Generate Non-Fatal Error", systemImage: "exclamationmark.circle")
                    .foregroundStyle(AppColors.textPrimary)
            }
        } header: {
            Text("Testing")
        } footer: {
            Text("Use these options to test crash reporting functionality")
                .dynamicTextStyle(.labelSmall)
        }
    }
    
    // MARK: - Helper Methods
    
    private func bindingForCrashReporting() -> Binding<Bool> {
        Binding(
            get: { crashService.isEnabled },
            set: { enabled in
                crashService.setEnabled(enabled)
                settingsWrapper.set(enabled, forKey: .crashReportingEnabled)
            }
        )
    }
    
    private func bindingForBool(key: SettingsKey, defaultValue: Bool) -> Binding<Bool> {
        Binding(
            get: { settingsWrapper.bool(forKey: key) ?? defaultValue },
            set: { settingsWrapper.set($0, forKey: key) }
        )
    }
    
    private func bindingForDetailLevel() -> Binding<String> {
        Binding(
            get: { 
                settingsWrapper.string(forKey: .crashReportingDetailLevel) ?? CrashReportDetailLevel.standard.rawValue 
            },
            set: { settingsWrapper.set($0, forKey: .crashReportingDetailLevel) }
        )
    }
    
    private func sendPendingReports() {
        isSendingReports = true
        
        Task {
            do {
                try await crashService.sendPendingReports()
                
                await MainActor.run {
                    isSendingReports = false
                }
            } catch {
                await MainActor.run {
                    isSendingReports = false
                    // Show error alert
                }
            }
        }
    }
    
    private func clearPendingReports() {
        crashService.clearPendingReports()
    }
    
    private func loadReportDetails() async {
        let reports = await crashService.getPendingReports()
        if let firstReport = reports.first {
            selectedReport = firstReport
        }
    }
    
    private func generateTestCrash() {
        // This won't actually crash the app, but will generate a report
        crashService.reportError(
            TestError.testCrash,
            userInfo: ["test": "true", "source": "settings"]
        )
    }
    
    private func generateNonFatalError() {
        crashService.reportNonFatal(
            "Test non-fatal error from settings",
            userInfo: ["test": "true", "severity": "low"]
        )
    }
}

// MARK: - Supporting Types

enum CrashReportDetailLevel: String, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case detailed = "detailed"
}

enum TestError: Error {
    case testCrash
    
    var localizedDescription: String {
        "This is a test crash for debugging purposes"
    }
}

// MARK: - Privacy View

struct CrashReportingPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Crash Reporting Privacy")
                    .dynamicTextStyle(.displayMedium)
                
                Text("We take your privacy seriously. Here's what you need to know about crash reporting:")
                    .dynamicTextStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                privacySection(
                    title: "What We Collect",
                    items: [
                        "Type of crash or error",
                        "App version and build number",
                        "Device model and iOS version",
                        "Stack trace showing where the crash occurred",
                        "Time when the crash happened"
                    ]
                )
                
                privacySection(
                    title: "What We DON'T Collect",
                    items: [
                        "Your personal information",
                        "Item names, descriptions, or values",
                        "Photos or documents",
                        "Location data",
                        "Network activity",
                        "Other apps on your device"
                    ],
                    isExclusion: true
                )
                
                privacySection(
                    title: "How We Use This Data",
                    items: [
                        "Identify and fix app crashes",
                        "Improve app stability",
                        "Prioritize bug fixes",
                        "Test on affected device types"
                    ]
                )
                
                privacySection(
                    title: "Your Control",
                    items: [
                        "Disable crash reporting at any time",
                        "Choose what information to include",
                        "Review reports before sending",
                        "Delete pending reports"
                    ]
                )
                
                Text("Crash reports are transmitted securely and stored for up to 90 days. They are only accessible to our development team.")
                    .dynamicTextStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .appPadding(.top)
            }
            .appPadding()
        }
        .navigationTitle("Privacy Information")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func privacySection(title: String, items: [String], isExclusion: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .dynamicTextStyle(.headlineMedium)
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: isExclusion ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(isExclusion ? AppColors.error : AppColors.success)
                            .font(.footnote)
                        
                        Text(item)
                            .dynamicTextStyle(.bodyMedium)
                    }
                }
            }
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
}

// MARK: - Report Detail View

struct CrashReportDetailView: View {
    let report: CrashReport
    @State private var showingFullStackTrace = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                headerSection
                
                // Basic Info
                infoSection
                
                // Stack Trace
                stackTraceSection
                
                // Device Info
                deviceInfoSection
                
                // App Info
                appInfoSection
                
                // User Info
                if let userInfo = report.userInfo, !userInfo.isEmpty {
                    userInfoSection(userInfo)
                }
            }
            .appPadding()
        }
        .navigationTitle("Crash Report")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: iconForType(report.type))
                    .font(.title2)
                    .foregroundStyle(colorForType(report.type))
                
                VStack(alignment: .leading) {
                    Text(report.type.rawValue.capitalized)
                        .dynamicTextStyle(.headlineMedium)
                    
                    Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Text(report.reason)
                .dynamicTextStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .appPadding()
        .background(AppColors.secondaryBackground)
        .appCornerRadius(.medium)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("CRASH INFORMATION")
                .dynamicTextStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Report ID", value: report.id.uuidString)
                InfoRow(label: "Type", value: report.type.rawValue.capitalized)
                InfoRow(label: "Time", value: report.timestamp.formatted())
                
                if let location = report.sourceLocation {
                    InfoRow(label: "File", value: URL(fileURLWithPath: location.file).lastPathComponent)
                    InfoRow(label: "Function", value: location.function)
                    InfoRow(label: "Line", value: "\(location.line)")
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var stackTraceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("STACK TRACE")
                    .dynamicTextStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                
                Spacer()
                
                Button(action: { showingFullStackTrace.toggle() }) {
                    Text(showingFullStackTrace ? "Show Less" : "Show All")
                        .dynamicTextStyle(.labelSmall)
                        .foregroundStyle(AppColors.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                let frames = showingFullStackTrace ? report.callStack : Array(report.callStack.prefix(5))
                
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    Text("\(index). \(frame)")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.system(.caption, design: .monospaced))
                }
                
                if !showingFullStackTrace && report.callStack.count > 5 {
                    Text("... and \(report.callStack.count - 5) more frames")
                        .dynamicTextStyle(.bodySmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("DEVICE INFORMATION")
                .dynamicTextStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Model", value: report.deviceInfo.model)
                InfoRow(label: "OS", value: "\(report.deviceInfo.systemName) \(report.deviceInfo.systemVersion)")
                InfoRow(label: "Simulator", value: report.deviceInfo.isSimulator ? "Yes" : "No")
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("APP INFORMATION")
                .dynamicTextStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Version", value: report.appInfo.version)
                InfoRow(label: "Build", value: report.appInfo.build)
                InfoRow(label: "Bundle ID", value: report.appInfo.bundleIdentifier)
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private func userInfoSection(_ userInfo: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("ADDITIONAL INFORMATION")
                .dynamicTextStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(userInfo.keys.sorted()), id: \.self) { key in
                    InfoRow(label: key.capitalized, value: userInfo[key] ?? "")
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private func iconForType(_ type: CrashType) -> String {
        switch type {
        case .exception:
            return "exclamationmark.triangle.fill"
        case .signal:
            return "bolt.trianglebadge.exclamationmark.fill"
        case .error:
            return "xmark.circle.fill"
        case .nonFatal:
            return "exclamationmark.circle.fill"
        }
    }
    
    private func colorForType(_ type: CrashType) -> Color {
        switch type {
        case .exception, .signal:
            return AppColors.error
        case .error:
            return AppColors.warning
        case .nonFatal:
            return AppColors.textSecondary
        }
    }
}

// MARK: - Info Row Component

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .dynamicTextStyle(.bodySmall)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Settings Keys

extension SettingsKey {
    static let crashReportingEnabled = SettingsKey("crash_reporting_enabled")
    static let crashReportingAutoSend = SettingsKey("crash_reporting_auto_send")
    static let crashReportingIncludeDeviceInfo = SettingsKey("crash_reporting_include_device")
    static let crashReportingIncludeAppState = SettingsKey("crash_reporting_include_state")
    static let crashReportingDetailLevel = SettingsKey("crash_reporting_detail_level")
}
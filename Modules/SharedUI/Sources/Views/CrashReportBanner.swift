import SwiftUI
import Core

/// A banner view that shows when there are pending crash reports
public struct CrashReportBanner: View {
    @StateObject private var crashService = CrashReportingService.shared
    @State private var isExpanded = false
    @State private var isSending = false
    @State private var isDismissed = false
    
    public init() {}
    
    public var body: some View {
        if crashService.pendingReportsCount > 0 && !isDismissed {
            VStack(spacing: 0) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.warning)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Crash Reports Available")
                            .dynamicTextStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("\(crashService.pendingReportsCount) report\(crashService.pendingReportsCount == 1 ? "" : "s") ready to send")
                            .dynamicTextStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        HStack(spacing: AppSpacing.sm) {
                            Button(action: sendReports) {
                                Text("Send")
                                    .dynamicTextStyle(.labelMedium)
                                    .foregroundStyle(AppColors.primary)
                            }
                            
                            Button(action: { isDismissed = true }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .appPadding()
                
                if isExpanded {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Help improve the app by sending crash reports. No personal data is included.")
                            .dynamicTextStyle(.bodySmall)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        HStack {
                            Button(action: viewDetails) {
                                Text("View Details")
                                    .dynamicTextStyle(.labelMedium)
                                    .foregroundStyle(AppColors.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: clearReports) {
                                Text("Clear All")
                                    .dynamicTextStyle(.labelMedium)
                                    .foregroundStyle(AppColors.error)
                            }
                        }
                    }
                    .appPadding()
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
                }
            }
            .background(AppColors.secondaryBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(AppColors.divider),
                alignment: .bottom
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Crash reports available. \(crashService.pendingReportsCount) reports ready to send.")
            .accessibilityHint("Double tap to expand options")
        }
    }
    
    private func sendReports() {
        isSending = true
        
        Task {
            do {
                try await crashService.sendPendingReports()
                
                await MainActor.run {
                    isSending = false
                    isDismissed = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    // Could show error alert here
                }
            }
        }
    }
    
    private func viewDetails() {
        // Navigate to crash reporting settings
        // This would need to be handled by the parent view
    }
    
    private func clearReports() {
        crashService.clearPendingReports()
        isDismissed = true
    }
}

// MARK: - View Extension

public extension View {
    /// Add a crash report banner to the top of the view
    func crashReportBanner() -> some View {
        VStack(spacing: 0) {
            CrashReportBanner()
            self
        }
    }
}
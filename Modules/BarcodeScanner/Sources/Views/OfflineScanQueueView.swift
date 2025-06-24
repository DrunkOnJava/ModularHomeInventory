import SwiftUI
import Core
import SharedUI

/// View for displaying and managing offline scan queue
/// Swift 5.9 - No Swift 6 features
public struct OfflineScanQueueView: View {
    @StateObject private var offlineScanService: OfflineScanService
    @State private var showingClearAlert = false
    
    public init(offlineScanService: OfflineScanService) {
        self._offlineScanService = StateObject(wrappedValue: offlineScanService)
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if offlineScanService.pendingScans.isEmpty {
                    emptyView
                } else {
                    queueList
                }
            }
            .navigationTitle("Offline Queue")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !offlineScanService.pendingScans.isEmpty {
                        Menu {
                            Button(action: { Task { await offlineScanService.processQueue() } }) {
                                Label("Process Queue", systemImage: "arrow.clockwise")
                            }
                            .disabled(offlineScanService.isProcessing)
                            
                            Button(action: { showingClearAlert = true }) {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Clear Completed Scans", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task {
                        try? await offlineScanService.clearCompleted()
                    }
                }
            } message: {
                Text("Remove all completed scans from the queue?")
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textSecondary)
            
            Text("No Offline Scans")
                .textStyle(.headlineMedium)
            
            Text("Scans will be queued here when you're offline")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .appPadding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var queueList: some View {
        List {
            if offlineScanService.isProcessing {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing queue...")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .appPadding(.vertical, AppSpacing.xs)
                }
            }
            
            ForEach(offlineScanService.pendingScans) { entry in
                OfflineScanQueueRow(
                    entry: entry,
                    onRetry: {
                        Task {
                            await offlineScanService.retryScan(id: entry.id)
                        }
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Queue Row View
struct OfflineScanQueueRow: View {
    let entry: OfflineScanQueueEntry
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: "barcode")
                    .foregroundStyle(statusColor)
                
                Text(entry.barcode)
                    .textStyle(.bodyLarge)
                    .fontDesign(.monospaced)
                
                Spacer()
                
                statusView
            }
            
            HStack {
                Text(entry.scanDate, style: .relative)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                if entry.retryCount > 0 {
                    Text("•")
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Retries: \(entry.retryCount)")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            if let error = entry.errorMessage {
                Text(error)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.error)
                    .lineLimit(2)
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
        .swipeActions(edge: .trailing) {
            if entry.status == .failed {
                Button("Retry") {
                    onRetry()
                }
                .tint(AppColors.primary)
            }
        }
    }
    
    private var statusColor: Color {
        switch entry.status {
        case .pending:
            return AppColors.textSecondary
        case .processing:
            return AppColors.primary
        case .completed:
            return AppColors.success
        case .failed:
            return AppColors.error
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch entry.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(AppColors.textSecondary)
        case .processing:
            ProgressView()
                .scaleEffect(0.7)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.error)
        }
    }
}
import SwiftUI
import Core
import SharedUI

/// Batch resolution view for resolving multiple conflicts at once
/// Swift 5.9 - No Swift 6 features
struct BatchResolutionView: View {
    let conflicts: [SyncConflict]
    @ObservedObject var viewModel: ConflictResolutionViewModel
    let onComplete: () -> Void
    
    @State private var selectedStrategy: ConflictResolution = .keepLocal
    @State private var mergeStrategy: MergeStrategy = .latestWins
    @State private var isResolving = false
    @State private var progress: Double = 0
    @State private var currentConflictIndex = 0
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isResolving {
                    progressView
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Summary
                            summaryCard
                            
                            // Strategy selection
                            strategySelectionCard
                            
                            // Preview
                            previewCard
                            
                            // Warning
                            warningCard
                        }
                        .padding()
                    }
                }
                
                // Action buttons
                actionButtons
            }
            .background(AppColors.background)
            .navigationTitle("Resolve All Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isResolving)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var progressView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            VStack(spacing: AppSpacing.lg) {
                ProgressView(value: progress, total: Double(conflicts.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("Resolving \(currentConflictIndex + 1) of \(conflicts.count)")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                if currentConflictIndex < conflicts.count {
                    let conflict = conflicts[currentConflictIndex]
                    HStack {
                        Image(systemName: conflict.entityType.icon)
                            .font(.body)
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text(conflict.entityType.rawValue)
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Batch Resolution")
                        .textStyle(.headlineMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Apply the same resolution to all conflicts")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            HStack(spacing: AppSpacing.xl) {
                StatItem(
                    value: "\(conflicts.count)",
                    label: "Total Conflicts"
                )
                
                StatItem(
                    value: "\(conflicts.filter { $0.entityType == .item }.count)",
                    label: "Items"
                )
                
                StatItem(
                    value: "\(conflicts.filter { $0.entityType == .receipt }.count)",
                    label: "Receipts"
                )
                
                StatItem(
                    value: "\(conflicts.filter { $0.entityType == .location }.count)",
                    label: "Locations"
                )
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var strategySelectionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Resolution Strategy")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                StrategyOption(
                    title: "Keep All Local",
                    description: "Use all versions from this device",
                    icon: "iphone",
                    isSelected: selectedStrategy == .keepLocal
                ) {
                    selectedStrategy = .keepLocal
                }
                
                StrategyOption(
                    title: "Keep All Remote",
                    description: "Use all versions from the cloud",
                    icon: "icloud",
                    isSelected: selectedStrategy == .keepRemote
                ) {
                    selectedStrategy = .keepRemote
                }
                
                StrategyOption(
                    title: "Auto-Merge",
                    description: "Intelligently merge based on strategy",
                    icon: "wand.and.stars",
                    isSelected: selectedStrategy == .merge(mergeStrategy)
                ) {
                    selectedStrategy = .merge(mergeStrategy)
                }
            }
            
            // Merge strategy options
            if case .merge = selectedStrategy {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Merge Strategy")
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, AppSpacing.sm)
                    
                    ForEach([
                        MergeStrategy.latestWins,
                        MergeStrategy.localPriority,
                        MergeStrategy.remotePriority
                    ], id: \.displayName) { strategy in
                        MergeStrategyOption(
                            strategy: strategy,
                            isSelected: mergeStrategy.displayName == strategy.displayName
                        ) {
                            mergeStrategy = strategy
                            selectedStrategy = .merge(strategy)
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Preview")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("The following resolution will be applied:")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            HStack {
                Image(systemName: resolutionIcon)
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(resolutionTitle)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(resolutionDescription)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(AppCornerRadius.small)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var warningCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.warning)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("This action cannot be undone")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Make sure to review your selection before proceeding")
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.warning.opacity(0.1))
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button("Cancel") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isResolving)
            
            Button(action: { Task { await resolveAllConflicts() } }) {
                if isResolving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Resolve All")
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isResolving)
        }
        .padding()
        .background(AppColors.surface)
    }
    
    // MARK: - Computed Properties
    
    private var resolutionIcon: String {
        switch selectedStrategy {
        case .keepLocal:
            return "iphone"
        case .keepRemote:
            return "icloud"
        case .merge:
            return "arrow.triangle.merge"
        case .custom:
            return "slider.horizontal.3"
        }
    }
    
    private var resolutionTitle: String {
        switch selectedStrategy {
        case .keepLocal:
            return "Keep all local versions"
        case .keepRemote:
            return "Keep all remote versions"
        case .merge(let strategy):
            return "Auto-merge with \(strategy.displayName)"
        case .custom:
            return "Custom resolution"
        }
    }
    
    private var resolutionDescription: String {
        switch selectedStrategy {
        case .keepLocal:
            return "All conflicts will be resolved using data from this device"
        case .keepRemote:
            return "All conflicts will be resolved using data from the cloud"
        case .merge:
            return "Conflicts will be merged automatically based on the selected strategy"
        case .custom:
            return "Each conflict will use custom resolution"
        }
    }
    
    // MARK: - Methods
    
    private func resolveAllConflicts() async {
        isResolving = true
        currentConflictIndex = 0
        progress = 0
        
        // Simulate batch resolution with progress
        for (index, _) in conflicts.enumerated() {
            currentConflictIndex = index
            progress = Double(index + 1)
            
            // Add small delay for visual feedback
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Actually resolve all conflicts
        await viewModel.resolveAllConflicts(strategy: selectedStrategy)
        
        onComplete()
        dismiss()
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(label)
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

private struct StrategyOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(description)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(AppCornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

private struct MergeStrategyOption: View {
    let strategy: MergeStrategy
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
                
                Text(strategy.displayName)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}
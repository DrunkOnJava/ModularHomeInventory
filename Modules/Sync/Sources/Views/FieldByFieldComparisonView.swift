import SwiftUI
import Core
import SharedUI

/// Field-by-field comparison view for custom merge resolution
/// Swift 5.9 - No Swift 6 features
struct FieldByFieldComparisonView: View {
    let conflict: SyncConflict
    let details: ConflictDetails
    @Binding var fieldResolutions: [FieldResolution]
    
    @State private var resolutions: [String: FieldResolution.FieldResolutionType] = [:]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Instructions
                    instructionsCard
                    
                    // Field comparisons
                    ForEach(details.changes) { change in
                        FieldComparisonCard(
                            change: change,
                            resolution: Binding(
                                get: { resolutions[change.fieldName] ?? .useLocal },
                                set: { resolutions[change.fieldName] = $0 }
                            )
                        )
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Custom Merge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyResolutions()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            initializeResolutions()
        }
    }
    
    // MARK: - Components
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                
                Text("Choose values for each field")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Text("Select which version to keep for each conflicting field. You can also choose special merge strategies for certain fields.")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    // MARK: - Methods
    
    private func initializeResolutions() {
        for change in details.changes {
            resolutions[change.fieldName] = .useLocal
        }
    }
    
    private func applyResolutions() {
        fieldResolutions = resolutions.map { fieldName, resolutionType in
            FieldResolution(fieldName: fieldName, resolution: resolutionType)
        }
    }
}

// MARK: - Field Comparison Card

private struct FieldComparisonCard: View {
    let change: FieldChange
    @Binding var resolution: FieldResolution.FieldResolutionType
    @State private var showingOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Field name header
            HStack {
                Text(change.displayName)
                    .textStyle(.headlineSmall)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                if change.isConflicting {
                    Label("Conflict", systemImage: "exclamationmark.triangle.fill")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.warning)
                }
            }
            
            // Value comparison
            VStack(spacing: AppSpacing.sm) {
                // Local value
                ValueOption(
                    label: "Local",
                    value: change.oldValue ?? "No value",
                    icon: "iphone",
                    isSelected: resolution == .useLocal
                ) {
                    resolution = .useLocal
                }
                
                // Remote value
                ValueOption(
                    label: "Remote",
                    value: change.newValue ?? "No value",
                    icon: "icloud",
                    isSelected: resolution == .useRemote
                ) {
                    resolution = .useRemote
                }
                
                // Special options for certain field types
                if canHaveSpecialOptions(for: change) {
                    Button(action: { showingOptions.toggle() }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.body)
                            
                            Text("More Options")
                                .textStyle(.bodyMedium)
                            
                            Spacer()
                            
                            Image(systemName: showingOptions ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(AppColors.primary)
                        .padding(.vertical, AppSpacing.sm)
                    }
                    
                    if showingOptions {
                        specialOptionsView(for: change)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    private func canHaveSpecialOptions(for change: FieldChange) -> Bool {
        // Check if field can have special merge options
        let numericFields = ["quantity", "purchasePrice", "value"]
        let textFields = ["name", "description", "notes"]
        
        return numericFields.contains(change.fieldName) || textFields.contains(change.fieldName)
    }
    
    @ViewBuilder
    private func specialOptionsView(for change: FieldChange) -> some View {
        VStack(spacing: AppSpacing.sm) {
            let numericFields = ["quantity", "purchasePrice", "value"]
            let textFields = ["name", "description", "notes"]
            
            if numericFields.contains(change.fieldName) {
                ValueOption(
                    label: "Average",
                    value: "Use average of both values",
                    icon: "divide.circle",
                    isSelected: resolution == .average
                ) {
                    resolution = .average
                }
            }
            
            if textFields.contains(change.fieldName) {
                ValueOption(
                    label: "Concatenate",
                    value: "Combine both values",
                    icon: "text.append",
                    isSelected: resolution == .concatenate(separator: " ")
                ) {
                    resolution = .concatenate(separator: " ")
                }
            }
            
            ValueOption(
                label: "Latest",
                value: "Use most recently modified",
                icon: "clock.arrow.circlepath",
                isSelected: resolution == .latest
            ) {
                resolution = .latest
            }
        }
        .padding(.top, AppSpacing.xs)
    }
}

// MARK: - Value Option

private struct ValueOption: View {
    let label: String
    let value: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(value)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
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
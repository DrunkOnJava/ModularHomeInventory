import SwiftUI
import Core
import SharedUI

/// Receipt detail view
/// Swift 5.9 - No Swift 6 features
struct ReceiptDetailView: View {
    @StateObject private var viewModel: ReceiptDetailViewModel
    @State private var showingFullScreenImage = false
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: ReceiptDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Receipt Image
                if let imageData = viewModel.receipt.imageData,
                   let uiImage = UIImage(data: imageData) {
                    receiptImageSection(uiImage)
                }
                
                // Store Information
                storeInfoSection
                
                // Linked Items
                if viewModel.isLoadingItems {
                    ProgressView("Loading items...")
                        .frame(maxWidth: .infinity)
                        .appPadding()
                } else if !viewModel.linkedItems.isEmpty {
                    linkedItemsSection
                }
                
                // Notes
                if let rawText = viewModel.receipt.rawText, !rawText.isEmpty {
                    notesSection(rawText)
                }
                
                // Metadata
                metadataSection
            }
            .appPadding()
        }
        .background(AppColors.secondaryBackground)
        .navigationTitle(viewModel.receipt.storeName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { viewModel.showingEditView = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { viewModel.showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadLinkedItems()
        }
        .sheet(isPresented: $viewModel.showingEditView) {
            // Edit view would go here
            FeatureUnavailableView(
                feature: "Edit Receipt",
                reason: "Edit functionality coming soon",
                icon: "pencil"
            )
        }
        .alert("Delete Receipt", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteReceipt()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let imageData = viewModel.receipt.imageData,
               let uiImage = UIImage(data: imageData) {
                FullScreenImageView(image: uiImage)
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func receiptImageSection(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("RECEIPT IMAGE")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            Button(action: { showingFullScreenImage = true }) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            
            Text("Tap to view full size")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var storeInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("STORE INFORMATION")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Store", value: viewModel.receipt.storeName, icon: "storefront")
                InfoRow(label: "Date", value: viewModel.receipt.date.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                InfoRow(
                    label: "Total",
                    value: NSDecimalNumber(decimal: viewModel.receipt.totalAmount).doubleValue.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle"
                )
                
                if viewModel.receipt.confidence < 1.0 {
                    InfoRow(
                        label: "Confidence",
                        value: "\(Int(viewModel.receipt.confidence * 100))%",
                        icon: "chart.bar",
                        valueColor: viewModel.receipt.confidence < 0.8 ? .orange : AppColors.textPrimary
                    )
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var linkedItemsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("LINKED ITEMS (\(viewModel.linkedItems.count))")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.linkedItems) { item in
                    LinkedItemRow(item: item)
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("NOTES")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            Text(notes)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("METADATA")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Created", value: viewModel.receipt.createdAt.formatted(date: .abbreviated, time: .shortened), icon: "clock")
                InfoRow(label: "Modified", value: viewModel.receipt.updatedAt.formatted(date: .abbreviated, time: .shortened), icon: "clock.arrow.circlepath")
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = AppColors.textPrimary
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .textStyle(.bodyMedium)
                .foregroundStyle(valueColor)
        }
    }
}

private struct LinkedItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            Image(systemName: item.category.icon)
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                if let brand = item.brand {
                    Text(brand)
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            if let value = item.value {
                Text(value, format: .currency(code: "USD"))
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { value in
                                lastScale = scale
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                lastOffset = offset
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black)
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
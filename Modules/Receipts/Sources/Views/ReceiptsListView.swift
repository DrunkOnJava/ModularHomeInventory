import SwiftUI
import Core
import SharedUI

/// Main receipts list view
/// Swift 5.9 - No Swift 6 features
struct ReceiptsListView: View {
    @StateObject private var viewModel: ReceiptsListViewModel
    @State private var showingImport = false
    
    init(viewModel: ReceiptsListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.receipts.isEmpty {
                    ProgressView("Loading receipts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.receipts.isEmpty {
                    emptyStateView
                } else {
                    receiptsList
                }
            }
            .navigationTitle("Receipts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImport = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImport) {
                if let addView = viewModel.makeAddReceiptView() {
                    addView
                }
            }
        }
        .task {
            await viewModel.loadReceipts()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No Receipts Yet")
                .textStyle(.headlineMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Import receipts from emails or scan them to get started")
                .textStyle(.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .appPadding(.horizontal)
            
            PrimaryButton(title: "Import Receipt", action: { showingImport = true })
                .appPadding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var receiptsList: some View {
        List {
            ForEach(viewModel.groupedReceipts, id: \.key) { section in
                Section(header: Text(section.key).textStyle(.labelMedium)) {
                    ForEach(section.value) { receipt in
                        NavigationLink(destination: destinationView(for: receipt)) {
                            ReceiptRowView(receipt: receipt)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await viewModel.loadReceipts()
        }
    }
    
    @ViewBuilder
    private func destinationView(for receipt: Receipt) -> some View {
        if let detailView = viewModel.makeReceiptDetailView(for: receipt) {
            detailView
        } else {
            Text("Unable to load receipt details")
        }
    }
}

/// Individual receipt row
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(receipt.storeName)
                    .textStyle(.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack {
                    Text(receipt.date, style: .date)
                        .textStyle(.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if receipt.confidence < 0.8 {
                        Label("Low confidence", systemImage: "exclamationmark.triangle.fill")
                            .textStyle(.labelSmall)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text("$\(NSDecimalNumber(decimal: receipt.totalAmount).doubleValue, specifier: "%.2f")")
                    .textStyle(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                
                Text("\(receipt.itemIds.count) items")
                    .textStyle(.labelSmall)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}
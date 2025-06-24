import SwiftUI
import Core
import SharedUI

public struct ServiceHistoryListView: View {
    @StateObject private var viewModel: ServiceHistoryViewModel
    @State private var showingAddService = false
    @State private var selectedRecord: ServiceRecord?
    @State private var filterType: ServiceType?
    
    public init(
        item: Item,
        serviceRepository: ServiceRecordRepository,
        repairRepository: RepairRecordRepository
    ) {
        self._viewModel = StateObject(wrappedValue: ServiceHistoryViewModel(
            item: item,
            serviceRepository: serviceRepository,
            repairRepository: repairRepository
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Stats header
            statsHeader
                .appPadding()
                .background(AppColors.secondaryBackground)
            
            // Filter chips
            filterChips
                .appPadding(.horizontal)
                .appPadding(.vertical, AppSpacing.sm)
            
            // Service records list
            if viewModel.filteredRecords.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.groupedRecords.keys.sorted().reversed(), id: \.self) { year in
                        Section(header: Text(String(year)).textStyle(.labelMedium)) {
                            ForEach(viewModel.groupedRecords[year] ?? []) { record in
                                ServiceRecordRow(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecord = record
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
            }
        }
        .navigationTitle("Service History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddService = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddService) {
            NavigationView {
                AddServiceRecordView(
                    item: viewModel.item,
                    serviceRepository: viewModel.serviceRepository,
                    onSave: { _ in
                        Task {
                            await viewModel.loadRecords()
                        }
                    }
                )
            }
        }
        .sheet(item: $selectedRecord) { record in
            NavigationView {
                ServiceRecordDetailView(
                    record: record,
                    item: viewModel.item,
                    serviceRepository: viewModel.serviceRepository
                )
            }
        }
        .task {
            await viewModel.loadRecords()
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: AppSpacing.lg) {
            // Total services
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("\(viewModel.serviceRecords.count)")
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Total Services")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Total cost
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(viewModel.totalServiceCost, format: .currency(code: "USD"))
                    .textStyle(.headlineLarge)
                    .foregroundStyle(AppColors.primary)
                Text("Total Cost")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Next service
            if let nextDate = viewModel.nextServiceDate {
                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    Text(nextDate, format: .dateTime.month().day())
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Next Service")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ServiceFilterChip(
                    title: "All",
                    isSelected: filterType == nil,
                    action: { filterType = nil }
                )
                
                ForEach(ServiceType.allCases, id: \.self) { type in
                    ServiceFilterChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: filterType == type,
                        action: { filterType = type }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textSecondary)
            
            Text("No Service History")
                .textStyle(.headlineMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Track maintenance and repairs for this item")
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "Add First Service") {
                showingAddService = true
            }
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appPadding()
    }
}

// MARK: - Service Record Row

struct ServiceRecordRow: View {
    let record: ServiceRecord
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Type icon
            Image(systemName: record.type.icon)
                .font(.title3)
                .foregroundStyle(Color(record.type.color))
                .frame(width: 40, height: 40)
                .background(Color(record.type.color).opacity(0.1))
                .cornerRadius(AppCornerRadius.small)
            
            // Details
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(record.description)
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(record.provider)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    if record.wasUnderWarranty {
                        Label("Warranty", systemImage: "checkmark.shield")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.success)
                    }
                }
            }
            
            Spacer()
            
            // Cost and date
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                if let cost = record.cost {
                    Text(cost, format: .currency(code: "USD"))
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.primary)
                } else {
                    Text("No charge")
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Text(record.date, format: .dateTime.month().day().year())
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Filter Chip

struct ServiceFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .textStyle(.labelSmall)
            }
            .appPadding(.horizontal, AppSpacing.sm)
            .appPadding(.vertical, AppSpacing.xs)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .cornerRadius(AppCornerRadius.small)
        }
    }
}
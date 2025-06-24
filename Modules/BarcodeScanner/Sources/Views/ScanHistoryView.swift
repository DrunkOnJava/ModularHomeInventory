import SwiftUI
import Core
import SharedUI

/// View displaying scan history
/// Swift 5.9 - No Swift 6 features
struct ScanHistoryView: View {
    @StateObject private var viewModel: ScanHistoryViewModel
    @State private var showingClearConfirmation = false
    @State private var selectedEntry: ScanHistoryEntry?
    
    init(scanHistoryRepository: any ScanHistoryRepository, itemRepository: any ItemRepository) {
        self._viewModel = StateObject(wrappedValue: ScanHistoryViewModel(
            scanHistoryRepository: scanHistoryRepository,
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.entries.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.entries.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearConfirmation = true
                        }
                        .foregroundStyle(Color.red)
                    }
                }
            }
            .alert("Clear Scan History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearHistory()
                    }
                }
            } message: {
                Text("Are you sure you want to clear all scan history? This action cannot be undone.")
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Scan History")
                    .textStyle(.displaySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("Your recently scanned items will appear here")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
    }
    
    private var historyList: some View {
        List {
            ForEach(groupedEntries, id: \.key) { section in
                Section {
                    ForEach(section.entries) { entry in
                        ScanHistoryRow(
                            entry: entry,
                            onTap: {
                                if entry.itemId != nil {
                                    selectedEntry = entry
                                }
                            }
                        )
                    }
                } header: {
                    Text(section.key)
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadHistory()
        }
        .sheet(item: $selectedEntry) { entry in
            if let itemId = entry.itemId {
                // Navigate to item detail
                // This would be handled by the navigation coordinator
                Text("Item Detail View for \(entry.itemName ?? "Unknown")")
                    .padding()
            }
        }
    }
    
    private var groupedEntries: [(key: String, entries: [ScanHistoryEntry])] {
        let grouped = Dictionary(grouping: viewModel.entries) { entry in
            formatSectionDate(entry.scanDate)
        }
        
        return grouped.sorted { first, second in
            // Sort sections by most recent first
            guard let firstDate = first.value.first?.scanDate,
                  let secondDate = second.value.first?.scanDate else {
                return false
            }
            return firstDate > secondDate
        }.map { (key: $0.key, entries: $0.value) }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let weekday = calendar.dateComponents([.weekday], from: date, to: now).weekday,
                  weekday < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month(.wide).day())
        }
    }
}

// MARK: - Scan History Row
struct ScanHistoryRow: View {
    let entry: ScanHistoryEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon or thumbnail
                if let thumbnail = entry.itemThumbnail {
                    Image(systemName: thumbnail)
                        .font(.title2)
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 50, height: 50)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppCornerRadius.medium)
                } else {
                    Image(systemName: "barcode")
                        .font(.title2)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray5))
                        .cornerRadius(AppCornerRadius.medium)
                }
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if let itemName = entry.itemName {
                        Text(itemName)
                            .textStyle(.bodyLarge)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                    }
                    
                    Text(entry.barcode)
                        .textStyle(.bodySmall)
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.system(.caption, design: .monospaced))
                    
                    HStack(spacing: AppSpacing.sm) {
                        Label(entry.scanType.rawValue, systemImage: scanTypeIcon)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text(formatTime(entry.scanDate))
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                if entry.itemId != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry.itemId == nil)
    }
    
    private var scanTypeIcon: String {
        switch entry.scanType {
        case .single:
            return "barcode.viewfinder"
        case .batch:
            return "square.stack.3d.up"
        case .continuous:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - View Model
@MainActor
final class ScanHistoryViewModel: ObservableObject {
    @Published var entries: [ScanHistoryEntry] = []
    @Published var isLoading = false
    
    private let scanHistoryRepository: any ScanHistoryRepository
    private let itemRepository: any ItemRepository
    
    init(scanHistoryRepository: any ScanHistoryRepository, itemRepository: any ItemRepository) {
        self.scanHistoryRepository = scanHistoryRepository
        self.itemRepository = itemRepository
    }
    
    func loadHistory() async {
        isLoading = true
        do {
            entries = try await scanHistoryRepository.fetchRecent(limit: 50)
            
            // Enrich entries with item data if available
            for i in entries.indices {
                if let itemId = entries[i].itemId,
                   let item = try await itemRepository.fetch(id: itemId) {
                    entries[i].itemName = item.name
                    // Map category to icon for thumbnail
                    entries[i].itemThumbnail = item.category.icon
                }
            }
        } catch {
            print("Failed to load scan history: \(error)")
        }
        isLoading = false
    }
    
    func clearHistory() async {
        do {
            try await scanHistoryRepository.deleteAll()
            entries.removeAll()
        } catch {
            print("Failed to clear scan history: \(error)")
        }
    }
}

#Preview {
    ScanHistoryView(
        scanHistoryRepository: DefaultScanHistoryRepository(),
        itemRepository: MockItemRepository()
    )
}

// MARK: - Mock Item Repository for Preview
private final class MockItemRepository: ItemRepository {
    func fetchAll() async throws -> [Item] { [] }
    func fetch(id: UUID) async throws -> Item? {
        Item(
            name: "Sample Item",
            brand: "Apple",
            model: "Pro",
            category: .electronics,
            condition: .new,
            quantity: 1
        )
    }
    func save(_ entity: Item) async throws {}
    func saveAll(_ entities: [Item]) async throws {}
    func delete(_ entity: Item) async throws {}
    func delete(id: UUID) async throws {}
    func search(query: String) async throws -> [Item] { [] }
    func fuzzySearch(query: String, threshold: Double) async throws -> [Item] { [] }
    func fetchByCategory(_ category: ItemCategory) async throws -> [Item] { [] }
    func fetchByCategoryId(_ categoryId: UUID) async throws -> [Item] { [] }
    func fetchByLocation(_ locationId: UUID) async throws -> [Item] { [] }
    func fetchByBarcode(_ barcode: String) async throws -> Item? { nil }
    func searchWithCriteria(_ criteria: ItemSearchCriteria) async throws -> [Item] { [] }
    func fetchItemsUnderWarranty() async throws -> [Item] { [] }
    func fetchFavoriteItems() async throws -> [Item] { [] }
    func fetchRecentlyAdded(days: Int) async throws -> [Item] { [] }
}
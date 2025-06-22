import SwiftUI
import Core
import SharedUI

struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    
    init(viewModel: ItemDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header Section
                headerSection
                
                // Basic Info Section
                infoSection
                
                // Purchase Info Section
                if viewModel.item.purchasePrice != nil || viewModel.item.purchaseDate != nil {
                    purchaseSection
                }
                
                // Identification Section
                if viewModel.item.serialNumber != nil || viewModel.item.barcode != nil {
                    identificationSection
                }
                
                // Location Section
                if viewModel.locationName != nil {
                    locationSection
                }
                
                // Tags Section
                if !viewModel.item.tags.isEmpty {
                    tagsSection
                }
                
                // Notes Section
                if let notes = viewModel.item.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }
                
                // Metadata Section
                metadataSection
            }
            .appPadding()
        }
        .background(AppColors.secondaryBackground)
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditView = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: { 
                        Task {
                            await viewModel.duplicateItem()
                        }
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let editView = viewModel.makeEditView() {
                editView
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteItem()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.item.name)
                        .textStyle(.headlineLarge)
                    
                    if let brand = viewModel.item.brand {
                        Text(brand)
                            .textStyle(.bodyLarge)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: viewModel.item.category.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            if let model = viewModel.item.model {
                Text("Model: \(model)")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("INFORMATION")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                InfoRow(label: "Category", value: viewModel.item.category.displayName, icon: viewModel.item.category.icon)
                InfoRow(label: "Condition", value: viewModel.item.condition.displayName, icon: viewModel.item.condition.icon)
                InfoRow(label: "Quantity", value: "\(viewModel.item.quantity)", icon: "number.square")
                
                if let value = viewModel.item.value {
                    InfoRow(label: "Current Value", value: value.formatted(.currency(code: "USD")), icon: "chart.line.uptrend.xyaxis")
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("PURCHASE INFORMATION")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                if let price = viewModel.item.purchasePrice {
                    InfoRow(label: "Purchase Price", value: price.formatted(.currency(code: "USD")), icon: "dollarsign.circle")
                }
                
                if let date = viewModel.item.purchaseDate {
                    InfoRow(label: "Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var identificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("IDENTIFICATION")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                if let serial = viewModel.item.serialNumber {
                    InfoRow(label: "Serial Number", value: serial, icon: "number")
                }
                
                if let barcode = viewModel.item.barcode {
                    InfoRow(label: "Barcode", value: barcode, icon: "barcode")
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("LOCATION")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            if let locationName = viewModel.locationName {
                InfoRow(label: "Location", value: locationName, icon: "location")
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("TAGS")
                .textStyle(.labelSmall)
                .foregroundStyle(AppColors.textTertiary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(viewModel.item.tags, id: \.self) { tag in
                        TagChip(
                            name: tag,
                            color: colorForTag(tag),
                            onDelete: { }
                        )
                        .allowsHitTesting(false) // Disable interaction in detail view
                    }
                }
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private func colorForTag(_ tagName: String) -> Color {
        // Generate a consistent color based on the tag name
        let hash = tagName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    private func notesSection(notes: String) -> some View {
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
                InfoRow(label: "Created", value: viewModel.item.createdAt.formatted(date: .abbreviated, time: .shortened), icon: "clock")
                InfoRow(label: "Modified", value: viewModel.item.updatedAt.formatted(date: .abbreviated, time: .shortened), icon: "clock.arrow.circlepath")
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
}

// MARK: - Info Row Component

private struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

// MARK: - View Model

@MainActor
final class ItemDetailViewModel: ObservableObject {
    @Published var item: Item
    private let itemRepository: any ItemRepository
    private let locationRepository: (any LocationRepository)?
    @Published var locationName: String?
    
    // Dependencies for creating edit view
    weak var itemsModule: ItemsModuleAPI?
    
    init(
        item: Item,
        itemRepository: any ItemRepository,
        locationRepository: (any LocationRepository)? = nil,
        itemsModule: ItemsModuleAPI? = nil
    ) {
        self.item = item
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.itemsModule = itemsModule
        
        loadLocationName()
    }
    
    private func loadLocationName() {
        guard let locationId = item.locationId,
              let locationRepository = locationRepository else { return }
        
        Task {
            do {
                if let location = try await locationRepository.fetch(id: locationId) {
                    self.locationName = location.name
                }
            } catch {
                print("Failed to load location: \(error)")
            }
        }
    }
    
    func deleteItem() async {
        do {
            try await itemRepository.delete(item)
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    func duplicateItem() async {
        do {
            // Create a copy of the item with a new ID and name
            let duplicatedItem = Item(
                id: UUID(),
                name: "\(item.name) (Copy)",
                brand: item.brand,
                model: item.model,
                category: item.category,
                condition: item.condition,
                quantity: item.quantity,
                value: item.value,
                purchasePrice: item.purchasePrice,
                purchaseDate: item.purchaseDate,
                notes: item.notes,
                barcode: nil, // Don't duplicate barcode as it should be unique
                serialNumber: nil, // Don't duplicate serial number as it should be unique
                tags: item.tags,
                imageIds: [], // Don't duplicate images initially
                locationId: item.locationId,
                warrantyId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await itemRepository.save(duplicatedItem)
            // Note: We don't update the current view as the user might want to continue viewing the original item
        } catch {
            print("Failed to duplicate item: \(error)")
        }
    }
    
    func makeEditView() -> AnyView? {
        itemsModule?.makeEditItemView(item: item) { [weak self] updatedItem in
            self?.item = updatedItem
        }
    }
}
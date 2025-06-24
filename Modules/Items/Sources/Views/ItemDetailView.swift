import SwiftUI
import Core
import SharedUI
import UIKit

struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPhotoGallery = false
    @State private var selectedPhotoIndex = 0
    @State private var photos: [Photo] = []
    @State private var showingDocuments = false
    @State private var documentCount = 0
    @State private var showingCloudSync = false
    @State private var pendingSyncCount = 0
    
    init(viewModel: ItemDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header Section
                headerSection
                
                // Photos Section
                if !photos.isEmpty || !viewModel.item.imageIds.isEmpty {
                    photosSection
                }
                
                // Basic Info Section
                infoSection
                
                // Purchase Info Section
                if viewModel.item.purchasePrice != nil || viewModel.item.purchaseDate != nil {
                    purchaseSection
                }
                
                // Warranty Section
                warrantySection
                
                // Documents Section
                documentsSection
                
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
        .sheet(isPresented: $showingPhotoGallery) {
            PhotoGalleryView(photos: photos, selectedIndex: $selectedPhotoIndex)
        }
        .sheet(isPresented: $viewModel.showingWarrantyDetail) {
            if let warranty = viewModel.warranty,
               let warrantyRepo = viewModel.warrantyRepository {
                WarrantyDetailView(
                    warranty: warranty,
                    itemRepository: viewModel.itemRepository,
                    warrantyRepository: warrantyRepo
                )
            }
        }
        .sheet(isPresented: $viewModel.showingAddWarranty) {
            if let warrantyRepo = viewModel.warrantyRepository {
                AddEditWarrantyView(
                    viewModel: AddEditWarrantyViewModel(
                        itemId: viewModel.item.id,
                        warrantyRepository: warrantyRepo,
                        itemRepository: viewModel.itemRepository,
                        completion: { warranty in
                            viewModel.warranty = warranty
                            viewModel.showingAddWarranty = false
                        }
                    )
                )
            }
        }
        .sheet(isPresented: $showingDocuments) {
            if let documentRepo = viewModel.documentRepository,
               let documentStorage = viewModel.documentStorage {
                NavigationView {
                    ItemDocumentsView(
                        itemId: viewModel.item.id,
                        documentRepository: documentRepo,
                        documentStorage: documentStorage
                    )
                }
            }
        }
        .onAppear {
            loadPhotos()
            loadDocumentCount()
            loadPendingSyncCount()
        }
        .sheet(isPresented: $showingCloudSync) {
            if let documentRepo = viewModel.documentRepository,
               let documentStorage = viewModel.documentStorage,
               let cloudStorage = viewModel.cloudStorage {
                NavigationView {
                    CloudSyncView(
                        cloudStorage: cloudStorage,
                        documentRepository: documentRepo,
                        documentStorage: documentStorage
                    )
                }
            }
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
    
    private var warrantySection: some View {
        Group {
            if let warranty = viewModel.warranty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("WARRANTY")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Spacer()
                        
                        // Warranty status indicator
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: warranty.status.icon)
                                .font(.caption)
                            Text(warranty.status.displayName)
                                .textStyle(.labelSmall)
                        }
                        .foregroundStyle(warrantyStatusColor(warranty.status))
                    }
                    
                    VStack(spacing: AppSpacing.sm) {
                        InfoRow(
                            label: "Provider",
                            value: warranty.provider,
                            icon: warranty.type.icon
                        )
                        
                        InfoRow(
                            label: "Expires",
                            value: warranty.endDate.formatted(date: .abbreviated, time: .omitted),
                            icon: "calendar.badge.clock"
                        )
                        
                        if warranty.daysRemaining > 0 {
                            InfoRow(
                                label: "Days Remaining",
                                value: "\(warranty.daysRemaining)",
                                icon: "clock"
                            )
                        }
                    }
                    
                    Button(action: { viewModel.showWarrantyDetail() }) {
                        Label("View Details", systemImage: "arrow.right.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .appPadding()
                .background(AppColors.background)
                .appCornerRadius(.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(warrantyStatusColor(warranty.status).opacity(0.3), lineWidth: 1)
                )
            } else if viewModel.item.purchaseDate != nil {
                // Show add warranty button if item has purchase date
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("WARRANTY")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textTertiary)
                    
                    HStack {
                        Image(systemName: "shield.slash")
                            .font(.title3)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("No Warranty Added")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("Track warranty expiration dates")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: { viewModel.showAddWarranty() }) {
                        Label("Add Warranty", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .appPadding()
                .background(AppColors.background)
                .appCornerRadius(.medium)
            }
        }
    }
    
    private func warrantyStatusColor(_ status: Warranty.Status) -> Color {
        switch status {
        case .active: return AppColors.success
        case .expiringSoon: return AppColors.warning
        case .expired: return AppColors.error
        }
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
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("DOCUMENTS")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                
                // Cloud sync indicator
                if pendingSyncCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(AppColors.warning)
                        Text("\(pendingSyncCount)")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.warning)
                    }
                } else if documentCount > 0 {
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.success)
                }
                
                Spacer()
                
                if documentCount > 0 {
                    Text("\(documentCount)")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Button(action: { showingDocuments = true }) {
                HStack {
                    Image(systemName: documentCount > 0 ? "doc.fill.badge.plus" : "doc.badge.plus")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(documentCount > 0 ? "Manage Documents" : "Add Documents")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        if documentCount > 0 {
                            Text("Receipts, manuals, warranties")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        } else {
                            Text("Attach PDFs and images")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Cloud sync navigation link
            if documentCount > 0 {
                Button(action: { showingCloudSync = true }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up.down")
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Cloud Sync")
                                .textStyle(.bodyMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if pendingSyncCount > 0 {
                                Text("\(pendingSyncCount) documents pending sync")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            } else {
                                Text("All documents synced")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.sm)
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("PHOTOS")
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
                
                Spacer()
                
                if !photos.isEmpty {
                    Text("\(photos.count)")
                        .textStyle(.labelSmall)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            if photos.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textTertiary)
                    
                    Text("No photos yet")
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(Array(photos.prefix(5).enumerated()), id: \.element.id) { index, photo in
                            PhotoThumbnailButton(photo: photo) {
                                selectedPhotoIndex = index
                                showingPhotoGallery = true
                            }
                        }
                        
                        if photos.count > 5 {
                            MorePhotosButton(count: photos.count - 5) {
                                selectedPhotoIndex = 0
                                showingPhotoGallery = true
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .appPadding()
        .background(AppColors.background)
        .appCornerRadius(.medium)
    }
    
    private func loadPhotos() {
        Task {
            let loadedPhotos = await viewModel.loadPhotos()
            await MainActor.run {
                self.photos = loadedPhotos
            }
        }
    }
    
    private func loadDocumentCount() {
        Task {
            let count = await viewModel.loadDocumentCount()
            await MainActor.run {
                self.documentCount = count
            }
        }
    }
    
    private func loadPendingSyncCount() {
        Task {
            let count = await viewModel.loadPendingSyncCount()
            await MainActor.run {
                self.pendingSyncCount = count
            }
        }
    }
}

// MARK: - Photo Components

private struct PhotoThumbnailButton: View {
    let photo: Photo
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(AppCornerRadius.small)
            } else {
                Rectangle()
                    .fill(AppColors.surface)
                    .frame(width: 120, height: 120)
                    .cornerRadius(AppCornerRadius.small)
                    .overlay {
                        ProgressView()
                    }
            }
        }
    }
}

private struct MorePhotosButton: View {
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(AppColors.surface)
                    .frame(width: 120, height: 120)
                    .cornerRadius(AppCornerRadius.small)
                
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 24))
                    Text("+\(count)")
                        .textStyle(.bodyMedium)
                }
                .foregroundStyle(AppColors.textSecondary)
            }
        }
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
    let itemRepository: any ItemRepository
    private let locationRepository: (any LocationRepository)?
    private let photoRepository: (any PhotoRepository)?
    let warrantyRepository: (any WarrantyRepository)?
    let documentRepository: (any DocumentRepository)?
    let documentStorage: DocumentStorageProtocol?
    let cloudStorage: CloudDocumentStorageProtocol?
    @Published var locationName: String?
    @Published var warranty: Warranty?
    @Published var showingWarrantyDetail = false
    @Published var showingAddWarranty = false
    
    // Dependencies for creating edit view
    weak var itemsModule: ItemsModuleAPI?
    
    init(
        item: Item,
        itemRepository: any ItemRepository,
        locationRepository: (any LocationRepository)? = nil,
        photoRepository: (any PhotoRepository)? = nil,
        warrantyRepository: (any WarrantyRepository)? = nil,
        documentRepository: (any DocumentRepository)? = nil,
        documentStorage: DocumentStorageProtocol? = nil,
        cloudStorage: CloudDocumentStorageProtocol? = nil,
        itemsModule: ItemsModuleAPI? = nil
    ) {
        self.item = item
        self.itemRepository = itemRepository
        self.locationRepository = locationRepository
        self.photoRepository = photoRepository
        self.warrantyRepository = warrantyRepository
        self.documentRepository = documentRepository
        self.documentStorage = documentStorage
        self.cloudStorage = cloudStorage
        self.itemsModule = itemsModule
        
        loadLocationName()
        loadWarranty()
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
    
    func loadPhotos() async -> [Photo] {
        guard let photoRepository = photoRepository else {
            // Return mock photos if no repository
            return item.imageIds.enumerated().map { index, id in
                var photo = Photo(
                    id: id,
                    itemId: item.id,
                    caption: "Photo \(index + 1)",
                    sortOrder: index
                )
                photo.image = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
                return photo
            }
        }
        
        do {
            var photos = try await photoRepository.loadPhotos(for: item.id)
            
            // Load images for each photo
            for i in 0..<photos.count {
                if let loadedPhoto = try? await photoRepository.loadPhoto(id: photos[i].id) {
                    photos[i] = loadedPhoto
                }
            }
            
            return photos
        } catch {
            print("Failed to load photos: \(error)")
            return []
        }
    }
    
    private func loadWarranty() {
        guard let warrantyRepository = warrantyRepository else { return }
        
        Task {
            do {
                let warranties = try await warrantyRepository.fetchWarranties(for: item.id)
                if let firstWarranty = warranties.first {
                    self.warranty = firstWarranty
                }
            } catch {
                print("Failed to load warranty: \(error)")
            }
        }
    }
    
    func showWarrantyDetail() {
        showingWarrantyDetail = true
    }
    
    func showAddWarranty() {
        showingAddWarranty = true
    }
    
    func loadDocumentCount() async -> Int {
        guard let documentRepository = documentRepository else { return 0 }
        
        do {
            let documents = try await documentRepository.fetchByItemId(item.id)
            return documents.count
        } catch {
            print("Failed to load document count: \(error)")
            return 0
        }
    }
    
    func loadPendingSyncCount() async -> Int {
        guard let documentRepository = documentRepository else { return 0 }
        
        do {
            // Get all documents for this item
            let documents = try await documentRepository.fetchByItemId(item.id)
            
            // Get sync service instance and check sync queue
            let syncService = CloudSyncService.shared
            let pendingCount = syncService.syncQueue.filter { queueItem in
                documents.contains { $0.id == queueItem.documentId }
            }.count
            
            return pendingCount
        } catch {
            print("Failed to load pending sync count: \(error)")
            return 0
        }
    }
}
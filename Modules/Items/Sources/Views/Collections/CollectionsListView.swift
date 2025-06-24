import SwiftUI
import Core
import SharedUI

/// View for displaying and managing collections
/// Swift 5.9 - No Swift 6 features
public struct CollectionsListView: View {
    @StateObject private var viewModel: CollectionsListViewModel
    @State private var showingAddCollection = false
    @State private var selectedCollection: Collection?
    @State private var showingDeleteAlert = false
    @State private var collectionToDelete: Collection?
    
    public init(
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onSelectCollection: @escaping (Collection) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: CollectionsListViewModel(
                collectionRepository: collectionRepository,
                itemRepository: itemRepository,
                onSelectCollection: onSelectCollection
            )
        )
    }
    
    public var body: some View {
        List {
            if !viewModel.activeCollections.isEmpty {
                Section {
                    ForEach(viewModel.activeCollections) { collection in
                        CollectionRow(
                            collection: collection,
                            itemCount: viewModel.itemCounts[collection.id] ?? 0,
                            onTap: {
                                viewModel.selectCollection(collection)
                            },
                            onEdit: {
                                selectedCollection = collection
                            },
                            onArchive: {
                                viewModel.archiveCollection(collection)
                            },
                            onDelete: {
                                collectionToDelete = collection
                                showingDeleteAlert = true
                            }
                        )
                    }
                } header: {
                    Text("Active Collections")
                }
            }
            
            if !viewModel.archivedCollections.isEmpty {
                Section {
                    ForEach(viewModel.archivedCollections) { collection in
                        CollectionRow(
                            collection: collection,
                            itemCount: viewModel.itemCounts[collection.id] ?? 0,
                            isArchived: true,
                            onTap: {
                                viewModel.selectCollection(collection)
                            },
                            onEdit: {
                                selectedCollection = collection
                            },
                            onUnarchive: {
                                viewModel.unarchiveCollection(collection)
                            },
                            onDelete: {
                                collectionToDelete = collection
                                showingDeleteAlert = true
                            }
                        )
                    }
                } header: {
                    Text("Archived Collections")
                }
            }
            
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Loading collections...")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            } else if viewModel.activeCollections.isEmpty && viewModel.archivedCollections.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Collections",
                        systemImage: "folder",
                        description: Text("Create collections to group related items together")
                    )
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCollection = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            AddEditCollectionView(
                collectionRepository: viewModel.collectionRepository,
                onComplete: { _ in
                    viewModel.loadCollections()
                }
            )
        }
        .sheet(item: $selectedCollection) { collection in
            AddEditCollectionView(
                collection: collection,
                collectionRepository: viewModel.collectionRepository,
                onComplete: { _ in
                    viewModel.loadCollections()
                }
            )
        }
        .alert("Delete Collection?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let collection = collectionToDelete {
                    viewModel.deleteCollection(collection)
                }
            }
        } message: {
            if let collection = collectionToDelete {
                Text("Are you sure you want to delete '\(collection.name)'? This action cannot be undone.")
            }
        }
        .onAppear {
            viewModel.loadCollections()
        }
    }
}

// MARK: - Collection Row
private struct CollectionRow: View {
    let collection: Collection
    let itemCount: Int
    var isArchived: Bool = false
    let onTap: () -> Void
    var onEdit: (() -> Void)? = nil
    var onArchive: (() -> Void)? = nil
    var onUnarchive: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                Image(systemName: collection.icon)
                    .font(.title2)
                    .foregroundStyle(Color.named(collection.color))
                    .frame(width: 44, height: 44)
                    .background(Color.named(collection.color).opacity(0.1))
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(collection.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(isArchived ? AppColors.textSecondary : AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Text("\(itemCount) items")
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        if let description = collection.description {
                            Text("•")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            Text(description)
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                                .lineLimit(1)
                        }
                        
                        if isArchived {
                            Text("•")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            Text("Archived")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.warning)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(AppColors.primary)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if isArchived, let onUnarchive = onUnarchive {
                Button(action: onUnarchive) {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                }
                .tint(AppColors.success)
            } else if !isArchived, let onArchive = onArchive {
                Button(action: onArchive) {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(AppColors.warning)
            }
        }
    }
}

// MARK: - View Model
@MainActor
final class CollectionsListViewModel: ObservableObject {
    @Published var activeCollections: [Collection] = []
    @Published var archivedCollections: [Collection] = []
    @Published var itemCounts: [UUID: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let collectionRepository: any CollectionRepository
    let itemRepository: any ItemRepository
    let onSelectCollection: (Collection) -> Void
    
    init(
        collectionRepository: any CollectionRepository,
        itemRepository: any ItemRepository,
        onSelectCollection: @escaping (Collection) -> Void
    ) {
        self.collectionRepository = collectionRepository
        self.itemRepository = itemRepository
        self.onSelectCollection = onSelectCollection
    }
    
    func loadCollections() {
        Task {
            isLoading = true
            do {
                // Load collections
                activeCollections = try await collectionRepository.fetchActive()
                archivedCollections = try await collectionRepository.fetchArchived()
                
                // Load item counts
                let allItems = try await itemRepository.fetchAll()
                var counts: [UUID: Int] = [:]
                
                for collection in (activeCollections + archivedCollections) {
                    let count = allItems.filter { collection.itemIds.contains($0.id) }.count
                    counts[collection.id] = count
                }
                
                itemCounts = counts
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func selectCollection(_ collection: Collection) {
        onSelectCollection(collection)
    }
    
    func archiveCollection(_ collection: Collection) {
        Task {
            do {
                try await collectionRepository.archive(collection.id)
                await loadCollections()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func unarchiveCollection(_ collection: Collection) {
        Task {
            do {
                try await collectionRepository.unarchive(collection.id)
                await loadCollections()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteCollection(_ collection: Collection) {
        Task {
            do {
                try await collectionRepository.delete(collection)
                await loadCollections()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
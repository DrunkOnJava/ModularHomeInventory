import SwiftUI
import Core
import SharedUI

/// Context menu support for iPad
/// Provides right-click and long-press context menus
struct iPadContextMenus {
    
    // MARK: - Item Context Menu
    
    static func itemContextMenu(
        for item: Item,
        onEdit: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onMove: @escaping () -> Void,
        onAddToCollection: @escaping () -> Void
    ) -> some View {
        Group {
            Section {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Item", systemImage: "pencil")
                }
                
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
            }
            
            Section {
                Button {
                    onMove()
                } label: {
                    Label("Move to...", systemImage: "folder")
                }
                
                Button {
                    onAddToCollection()
                } label: {
                    Label("Add to Collection", systemImage: "folder.badge.plus")
                }
            }
            
            Section {
                Button {
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    // Export as CSV
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up.on.square")
                }
                
                Button {
                    // Print item details
                } label: {
                    Label("Print", systemImage: "printer")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - Collection Context Menu
    
    static func collectionContextMenu(
        for collection: Collection,
        onEdit: @escaping () -> Void,
        onAddItems: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        Group {
            Section {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Collection", systemImage: "pencil")
                }
                
                Button {
                    onAddItems()
                } label: {
                    Label("Add Items", systemImage: "plus.circle")
                }
            }
            
            Section {
                Button {
                    onShare()
                } label: {
                    Label("Share Collection", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    onExport()
                } label: {
                    Label("Export as CSV", systemImage: "doc.plaintext")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - Photo Context Menu
    
    static func photoContextMenu(
        onView: @escaping () -> Void,
        onSaveToPhotos: @escaping () -> Void,
        onShare: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        Group {
            Button {
                onView()
            } label: {
                Label("View Full Size", systemImage: "eye")
            }
            
            Button {
                onSaveToPhotos()
            } label: {
                Label("Save to Photos", systemImage: "square.and.arrow.down")
            }
            
            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Photo", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Receipt Context Menu
    
    static func receiptContextMenu(
        onView: @escaping () -> Void,
        onReparse: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        Group {
            Button {
                onView()
            } label: {
                Label("View Receipt", systemImage: "doc.text")
            }
            
            Button {
                onReparse()
            } label: {
                Label("Re-scan Receipt", systemImage: "doc.text.magnifyingglass")
            }
            
            Button {
                onExport()
            } label: {
                Label("Export PDF", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Receipt", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Empty Space Context Menu
    
    static func emptySpaceContextMenu(
        onNewItem: @escaping () -> Void,
        onImport: @escaping () -> Void,
        onPaste: @escaping () -> Void
    ) -> some View {
        Group {
            Button {
                onNewItem()
            } label: {
                Label("New Item", systemImage: "plus")
            }
            
            Button {
                onImport()
            } label: {
                Label("Import Items", systemImage: "square.and.arrow.down")
            }
            
            Button {
                onPaste()
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
            .disabled(!UIPasteboard.general.hasStrings)
        }
    }
}

// MARK: - Context Menu View Modifiers

struct ItemContextMenuModifier: ViewModifier {
    let item: Item
    @State private var showEditSheet = false
    @State private var showMoveSheet = false
    @State private var showCollectionPicker = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                iPadContextMenus.itemContextMenu(
                    for: item,
                    onEdit: { showEditSheet = true },
                    onDuplicate: { duplicateItem() },
                    onDelete: { showDeleteAlert = true },
                    onShare: { showShareSheet = true },
                    onMove: { showMoveSheet = true },
                    onAddToCollection: { showCollectionPicker = true }
                )
            }
            .sheet(isPresented: $showEditSheet) {
                EditItemSheet(item: item)
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveItemSheet(item: item)
            }
            .sheet(isPresented: $showCollectionPicker) {
                CollectionPickerSheet(item: item)
            }
            .alert("Delete Item", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(item.name)\"? This action cannot be undone.")
            }
    }
    
    private func duplicateItem() {
        // TODO: Implement item duplication
    }
    
    private func deleteItem() {
        // TODO: Implement item deletion
    }
}

// MARK: - Helper Sheets

struct EditItemSheet: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            // EditItemView(item: item)
            Text("Edit: \(item.name)")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { dismiss() }
                    }
                }
        }
    }
}

struct MoveItemSheet: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLocation: Location?
    
    var body: some View {
        NavigationView {
            List {
                // Location picker
                Text("Select location for: \(item.name)")
            }
            .navigationTitle("Move Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") { 
                        // TODO: Move item
                        dismiss() 
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
    }
}

struct CollectionPickerSheet: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCollections: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            List {
                // Collection picker
                Text("Add \"\(item.name)\" to collections")
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { 
                        // TODO: Add to collections
                        dismiss() 
                    }
                    .disabled(selectedCollections.isEmpty)
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func itemContextMenu(_ item: Item) -> some View {
        self.modifier(ItemContextMenuModifier(item: item))
    }
    
    func emptySpaceContextMenu(
        onNewItem: @escaping () -> Void,
        onImport: @escaping () -> Void
    ) -> some View {
        self.contextMenu {
            iPadContextMenus.emptySpaceContextMenu(
                onNewItem: onNewItem,
                onImport: onImport,
                onPaste: {
                    // Handle paste from clipboard
                    if let string = UIPasteboard.general.string {
                        // Parse and create item
                        print("Pasting: \(string)")
                    }
                }
            )
        }
    }
}

// MARK: - Multi-Selection Context Menu

struct MultiSelectionContextMenu: View {
    let selectedItems: Set<UUID>
    let onDelete: () -> Void
    let onMove: () -> Void
    let onAddToCollection: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        Group {
            Section {
                Button {
                    onMove()
                } label: {
                    Label("Move \(selectedItems.count) Items", systemImage: "folder")
                }
                
                Button {
                    onAddToCollection()
                } label: {
                    Label("Add to Collection", systemImage: "folder.badge.plus")
                }
            }
            
            Section {
                Button {
                    onExport()
                } label: {
                    Label("Export Selected", systemImage: "square.and.arrow.up")
                }
            }
            
            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete \(selectedItems.count) Items", systemImage: "trash")
                }
            }
        }
    }
}
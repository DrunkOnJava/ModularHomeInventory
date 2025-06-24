import SwiftUI
import Core
import SharedUI

/// View for adding or editing a collection
/// Swift 5.9 - No Swift 6 features
struct AddEditCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let collection: Collection?
    let collectionRepository: any CollectionRepository
    let onComplete: (Collection) -> Void
    
    private let isEditing: Bool
    
    // Available icons for collections
    let availableIcons = [
        "folder", "star", "heart", "flag", "bookmark", "tag",
        "gift", "camera", "airplane", "car", "house", "briefcase",
        "graduationcap", "book", "music.note", "gamecontroller",
        "teddybear", "pawprint", "leaf", "flame", "drop", "snowflake",
        "sun.max", "moon", "sparkles", "bolt", "battery.100", "cpu",
        "desktopcomputer", "keyboard", "printer", "tv", "headphones",
        "speaker.wave.3", "mic", "video", "phone", "envelope",
        "paperplane", "bubble.left", "quote.bubble", "exclamationmark.triangle",
        "checkmark.circle", "xmark.circle", "plus.circle", "minus.circle"
    ]
    
    let availableColors = [
        "blue", "purple", "pink", "red", "orange",
        "yellow", "green", "mint", "teal", "cyan",
        "indigo", "brown", "gray", "black"
    ]
    
    
    init(
        collection: Collection? = nil,
        collectionRepository: any CollectionRepository,
        onComplete: @escaping (Collection) -> Void
    ) {
        self.collection = collection
        self.collectionRepository = collectionRepository
        self.onComplete = onComplete
        self.isEditing = collection != nil
        
        // Initialize state
        _name = State(initialValue: collection?.name ?? "")
        _description = State(initialValue: collection?.description ?? "")
        _selectedIcon = State(initialValue: collection?.icon ?? "folder")
        _selectedColor = State(initialValue: collection?.color ?? "blue")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Collection Details
                Section {
                    TextField("Collection Name", text: $name)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .padding(AppSpacing.sm)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppCornerRadius.small)
                        .lineLimit(2...4)
                } header: {
                    Text("Collection Details")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Icon Selection
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: AppSpacing.md) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(selectedIcon == icon ? .white : AppColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedIcon == icon 
                                        ? AppColors.primary 
                                        : Color(.systemGray5)
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedIcon == icon 
                                                ? AppColors.primary 
                                                : Color(.systemGray3), 
                                            lineWidth: selectedIcon == icon ? 3 : 1
                                        )
                                )
                                .contentShape(Circle())
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                } header: {
                    Text("Icon")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Color Selection
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.md) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color.named(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemGray3), lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? .white : .clear, lineWidth: 3)
                                        .padding(2)
                                )
                                .scaleEffect(selectedColor == color ? 1.15 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedColor == color)
                                .contentShape(Circle())
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                } header: {
                    Text("Color")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                // Preview
                Section {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundStyle(Color.named(selectedColor))
                            .frame(width: 50, height: 50)
                            .background(Color.named(selectedColor).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(name.isEmpty ? "Collection Name" : name)
                                .textStyle(.headlineMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if !description.isEmpty {
                                Text(description)
                                    .textStyle(.bodySmall)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.sm)
                } header: {
                    Text("Preview")
                        .textStyle(.labelLarge)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle(isEditing ? "Edit Collection" : "New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCollection()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.isEmpty || isLoading ? AppColors.textTertiary : AppColors.primary)
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func saveCollection() {
        Task {
            isLoading = true
            do {
                let newCollection: Collection
                
                if let existingCollection = collection {
                    // Update existing collection
                    newCollection = Collection(
                        id: existingCollection.id,
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                        icon: selectedIcon,
                        color: selectedColor,
                        itemIds: existingCollection.itemIds,
                        isArchived: existingCollection.isArchived,
                        createdAt: existingCollection.createdAt,
                        updatedAt: Date()
                    )
                } else {
                    // Create new collection
                    newCollection = Collection(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                        icon: selectedIcon,
                        color: selectedColor
                    )
                }
                
                try await collectionRepository.save(newCollection)
                onComplete(newCollection)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
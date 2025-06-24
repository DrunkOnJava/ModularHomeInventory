import SwiftUI
import Core
import SharedUI

/// View for managing custom categories with subcategory support
/// Swift 5.9 - No Swift 6 features
public struct CategoryManagementView: View {
    @StateObject private var viewModel: CategoryManagementViewModel
    @State private var showingAddCategory = false
    @State private var selectedCategory: ItemCategoryModel?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: ItemCategoryModel?
    @State private var selectedParentCategory: ItemCategoryModel?
    @State private var expandedCategories: Set<UUID> = []
    
    public init(categoryRepository: any CategoryRepository) {
        _viewModel = StateObject(wrappedValue: CategoryManagementViewModel(categoryRepository: categoryRepository))
    }
    
    public var body: some View {
        NavigationView {
            List {
                // Built-in categories section
                Section(header: Text("Built-in Categories")) {
                    ForEach(viewModel.builtInCategories) { category in
                        CategoryRowView(
                            category: category,
                            subcategories: viewModel.subcategories[category.id] ?? [],
                            isEditable: false,
                            isExpanded: expandedCategories.contains(category.id),
                            onToggleExpand: { toggleExpanded(category.id) },
                            onAddSubcategory: { 
                                selectedParentCategory = category
                                showingAddCategory = true
                            },
                            onEdit: { },
                            onDelete: { }
                        )
                    }
                }
                
                // Custom categories section
                if !viewModel.customCategories.isEmpty {
                    Section(header: Text("Custom Categories")) {
                        ForEach(viewModel.rootCustomCategories) { category in
                            CategoryRowView(
                                category: category,
                                subcategories: viewModel.subcategories[category.id] ?? [],
                                isEditable: true,
                                isExpanded: expandedCategories.contains(category.id),
                                onToggleExpand: { toggleExpanded(category.id) },
                                onAddSubcategory: {
                                    selectedParentCategory = category
                                    showingAddCategory = true
                                },
                                onEdit: {
                                    selectedCategory = category
                                },
                                onDelete: {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        selectedParentCategory = nil
                        showingAddCategory = true 
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(
                    categoryRepository: viewModel.categoryRepository,
                    parentCategory: selectedParentCategory
                ) { _ in
                    viewModel.loadCategories()
                }
            }
            .sheet(item: $selectedCategory) { category in
                EditCategoryView(
                    category: category,
                    categoryRepository: viewModel.categoryRepository
                ) {
                    viewModel.loadCategories()
                }
            }
            .alert("Delete Category?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        viewModel.deleteCategory(category)
                    }
                }
            } message: {
                if let category = categoryToDelete,
                   let subcategories = viewModel.subcategories[category.id],
                   !subcategories.isEmpty {
                    Text("This category has \(subcategories.count) subcategories. Deleting it will also delete all subcategories. This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this category? This action cannot be undone.")
                }
            }
            .onAppear {
                viewModel.loadCategories()
            }
        }
    }
    
    private func toggleExpanded(_ categoryId: UUID) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
    }
}

// MARK: - Category Row View with Subcategory Support
private struct CategoryRowView: View {
    let category: ItemCategoryModel
    let subcategories: [ItemCategoryModel]
    let isEditable: Bool
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAddSubcategory: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.md) {
                // Expand/Collapse button
                if !subcategories.isEmpty {
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 20)
                }
                
                // Icon
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(category.color))
                    .frame(width: 40, height: 40)
                    .background(Color(category.color).opacity(0.1))
                    .clipShape(Circle())
                
                // Name and info
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(category.name)
                        .textStyle(.bodyLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        if !isEditable {
                            Text("Built-in")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        
                        if !subcategories.isEmpty {
                            Text("\(subcategories.count) subcategories")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                if isEditable {
                    Menu {
                        Button(action: onAddSubcategory) {
                            Label("Add Subcategory", systemImage: "plus.square")
                        }
                        
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 30, height: 30)
                    }
                } else if category.parentId == nil {
                    // Allow adding subcategories to built-in categories
                    Button(action: onAddSubcategory) {
                        Image(systemName: "plus.square")
                            .font(.body)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .padding(.vertical, AppSpacing.sm)
            
            // Subcategories
            if isExpanded && !subcategories.isEmpty {
                VStack(spacing: 0) {
                    ForEach(subcategories) { subcategory in
                        SubcategoryRowView(
                            category: subcategory,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                        .padding(.leading, 40)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Subcategory Row View
private struct SubcategoryRowView: View {
    let category: ItemCategoryModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(Color(category.color))
                .frame(width: 30, height: 30)
                .background(Color(category.color).opacity(0.1))
                .clipShape(Circle())
            
            // Name
            Text(category.name)
                .textStyle(.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            // Actions
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 25, height: 25)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - View Model
@MainActor
final class CategoryManagementViewModel: ObservableObject {
    @Published var builtInCategories: [ItemCategoryModel] = []
    @Published var customCategories: [ItemCategoryModel] = []
    @Published var subcategories: [UUID: [ItemCategoryModel]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let categoryRepository: any CategoryRepository
    
    var rootCustomCategories: [ItemCategoryModel] {
        customCategories.filter { $0.parentId == nil }
    }
    
    init(categoryRepository: any CategoryRepository) {
        self.categoryRepository = categoryRepository
    }
    
    func loadCategories() {
        Task {
            isLoading = true
            do {
                let allCategories = try await categoryRepository.fetchAll()
                
                // Separate built-in and custom categories
                builtInCategories = allCategories.filter { $0.isBuiltIn && $0.parentId == nil }
                customCategories = allCategories.filter { !$0.isBuiltIn }
                
                // Build subcategory map
                subcategories = [:]
                for category in allCategories {
                    if let parentId = category.parentId {
                        if subcategories[parentId] == nil {
                            subcategories[parentId] = []
                        }
                        subcategories[parentId]?.append(category)
                    }
                }
                
                // Sort subcategories
                for (parentId, subs) in subcategories {
                    subcategories[parentId] = subs.sorted { $0.sortOrder < $1.sortOrder }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func deleteCategory(_ category: ItemCategoryModel) {
        Task {
            do {
                // Delete all subcategories first
                if let subs = subcategories[category.id] {
                    for subcategory in subs {
                        try await categoryRepository.delete(subcategory)
                    }
                }
                
                // Delete the category itself
                try await categoryRepository.delete(category)
                await loadCategories()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Add Category View with Parent Support
struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let categoryRepository: any CategoryRepository
    let parentCategory: ItemCategoryModel?
    let onComplete: (ItemCategoryModel) -> Void
    
    // Common category icons
    let availableIcons = [
        "folder", "tag", "star", "heart", "flag", "bookmark",
        "gift", "camera", "music.note", "gamecontroller",
        "tv", "headphones", "keyboard", "printer", "scanner",
        "wifi", "battery.100", "power", "lock", "key",
        "creditcard", "cart", "bag", "basket", "archivebox",
        "tray", "doc", "book.closed", "newspaper", "magazine",
        "graduationcap", "backpack", "briefcase", "suitcase", "latch.2.case",
        "cross.case", "pills", "bandage", "syringe", "stethoscope"
    ]
    
    let availableColors = [
        "blue", "purple", "pink", "red", "orange",
        "yellow", "green", "mint", "teal", "cyan",
        "indigo", "brown", "gray", "black"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                if let parent = parentCategory {
                    Section(header: Text("Parent Category")) {
                        HStack {
                            Image(systemName: parent.icon)
                                .font(.title3)
                                .foregroundStyle(Color(parent.color))
                                .frame(width: 40, height: 40)
                                .background(Color(parent.color).opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(parent.name)
                                .textStyle(.bodyLarge)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
                
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: AppSpacing.md) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : AppColors.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? AppColors.primary : AppColors.surface)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? AppColors.primary : AppColors.border, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.md) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? AppColors.textPrimary : .clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundStyle(Color(selectedColor))
                            .frame(width: 50, height: 50)
                            .background(Color(selectedColor).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(name.isEmpty ? "Category Name" : name)
                                .textStyle(.headlineMedium)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if let parent = parentCategory {
                                Text("Subcategory of \(parent.name)")
                                    .textStyle(.labelSmall)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
            .navigationTitle(parentCategory != nil ? "New Subcategory" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
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
    
    private func saveCategory() {
        Task {
            isLoading = true
            do {
                // Calculate sort order
                let existingCategories = try await categoryRepository.fetchByParent(id: parentCategory?.id)
                let maxSortOrder = existingCategories.map { $0.sortOrder }.max() ?? 0
                
                let category = ItemCategoryModel(
                    name: name,
                    icon: selectedIcon,
                    color: selectedColor,
                    isBuiltIn: false,
                    parentId: parentCategory?.id,
                    sortOrder: maxSortOrder + 1
                )
                try await categoryRepository.save(category)
                onComplete(category)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let category: ItemCategoryModel
    let categoryRepository: any CategoryRepository
    let onComplete: () -> Void
    
    init(category: ItemCategoryModel, categoryRepository: any CategoryRepository, onComplete: @escaping () -> Void) {
        self.category = category
        self.categoryRepository = categoryRepository
        self.onComplete = onComplete
        _name = State(initialValue: category.name)
        _selectedIcon = State(initialValue: category.icon)
        _selectedColor = State(initialValue: category.color)
    }
    
    // Same icon and color arrays as AddCategoryView
    let availableIcons = [
        "folder", "tag", "star", "heart", "flag", "bookmark",
        "gift", "camera", "music.note", "gamecontroller",
        "tv", "headphones", "keyboard", "printer", "scanner",
        "wifi", "battery.100", "power", "lock", "key",
        "creditcard", "cart", "bag", "basket", "archivebox",
        "tray", "doc", "book.closed", "newspaper", "magazine",
        "graduationcap", "backpack", "briefcase", "suitcase", "latch.2.case",
        "cross.case", "pills", "bandage", "syringe", "stethoscope"
    ]
    
    let availableColors = [
        "blue", "purple", "pink", "red", "orange",
        "yellow", "green", "mint", "teal", "cyan",
        "indigo", "brown", "gray", "black"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: AppSpacing.md) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? .white : AppColors.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? AppColors.primary : AppColors.surface)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? AppColors.primary : AppColors.border, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.md) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? AppColors.textPrimary : .clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundStyle(Color(selectedColor))
                            .frame(width: 50, height: 50)
                            .background(Color(selectedColor).opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .textStyle(.headlineMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
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
    
    private func saveCategory() {
        Task {
            isLoading = true
            do {
                var updatedCategory = category
                updatedCategory.name = name
                updatedCategory.icon = selectedIcon
                updatedCategory.color = selectedColor
                updatedCategory.updatedAt = Date()
                
                try await categoryRepository.save(updatedCategory)
                onComplete()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
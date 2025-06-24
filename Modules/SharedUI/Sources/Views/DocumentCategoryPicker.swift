import SwiftUI
import Core

/// Document category picker with subcategory support
/// Swift 5.9 - No Swift 6 features
public struct DocumentCategoryPicker: View {
    @Binding var category: Document.DocumentCategory
    @Binding var subcategory: String?
    @State private var showingSubcategoryPicker = false
    
    public init(category: Binding<Document.DocumentCategory>, subcategory: Binding<String?>) {
        self._category = category
        self._subcategory = subcategory
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Picker
            Menu {
                ForEach(Document.DocumentCategory.allCases, id: \.self) { cat in
                    Button(action: {
                        category = cat
                        subcategory = nil // Reset subcategory when category changes
                    }) {
                        Label(cat.displayName, systemImage: cat.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.color))
                    Text(category.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Subcategory Picker (if available)
            if !category.subcategories.isEmpty {
                Menu {
                    Button(action: { subcategory = nil }) {
                        Text("None")
                    }
                    Divider()
                    ForEach(category.subcategories, id: \.self) { subcat in
                        Button(action: { subcategory = subcat }) {
                            Text(subcat)
                        }
                    }
                } label: {
                    HStack {
                        Text("Subcategory")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(subcategory ?? "Select")
                            .foregroundStyle(subcategory != nil ? .primary : .secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

/// Document category filter view
public struct DocumentCategoryFilter: View {
    @Binding var selectedCategories: Set<Document.DocumentCategory>
    @State private var showingAllCategories = false
    
    public init(selectedCategories: Binding<Set<Document.DocumentCategory>>) {
        self._selectedCategories = selectedCategories
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Categories chip
                Button(action: {
                    selectedCategories.removeAll()
                }) {
                    Text("All")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategories.isEmpty ? Color.accentColor : Color(.systemGray6))
                        .foregroundStyle(selectedCategories.isEmpty ? .white : .primary)
                        .cornerRadius(16)
                }
                
                // Individual category chips
                ForEach(Document.DocumentCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        action: {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual category filter chip
struct CategoryFilterChip: View {
    let category: Document.DocumentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: category.color) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

/// Document organization grid view
public struct DocumentOrganizationView: View {
    let documents: [Document]
    @State private var selectedCategories: Set<Document.DocumentCategory> = []
    @State private var groupBySubcategory = false
    
    public init(documents: [Document]) {
        self.documents = documents
    }
    
    private var filteredDocuments: [Document] {
        if selectedCategories.isEmpty {
            return documents
        }
        return documents.filter { selectedCategories.contains($0.category) }
    }
    
    private var groupedDocuments: [String: [Document]] {
        if groupBySubcategory {
            return Dictionary(grouping: filteredDocuments) { document in
                if let subcategory = document.subcategory {
                    return "\(document.category.displayName) - \(subcategory)"
                }
                return document.category.displayName
            }
        } else {
            return Dictionary(grouping: filteredDocuments) { $0.category.displayName }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            DocumentCategoryFilter(selectedCategories: $selectedCategories)
                .padding(.vertical, 8)
            
            // Group by toggle
            HStack {
                Text("Group by subcategory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("", isOn: $groupBySubcategory)
                    .labelsHidden()
            }
            .padding(.horizontal)
            
            Divider()
            
            // Grouped documents
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedDocuments.keys.sorted(), id: \.self) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(groupedDocuments[group] ?? []) { document in
                                        DocumentCard(document: document)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

/// Document card for grid display
struct DocumentCard: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail or icon
            ZStack {
                if let thumbnailData = document.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 160)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(hex: document.category.color).opacity(0.1))
                        .frame(width: 120, height: 160)
                        .overlay {
                            Image(systemName: document.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(Color(hex: document.category.color))
                        }
                }
            }
            .cornerRadius(8)
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                if let subcategory = document.subcategory {
                    Text(subcategory)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if let pageCount = document.pageCount {
                        Text("\(pageCount)p")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(document.formattedFileSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, alignment: .leading)
        }
    }
}


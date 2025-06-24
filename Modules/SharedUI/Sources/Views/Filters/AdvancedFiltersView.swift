import SwiftUI
import Core

/// Advanced filtering view with multiple criteria
/// Swift 5.9 - No Swift 6 features
public struct AdvancedFiltersView: View {
    @StateObject private var viewModel: AdvancedFiltersViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(
        currentFilters: ItemFilters,
        onApply: @escaping (ItemFilters) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: AdvancedFiltersViewModel(
            currentFilters: currentFilters,
            onApply: onApply
        ))
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Search Section
                searchSection
                
                // Categories Section
                categoriesSection
                
                // Price Range Section
                priceRangeSection
                
                // Date Range Section
                dateRangeSection
                
                // Location Section
                locationSection
                
                // Tags Section
                tagsSection
                
                // Additional Filters
                additionalFiltersSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("Clear All") {
                            viewModel.clearAllFilters()
                        }
                        .foregroundStyle(.red)
                        
                        Spacer()
                        
                        if viewModel.activeFilterCount > 0 {
                            Text("\(viewModel.activeFilterCount) Active")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var searchSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textTertiary)
                TextField("Search items...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        } header: {
            Text("Search")
        }
    }
    
    private var categoriesSection: some View {
        Section {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                FilterToggleRow(
                    title: category.displayName,
                    icon: category.icon,
                    isSelected: viewModel.selectedCategories.contains(category)
                ) {
                    viewModel.toggleCategory(category)
                }
            }
        } header: {
            HStack {
                Text("Categories")
                Spacer()
                if !viewModel.selectedCategories.isEmpty {
                    Button("Clear") {
                        viewModel.selectedCategories.removeAll()
                    }
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
    
    private var priceRangeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Price range slider
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("$\(Int(viewModel.minPrice))")
                            .textStyle(.bodySmall)
                        Spacer()
                        Text("$\(Int(viewModel.maxPrice))")
                            .textStyle(.bodySmall)
                    }
                    .foregroundStyle(AppColors.textSecondary)
                    
                    RangeSlider(
                        minValue: $viewModel.minPrice,
                        maxValue: $viewModel.maxPrice,
                        bounds: 0...10000
                    )
                }
                
                // Quick price ranges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.quickPriceRanges, id: \.label) { range in
                            Button(action: { viewModel.applyPriceRange(range) }) {
                                Text(range.label)
                                    .textStyle(.labelSmall)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(
                                        range.min == viewModel.minPrice && range.max == viewModel.maxPrice
                                            ? AppColors.primary
                                            : AppColors.surface
                                    )
                                    .foregroundStyle(
                                        range.min == viewModel.minPrice && range.max == viewModel.maxPrice
                                            ? .white
                                            : AppColors.textPrimary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Price Range")
        }
    }
    
    private var dateRangeSection: some View {
        Section {
            DatePicker(
                "From",
                selection: $viewModel.startDate,
                in: ...Date(),
                displayedComponents: .date
            )
            
            DatePicker(
                "To",
                selection: $viewModel.endDate,
                in: viewModel.startDate...Date(),
                displayedComponents: .date
            )
            
            // Quick date ranges
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.quickDateRanges, id: \.label) { range in
                        Button(action: { viewModel.applyDateRange(range) }) {
                            Text(range.label)
                                .textStyle(.labelSmall)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    viewModel.isDateRangeActive(range)
                                        ? AppColors.primary
                                        : AppColors.surface
                                )
                                .foregroundStyle(
                                    viewModel.isDateRangeActive(range)
                                        ? .white
                                        : AppColors.textPrimary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Purchase Date")
                Spacer()
                Toggle("", isOn: $viewModel.useDateFilter)
                    .labelsHidden()
            }
        }
        .disabled(!viewModel.useDateFilter)
        .opacity(viewModel.useDateFilter ? 1 : 0.5)
    }
    
    private var locationSection: some View {
        Section {
            if viewModel.locations.isEmpty {
                Text("No locations available")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                ForEach(viewModel.locations) { location in
                    FilterToggleRow(
                        title: location.name,
                        icon: location.icon ?? "location",
                        isSelected: viewModel.selectedLocations.contains(location.id)
                    ) {
                        viewModel.toggleLocation(location.id)
                    }
                }
            }
        } header: {
            HStack {
                Text("Locations")
                Spacer()
                if !viewModel.selectedLocations.isEmpty {
                    Button("Clear") {
                        viewModel.selectedLocations.removeAll()
                    }
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        Section {
            if viewModel.tags.isEmpty {
                Text("No tags available")
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                TagCloudView(
                    tags: viewModel.tags,
                    selectedTags: $viewModel.selectedTags
                )
            }
        } header: {
            HStack {
                Text("Tags")
                Spacer()
                if !viewModel.selectedTags.isEmpty {
                    Button("Clear") {
                        viewModel.selectedTags.removeAll()
                    }
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
    
    private var additionalFiltersSection: some View {
        Section {
            // Has Photos
            Toggle(isOn: $viewModel.hasPhotos) {
                Label("Has Photos", systemImage: "photo")
            }
            
            // Has Receipt
            Toggle(isOn: $viewModel.hasReceipt) {
                Label("Has Receipt", systemImage: "doc.text")
            }
            
            // Has Warranty
            Toggle(isOn: $viewModel.hasWarranty) {
                Label("Has Warranty", systemImage: "shield")
            }
            
            // Is Favorite
            Toggle(isOn: $viewModel.isFavorite) {
                Label("Favorites Only", systemImage: "star.fill")
                    .foregroundStyle(viewModel.isFavorite ? .yellow : AppColors.textPrimary)
            }
        } header: {
            Text("Additional Filters")
        }
    }
}

// MARK: - Supporting Views

struct FilterToggleRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
                
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textTertiary)
            }
        }
    }
}

struct TagCloudView: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<UUID>
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: AppSpacing.sm) {
            ForEach(tags) { tag in
                Button(action: {
                    if selectedTags.contains(tag.id) {
                        selectedTags.remove(tag.id)
                    } else {
                        selectedTags.insert(tag.id)
                    }
                }) {
                    HStack(spacing: AppSpacing.xxs) {
                        Text(tag.name)
                            .textStyle(.labelSmall)
                            .foregroundStyle(selectedTags.contains(tag.id) ? .white : AppColors.textPrimary)
                        
                        if selectedTags.contains(tag.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                    .appPadding(.horizontal, AppSpacing.sm)
                    .appPadding(.vertical, AppSpacing.xxs)
                    .background(selectedTags.contains(tag.id) ? Color.named(tag.color) : AppColors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTags.contains(tag.id) ? Color.clear : AppColors.border, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Range Slider

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.surface)
                    .frame(height: 4)
                
                // Selected range
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.primary)
                    .frame(
                        width: CGFloat((maxValue - minValue) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                        height: 4
                    )
                    .offset(x: CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                
                // Min handle
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((minValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                minValue = min(max(bounds.lowerBound, newValue), maxValue - 10)
                            }
                    )
                
                // Max handle
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((maxValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                maxValue = max(min(bounds.upperBound, newValue), minValue + 10)
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}
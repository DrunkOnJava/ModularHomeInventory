import XCTest
import SnapshotTesting
import SwiftUI

final class ResponsiveLayoutTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testAdaptiveGridLayoutView() {
        let view = AdaptiveGridLayoutView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
    }
    
    func testCompactWideLayoutView() {
        let view = CompactWideLayoutView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testStackedNavigationView() {
        let view = StackedNavigationView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testSplitViewLayoutView() {
        let view = SplitViewLayoutView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testDynamicFormLayoutView() {
        let view = DynamicFormLayoutView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
}

// MARK: - Helper Views

struct AdaptiveGridLayoutView: View {
    let items = Array(0..<20).map { "Item \($0 + 1)" }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                    ForEach(items.indices, id: \.self) { index in
                        GridItemCard(
                            title: items[index],
                            price: "$\(50 + index * 25)",
                            category: categories[index % categories.count],
                            isNew: index < 3
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Adaptive Grid")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)]
    }
    
    let categories = ["Electronics", "Furniture", "Clothing", "Books", "Tools"]
}

struct GridItemCard: View {
    let title: String
    let price: String
    let category: String
    let isNew: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                if isNew {
                    VStack {
                        HStack {
                            Spacer()
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    var categoryIcon: String {
        switch category {
        case "Electronics": return "laptopcomputer"
        case "Furniture": return "bed.double"
        case "Clothing": return "tshirt"
        case "Books": return "book"
        case "Tools": return "wrench"
        default: return "cube"
        }
    }
}

struct CompactWideLayoutView: View {
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // Wide layout (iPad)
                WideLayoutContent()
            } else {
                // Compact layout (iPhone)
                CompactLayoutContent()
            }
        }
    }
}

struct WideLayoutContent: View {
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 16) {
                    Text("Categories")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        SidebarItem(icon: "house", title: "All Items", count: 234, isSelected: true)
                        SidebarItem(icon: "laptopcomputer", title: "Electronics", count: 45)
                        SidebarItem(icon: "bed.double", title: "Furniture", count: 28)
                        SidebarItem(icon: "tshirt", title: "Clothing", count: 67)
                        SidebarItem(icon: "book", title: "Books", count: 94)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(width: 250)
                .background(Color(.systemGray6))
                
                // Main content
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("All Items")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("234 items • $12,450 total value")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Image(systemName: "plus")
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(22)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "magnifyingglass")
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(22)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Content grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(0..<12) { index in
                                WideItemCard(
                                    title: "Item \(index + 1)",
                                    price: "$\(100 + index * 50)",
                                    category: "Electronics"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CompactLayoutContent: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Horizontal category scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(["All", "Electronics", "Furniture", "Clothing", "Books"], id: \.self) { category in
                            CategoryChip(title: category, isSelected: category == "All")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                
                // Vertical item list
                List {
                    ForEach(0..<10) { index in
                        CompactItemRow(
                            title: "Item \(index + 1)",
                            subtitle: "Electronics • Added 2 days ago",
                            price: "$\(100 + index * 50)"
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let count: Int
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.clear)
        .cornerRadius(12)
    }
}

struct WideItemCard: View {
    let title: String
    let price: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .aspectRatio(4/3, contentMode: .fit)
                .overlay(
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct CompactItemRow: View {
    let title: String
    let subtitle: String
    let price: String
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "laptopcomputer")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(price)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct StackedNavigationView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Quick Actions") {
                    NavigationRow(icon: "plus", title: "Add Item", subtitle: "Add new item to inventory")
                    NavigationRow(icon: "camera", title: "Scan Barcode", subtitle: "Quick add with barcode")
                    NavigationRow(icon: "square.and.arrow.up", title: "Export Data", subtitle: "Export your inventory")
                }
                
                Section("Categories") {
                    NavigationRow(icon: "laptopcomputer", title: "Electronics", subtitle: "45 items")
                    NavigationRow(icon: "bed.double", title: "Furniture", subtitle: "28 items")
                    NavigationRow(icon: "tshirt", title: "Clothing", subtitle: "67 items")
                    NavigationRow(icon: "book", title: "Books", subtitle: "94 items")
                }
                
                Section("Tools") {
                    NavigationRow(icon: "chart.bar", title: "Analytics", subtitle: "View statistics")
                    NavigationRow(icon: "gear", title: "Settings", subtitle: "App preferences")
                    NavigationRow(icon: "questionmark.circle", title: "Help", subtitle: "Get support")
                }
            }
            .navigationTitle("Home Inventory")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SplitViewLayoutView: View {
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 800 {
                // Split view for large screens
                HStack(spacing: 0) {
                    // Master view
                    MasterListView()
                        .frame(width: 320)
                        .background(Color(.systemGray6))
                    
                    // Detail view
                    DetailContentView()
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Single view for smaller screens
                NavigationView {
                    MasterListView()
                        .navigationTitle("Items")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

struct MasterListView: View {
    var body: some View {
        List {
            ForEach(0..<15) { index in
                MasterListRow(
                    title: "Item \(index + 1)",
                    category: "Electronics",
                    price: "$\(100 + index * 75)",
                    isSelected: index == 2
                )
            }
        }
        .listStyle(SidebarListStyle())
    }
}

struct MasterListRow: View {
    let title: String
    let category: String
    let price: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "laptopcomputer")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct DetailContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MacBook Pro 16-inch")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Electronics")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Added Oct 15, 2024")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$2,499")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Excellent condition")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            // Image
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .aspectRatio(16/10, contentMode: .fit)
                .overlay(
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                )
                .padding(.horizontal, 32)
            
            // Details
            VStack(spacing: 16) {
                DetailSection(title: "Description", content: "MacBook Pro with M1 Pro chip, 16GB RAM, 512GB SSD. Used for work and personal projects.")
                DetailSection(title: "Purchase Info", content: "Purchased from Apple Store on January 15, 2024 for $2,499")
                DetailSection(title: "Warranty", content: "AppleCare+ until January 15, 2027")
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DynamicFormLayoutView: View {
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                Form {
                    if geometry.size.width > 600 {
                        // Wide form layout
                        WideFormContent()
                    } else {
                        // Compact form layout
                        CompactFormContent()
                    }
                }
                .navigationTitle("Add Item")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

struct WideFormContent: View {
    var body: some View {
        Section("Basic Information") {
            HStack {
                VStack {
                    TextField("Item Name", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Category", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack {
                    TextField("Price", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Brand", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        
        Section("Details") {
            HStack(alignment: .top) {
                VStack {
                    TextField("Serial Number", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Model", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack {
                    TextField("Purchase Date", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Warranty Until", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        
        Section("Description") {
            HStack(alignment: .top) {
                VStack {
                    Text("Notes")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("Additional notes...", text: .constant(""), axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: 100)
                }
                
                VStack {
                    Text("Condition")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("Condition", selection: .constant(0)) {
                        Text("Excellent").tag(0)
                        Text("Good").tag(1)
                        Text("Fair").tag(2)
                        Text("Poor").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
}

struct CompactFormContent: View {
    var body: some View {
        Section("Basic Information") {
            TextField("Item Name", text: .constant(""))
            TextField("Category", text: .constant(""))
            TextField("Price", text: .constant(""))
            TextField("Brand", text: .constant(""))
        }
        
        Section("Details") {
            TextField("Serial Number", text: .constant(""))
            TextField("Model", text: .constant(""))
            TextField("Purchase Date", text: .constant(""))
            TextField("Warranty Until", text: .constant(""))
        }
        
        Section("Condition") {
            Picker("Condition", selection: .constant(0)) {
                Text("Excellent").tag(0)
                Text("Good").tag(1)
                Text("Fair").tag(2)
                Text("Poor").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        
        Section("Description") {
            TextField("Additional notes...", text: .constant(""), axis: .vertical)
                .frame(minHeight: 80)
        }
    }
}
import XCTest
import SnapshotTesting
import SwiftUI

final class ItemsDetailedSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testStorageUnitsView() {
        let view = createStorageUnitsView()
        let hostingController = UIHostingController(rootView: view)
        
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testStorageUnitsViewDarkMode() {
        let view = createStorageUnitsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testStorageUnitsViewEmptyState() {
        let view = createStorageUnitsEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testCollectionsView() {
        let view = createCollectionsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testCollectionsViewDarkMode() {
        let view = createCollectionsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testCollectionsViewEmptyState() {
        let view = createCollectionsEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testWarrantyView() {
        let view = createWarrantyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testWarrantyViewDarkMode() {
        let view = createWarrantyView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testWarrantyViewEmptyState() {
        let view = createWarrantyEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testBudgetView() {
        let view = createBudgetView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBudgetViewDarkMode() {
        let view = createBudgetView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testBudgetViewEmptyState() {
        let view = createBudgetEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testAnalyticsView() {
        let view = createAnalyticsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testAnalyticsViewDarkMode() {
        let view = createAnalyticsView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testAnalyticsViewEmptyState() {
        let view = createAnalyticsEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testInsuranceView() {
        let view = createInsuranceView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testInsuranceViewDarkMode() {
        let view = createInsuranceView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testInsuranceViewEmptyState() {
        let view = createInsuranceEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    
    // MARK: - Combined View Test
    
    func testAllViewsCombined() {
        let view = createCombinedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    // MARK: - View Creation Helpers
    
    private func createStorageUnitsView() -> some View {
        NavigationView {
            List {
                ForEach(["Garage", "Attic", "Basement", "Storage Unit A"], id: \.self) { unit in
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.brown)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text(unit)
                                .font(.headline)
                            Text("15 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("75%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Storage Units")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createStorageUnitsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "archivebox")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Storage Units")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Organize your items by creating storage units")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: {}) {
                    Label("Add Storage Unit", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Storage Units")
        }
    }

    private func createCollectionsView() -> some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(["Electronics", "Jewelry", "Books", "Art", "Tools", "Sports"], id: \.self) { collection in
                        VStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.indigo.opacity(0.2))
                                .frame(height: 120)
                                .overlay(
                                    VStack {
                                        Image(systemName: self.collectionIcon(for: collection))
                                            .font(.largeTitle)
                                            .foregroundColor(.indigo)
                                        Text(collection)
                                            .font(.headline)
                                            .padding(.top, 4)
                                    }
                                )
                            Text("8 items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createCollectionsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "folder")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Collections")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Group your items into collections")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Collection", systemImage: "plus")
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Collections")
        }
    }
    
    private func collectionIcon(for collection: String) -> String {
        switch collection {
        case "Electronics": return "tv"
        case "Jewelry": return "sparkles"
        case "Books": return "books.vertical"
        case "Art": return "paintpalette"
        case "Tools": return "wrench"
        case "Sports": return "sportscourt"
        default: return "folder"
        }
    }

    private func createWarrantyView() -> some View {
        NavigationView {
            List {
                Section("Expiring Soon") {
                    ForEach(["MacBook Pro", "iPhone 15 Pro", "AirPods Pro"], id: \.self) { item in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text(item)
                                    .font(.headline)
                                Text("Expires in 15 days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Extended")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Active Warranties") {
                    ForEach(["Smart TV", "Refrigerator", "Washing Machine"], id: \.self) { item in
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(item)
                                    .font(.headline)
                                Text("350 days remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Warranties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                    }
                }
            }
        }
    }
    
    private func createWarrantyEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "shield")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Warranties")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Track your product warranties here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Warranties")
        }
    }

    private func createBudgetView() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Overview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Budget")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("$2,000")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("of $3,000")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            CircularProgressView(progress: 0.65)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Category")
                            .font(.headline)
                        ForEach(["Electronics", "Home & Garden", "Clothing", "Sports"], id: \.self) { category in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(self.categoryColor(for: category))
                                    .frame(width: 4)
                                VStack(alignment: .leading) {
                                    Text(category)
                                        .font(.subheadline)
                                    Text("$450")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                ProgressView(value: 0.6)
                                    .frame(width: 100)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Budget")
        }
    }
    
    private func createBudgetEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Budget Set")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Create a budget to track your spending")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Create Budget", systemImage: "plus")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Budget")
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Electronics": return .blue
        case "Home & Garden": return .green
        case "Clothing": return .purple
        case "Sports": return .orange
        default: return .gray
        }
    }

    private func createAnalyticsView() -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Value Card
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Inventory Value")
                                .font(.headline)
                            Text("$20,000")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            HStack {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("+10%")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("vs last month")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Category Distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Value by Category")
                            .font(.headline)
                        // Mock chart placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.pie.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                    Text("Category Distribution")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
    
    private func createAnalyticsEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add items to see analytics")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Analytics")
        }
    }

    private func createInsuranceView() -> some View {
        NavigationView {
            List {
                Section("Active Policies") {
                    ForEach(["Home Insurance", "Electronics Protection", "Jewelry Coverage"], id: \.self) { policy in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.green)
                                Text(policy)
                                    .font(.headline)
                                Spacer()
                                Text("Active")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            HStack {
                                Label("30 items", systemImage: "cube.box")
                                Spacer()
                                Text("$125/mo")
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Coverage Summary") {
                    HStack {
                        Text("Total Coverage")
                        Spacer()
                        Text("$75,000")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Total Premium")
                        Spacer()
                        Text("$350/mo")
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Insurance")
        }
    }
    
    private func createInsuranceEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "shield")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Insurance Policies")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Track your insurance coverage")
                    .foregroundColor(.secondary)
                Button(action: {}) {
                    Label("Add Policy", systemImage: "plus")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Insurance")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createStorageUnitsView()
                .tabItem {
                    Label("StorageUnits", systemImage: "archivebox")
                }
            createCollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
            createWarrantyView()
                .tabItem {
                    Label("Warranty", systemImage: "shield.checkered")
                }
            createBudgetView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign.circle")
                }
            createAnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
            createInsuranceView()
                .tabItem {
                    Label("Insurance", systemImage: "shield.fill")
                }
        }
    }
}

// Helper view for Budget dashboard
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, lineWidth: 10)
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.headline)
        }
    }
}

import XCTest
import SnapshotTesting
import SwiftUI

final class SearchSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testNaturalLanguageView() {
        let view = createNaturalLanguageView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testNaturalLanguageViewDarkMode() {
        let view = createNaturalLanguageView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testNaturalLanguageViewEmptyState() {
        let view = createNaturalLanguageEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testImageSearchView() {
        let view = createImageSearchView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testImageSearchViewDarkMode() {
        let view = createImageSearchView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testImageSearchViewEmptyState() {
        let view = createImageSearchEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testBarcodeSearchView() {
        let view = createBarcodeSearchView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testBarcodeSearchViewDarkMode() {
        let view = createBarcodeSearchView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testBarcodeSearchViewEmptyState() {
        let view = createBarcodeSearchEmptyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }

    func testSavedSearchesView() {
        let view = createSavedSearchesView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testSavedSearchesViewDarkMode() {
        let view = createSavedSearchesView()
            .environment(\.colorScheme, .dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testSavedSearchesViewEmptyState() {
        let view = createSavedSearchesEmptyView()
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
    
    private func createNaturalLanguageView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Ask anything about your items...", text: .constant(""))
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Example Queries
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try asking:")
                        .font(.headline)
                    ForEach([
                        "Show me all electronics bought this year",
                        "What items are worth more than $500?",
                        "Find warranties expiring soon",
                        "Items I haven't used in 6 months"
                    ], id: \.self) { query in
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.purple)
                                Text(query)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Smart Search")
        }
    }
    
    private func createNaturalLanguageEmptyView() -> some View {
        createNaturalLanguageView()
    }

    private func createImageSearchView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                // Camera Button
                Button(action: {}) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Take Photo")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Upload Button
                Button(action: {}) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Choose from Library")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Image Search")
        }
    }
    
    private func createImageSearchEmptyView() -> some View {
        createImageSearchView()
    }

    private func createBarcodeSearchView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "barcode")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text("BarcodeSearch")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("BarcodeSearch")
        }
    }
    
    private func createBarcodeSearchEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "barcode")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("BarcodeSearch content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("BarcodeSearch")
        }
    }

    private func createSavedSearchesView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                Text("SavedSearches")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("This view is under development")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("SavedSearches")
        }
    }
    
    private func createSavedSearchesEmptyView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("SavedSearches content will appear here")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("SavedSearches")
        }
    }

    
    private func createCombinedView() -> some View {
        TabView {
            createNaturalLanguageView()
                .tabItem {
                    Label("NaturalLanguage", systemImage: "text.magnifyingglass")
                }
            createImageSearchView()
                .tabItem {
                    Label("ImageSearch", systemImage: "photo.fill")
                }
            createBarcodeSearchView()
                .tabItem {
                    Label("BarcodeSearch", systemImage: "barcode")
                }
            createSavedSearchesView()
                .tabItem {
                    Label("SavedSearches", systemImage: "bookmark.fill")
                }
        }
    }
}

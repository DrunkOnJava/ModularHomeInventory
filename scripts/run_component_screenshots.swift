import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Mock types needed for the screenshot tests
struct Item: Identifiable {
    let id = UUID()
    let name: String
    let brandName: String?
    let purchasePrice: Double
    let quantity: Int
    let warrantyEndDate: Date?
    let notes: String?
    let images: [Data] = []
    let barcode: String?
    
    init(name: String, brandName: String? = nil, purchasePrice: Double = 0, quantity: Int = 1, warrantyEndDate: Date? = nil, notes: String? = nil, barcode: String? = nil) {
        self.name = name
        self.brandName = brandName
        self.purchasePrice = purchasePrice
        self.quantity = quantity
        self.warrantyEndDate = warrantyEndDate
        self.notes = notes
        self.barcode = barcode
    }
}

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

// Simple view components for testing
struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    if let brand = item.brandName {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("$\(item.purchasePrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            HStack {
                Label("\(item.quantity)", systemImage: "number.square")
                    .font(.caption)
                
                if let warranty = item.warrantyEndDate {
                    Label(warranty.formatted(date: .abbreviated, time: .omitted), systemImage: "shield")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Screenshot capture function
@MainActor
func captureScreenshot<Content: View>(of view: Content, named name: String) throws {
    let outputDir = "\(NSHomeDirectory())/Documents/ComponentScreenshots"
    try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0 // High resolution
    
    guard let image = renderer.cgImage else {
        throw NSError(domain: "Screenshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render image"])
    }
    
    let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    
    print("✅ Saved: \(name).png")
}

// Main screenshot generation
@main
@MainActor
struct ScreenshotGenerator {
    static func main() async throws {
        print("📸 Generating Component Screenshots...")
        print("=====================================")
        
        // Generate mock data
        let mockItem = Item(
            name: "MacBook Pro 16\"",
            brandName: "Apple",
            purchasePrice: 2499.99,
            quantity: 1,
            warrantyEndDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            notes: "Work laptop with AppleCare+",
            barcode: "123456789"
        )
        
        // Item Card
        try captureScreenshot(
            of: ItemCard(item: mockItem)
                .frame(width: 350)
                .padding()
                .background(Color(.systemGroupedBackground)),
            named: "ItemCard"
        )
        
        // Empty State
        try captureScreenshot(
            of: EmptyStateView(
                title: "No Items Yet",
                message: "Add your first item to start organizing your belongings",
                icon: "archivebox"
            ),
            named: "EmptyState"
        )
        
        // Multiple Items
        let items = [
            Item(name: "iPhone 15 Pro", brandName: "Apple", purchasePrice: 999, quantity: 1),
            Item(name: "AirPods Pro", brandName: "Apple", purchasePrice: 249, quantity: 1),
            Item(name: "Magic Keyboard", brandName: "Apple", purchasePrice: 149, quantity: 1)
        ]
        
        try captureScreenshot(
            of: VStack(spacing: 10) {
                ForEach(items) { item in
                    ItemCard(item: item)
                }
            }
            .frame(width: 350)
            .padding()
            .background(Color(.systemGroupedBackground)),
            named: "ItemsList"
        )
        
        // Statistics Card
        let statsCard = VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Inventory Stats")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Total Items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("127")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$15,432")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        
        try captureScreenshot(
            of: statsCard
                .frame(width: 350)
                .padding()
                .background(Color(.systemGroupedBackground)),
            named: "StatsCard"
        )
        
        print("\n✅ All component screenshots generated!")
        print("📁 Output: ~/Documents/ComponentScreenshots/")
    }
}
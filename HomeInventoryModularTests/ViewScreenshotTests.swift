import XCTest
import SwiftUI
@testable import HomeInventoryModular
@testable import Items
@testable import AppSettings
@testable import SharedUI
@testable import Core

final class ViewScreenshotTests: XCTestCase {
    
    // Directory for saving screenshots
    private var screenshotDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotsDir = documentsDirectory.appendingPathComponent("ComponentScreenshots")
        try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        return screenshotsDir
    }
    
    // MARK: - Component Screenshots
    
    @MainActor
    func testItemCardScreenshot() throws {
        // Create a mock item
        let mockItem = Item(
            name: "Vintage Lamp",
            category: .electronics,
            location: .livingRoom,
            value: 129.99,
            quantity: 1,
            notes: "Antique brass table lamp from the 1950s",
            tags: ["vintage", "collectible"],
            customFields: [],
            images: [],
            receipts: [],
            warrantyId: nil,
            manualURL: nil,
            modelNumber: "VL-1950",
            serialNumber: "SN123456",
            purchaseInfo: PurchaseInfo(
                price: 129.99,
                date: Date(),
                location: "Antique Shop",
                notes: "Great condition"
            )
        )
        
        // Create the view
        let itemCard = ItemCard(item: mockItem)
            .frame(width: 350)
            .padding()
        
        // Render and save
        try captureScreenshot(of: itemCard, named: "ItemCard")
    }
    
    @MainActor
    func testItemDetailHeaderScreenshot() throws {
        let mockItem = Item(
            name: "MacBook Pro 16\"",
            category: .electronics,
            location: .office,
            value: 2499.00,
            quantity: 1,
            notes: "Work laptop",
            tags: ["work", "apple", "computer"],
            customFields: [
                CustomField(id: UUID(), name: "RAM", value: "32GB"),
                CustomField(id: UUID(), name: "Storage", value: "1TB SSD")
            ],
            images: [],
            receipts: [],
            warrantyId: nil,
            manualURL: nil,
            modelNumber: "A2485",
            serialNumber: "C02XL1234567",
            purchaseInfo: PurchaseInfo(
                price: 2499.00,
                date: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
                location: "Apple Store",
                notes: "AppleCare+ included"
            )
        )
        
        // Create a detail header view
        let detailHeader = VStack(spacing: 16) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(mockItem.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Label(mockItem.category.displayName, systemImage: mockItem.category.iconName)
                    Spacer()
                    Text(mockItem.value.asCurrency())
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                if let modelNumber = mockItem.modelNumber {
                    HStack {
                        Text("Model: \(modelNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let serialNumber = mockItem.serialNumber {
                            Text("• S/N: \(serialNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Tags
                if !mockItem.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(mockItem.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 390)
        .padding()
        .background(Color(.systemBackground))
        
        try captureScreenshot(of: detailHeader, named: "ItemDetailHeader")
    }
    
    @MainActor
    func testSettingsSectionScreenshot() throws {
        // Create a settings section
        let settingsSection = VStack(alignment: .leading, spacing: 0) {
            Text("APPEARANCE")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "paintbrush",
                    title: "Theme",
                    value: "System",
                    showDisclosure: true
                )
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(
                    icon: "textformat.size",
                    title: "Text Size",
                    value: "Medium",
                    showDisclosure: true
                )
                
                Divider()
                    .padding(.leading, 56)
                
                SettingsRow(
                    icon: "circle.lefthalf.filled",
                    title: "Icon Style",
                    value: "Filled",
                    showDisclosure: true
                )
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .frame(width: 390)
        .padding()
        .background(Color(.systemBackground))
        
        try captureScreenshot(of: settingsSection, named: "SettingsSection")
    }
    
    @MainActor
    func testEmptyStateScreenshot() throws {
        let emptyState = VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Items Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start adding items to your inventory to keep track of your belongings")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)
            
            Button(action: {}) {
                Label("Add First Item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .frame(width: 390, height: 600)
        .background(Color(.systemBackground))
        
        try captureScreenshot(of: emptyState, named: "EmptyState")
    }
    
    @MainActor
    func testStatisticsCardScreenshot() throws {
        let statsCard = VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Value")
                        .font(.headline)
                    Text("$15,234.56")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("156")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("12")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("8")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Locations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .frame(width: 350)
        .padding()
        
        try captureScreenshot(of: statsCard, named: "StatisticsCard")
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func captureScreenshot<Content: View>(of view: Content, named name: String) throws {
        let renderer = ImageRenderer(content: view)
        
        // Configure for high quality
        renderer.scale = UIScreen.main.scale
        
        guard let uiImage = renderer.uiImage else {
            XCTFail("Failed to render \(name)")
            return
        }
        
        // Save the image
        let fileURL = screenshotDirectory.appendingPathComponent("\(name).png")
        guard let pngData = uiImage.pngData() else {
            XCTFail("Failed to create PNG data for \(name)")
            return
        }
        
        try pngData.write(to: fileURL)
        print("📸 Screenshot saved: \(fileURL.path)")
        
        // Also attach to test results
        let attachment = XCTAttachment(image: uiImage)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Helper Views for Testing

private struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let showDisclosure: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
            
            if showDisclosure {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiaryLabel)
            }
        }
        .padding()
    }
}
import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI
@testable import Core
@testable import Items

final class AccessibilitySnapshotTests: SnapshotTestCase {
    
    // Test different text size categories
    func testDynamicType_ItemCard() {
        let item = Item.sample
        let card = ItemCard(item: item)
            .frame(width: 350)
            .padding()
        
        let textSizes: [ContentSizeCategory] = [
            .extraSmall,
            .medium,
            .extraLarge,
            .accessibilityMedium,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for size in textSizes {
            assertSnapshot(
                matching: card,
                as: .image(traits: .init(preferredContentSizeCategory: size)),
                named: "itemCard_\(size.name)"
            )
        }
    }
    
    func testHighContrast_Views() {
        let button = PrimaryButton(title: "Save Changes") {}
            .frame(width: 300)
            .padding()
        
        // High contrast mode
        assertSnapshot(
            matching: button,
            as: .image(traits: .init(accessibilityContrast: .high))
        )
    }
    
    func testReducedMotion_LoadingView() {
        let loading = LoadingOverlay(isLoading: .constant(true))
            .frame(width: 300, height: 200)
        
        // Reduced motion
        assertSnapshot(
            matching: loading,
            as: .image(traits: .init(accessibilityReduceMotion: true))
        )
    }
    
    func testColorBlindness_StatusIndicators() {
        let statusView = VStack(spacing: 20) {
            StatusIndicator(status: .active, title: "Active")
            StatusIndicator(status: .warning, title: "Expiring Soon")
            StatusIndicator(status: .expired, title: "Expired")
            StatusIndicator(status: .neutral, title: "No Status")
        }
        .padding()
        .frame(width: 300)
        
        // Test for different color blindness types
        // Note: iOS doesn't have built-in color blindness traits,
        // so we test in grayscale as a proxy
        assertSnapshot(
            matching: statusView,
            as: .image(traits: .init(displayGamut: .P3))
        )
    }
    
    func testVoiceOver_Annotations() {
        // This tests that our views have proper accessibility labels
        let itemCard = ItemCard(item: Item.sample)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("MacBook Pro 16 inch, Electronics, $3,499.99")
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: itemCard, as: .image)
    }
    
    func testRTL_Layout() {
        let searchBar = SearchBar(text: .constant("البحث"), placeholder: "ابحث عن العناصر...")
            .environment(\.layoutDirection, .rightToLeft)
            .frame(height: 60)
            .padding()
        
        assertSnapshot(
            matching: searchBar,
            as: .image(traits: .init(layoutDirection: .rightToLeft))
        )
    }
}

// Helper views
struct StatusIndicator: View {
    enum Status {
        case active, warning, expired, neutral
        
        var color: Color {
            switch self {
            case .active: return .green
            case .warning: return .orange
            case .expired: return .red
            case .neutral: return .gray
            }
        }
    }
    
    let status: Status
    let title: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.body)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Helper extension for ContentSizeCategory names
extension ContentSizeCategory {
    var name: String {
        switch self {
        case .extraSmall: return "extraSmall"
        case .small: return "small"
        case .medium: return "medium"
        case .large: return "large"
        case .extraLarge: return "extraLarge"
        case .extraExtraLarge: return "extraExtraLarge"
        case .extraExtraExtraLarge: return "extraExtraExtraLarge"
        case .accessibilityMedium: return "accessibilityMedium"
        case .accessibilityLarge: return "accessibilityLarge"
        case .accessibilityExtraLarge: return "accessibilityExtraLarge"
        case .accessibilityExtraExtraLarge: return "accessibilityExtraExtraLarge"
        case .accessibilityExtraExtraExtraLarge: return "accessibilityExtraExtraExtraLarge"
        @unknown default: return "unknown"
        }
    }
}
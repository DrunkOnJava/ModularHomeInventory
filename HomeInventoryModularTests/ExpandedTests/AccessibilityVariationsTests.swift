import XCTest
import SnapshotTesting
import SwiftUI

final class AccessibilityVariationsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testVoiceOverOptimizedView() {
        let view = VoiceOverOptimizedView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testLargeTextSizesView() {
        let view = LargeTextSizesView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testHighContrastView() {
        let view = HighContrastView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testReducedMotionView() {
        let view = ReducedMotionView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testColorBlindFriendlyView() {
        let view = ColorBlindFriendlyView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
}

// MARK: - Helper Views

struct VoiceOverOptimizedView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with clear hierarchy
                    VStack(spacing: 12) {
                        Text("My Items")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("234 items • Total value $12,450")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("234 items with total value of 12,450 dollars")
                    }
                    .padding(.horizontal)
                    
                    // Action buttons with clear labels
                    HStack(spacing: 16) {
                        AccessibleActionButton(
                            icon: "plus",
                            title: "Add Item",
                            accessibilityHint: "Add a new item to your inventory"
                        )
                        
                        AccessibleActionButton(
                            icon: "camera",
                            title: "Scan",
                            accessibilityHint: "Scan barcode or take photo to add item"
                        )
                        
                        AccessibleActionButton(
                            icon: "magnifyingglass",
                            title: "Search",
                            accessibilityHint: "Search through your items"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Item list with comprehensive accessibility
                    VStack(spacing: 16) {
                        ForEach(0..<5) { index in
                            AccessibleItemRow(
                                title: "MacBook Pro \(index + 1)",
                                category: "Electronics",
                                value: "$\(2000 + index * 100)",
                                condition: index % 2 == 0 ? "Excellent" : "Good",
                                addedDate: "Added \(index + 1) day\(index == 0 ? "" : "s") ago"
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
        .accessibilityElement(children: .contain)
    }
}

struct AccessibleActionButton: View {
    let icon: String
    let title: String
    let accessibilityHint: String
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
}

struct AccessibleItemRow: View {
    let title: String
    let category: String
    let value: String
    let condition: String
    let addedDate: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Item image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.gray)
                )
                .accessibilityLabel("Item image")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(condition)
                        .font(.caption)
                        .foregroundColor(condition == "Excellent" ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (condition == "Excellent" ? Color.green : Color.orange)
                                .opacity(0.1)
                        )
                        .cornerRadius(8)
                }
                
                Text(addedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(category), valued at \(value), condition is \(condition), \(addedDate)")
        .accessibilityHint("Double tap to view item details")
        .accessibilityAddTraits(.isButton)
    }
}

struct LargeTextSizesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Accessibility Text Sizes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Dynamic type examples
                VStack(alignment: .leading, spacing: 16) {
                    TextSizeExample(
                        style: .largeTitle,
                        label: "Large Title",
                        content: "Home Inventory"
                    )
                    
                    TextSizeExample(
                        style: .title,
                        label: "Title",
                        content: "My Collections"
                    )
                    
                    TextSizeExample(
                        style: .headline,
                        label: "Headline",
                        content: "MacBook Pro 16-inch"
                    )
                    
                    TextSizeExample(
                        style: .body,
                        label: "Body",
                        content: "This laptop is used for work and personal projects. It's in excellent condition with minimal wear."
                    )
                    
                    TextSizeExample(
                        style: .callout,
                        label: "Callout",
                        content: "Value: $2,499 • Purchased: Jan 2024"
                    )
                    
                    TextSizeExample(
                        style: .caption,
                        label: "Caption",
                        content: "Serial: ABC123DEF456"
                    )
                }
                .padding(.horizontal)
                
                // Button with large text
                Button(action: {}) {
                    Text("Add New Item")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                
                // List item with large text
                VStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        LargeTextItemRow(
                            title: "Camera Equipment \(index + 1)",
                            subtitle: "Photography • $\(500 + index * 200)",
                            description: "Professional camera equipment used for photography projects and personal use."
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

struct TextSizeExample: View {
    let style: Font.TextStyle
    let label: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(content)
                .font(.custom("", size: 17, relativeTo: style))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LargeTextItemRow: View {
    let title: String
    let subtitle: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("", size: 20, relativeTo: .headline))
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.custom("", size: 16, relativeTo: .subheadline))
                .foregroundColor(.blue)
            
            Text(description)
                .font(.custom("", size: 15, relativeTo: .body))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct HighContrastView: View {
    var body: some View {
        VStack(spacing: 0) {
            // High contrast header
            VStack(spacing: 16) {
                Text("High Contrast Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Enhanced visibility for better accessibility")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.black)
            
            ScrollView {
                VStack(spacing: 24) {
                    // High contrast buttons
                    VStack(spacing: 16) {
                        HighContrastButton(
                            title: "Add Item",
                            icon: "plus",
                            style: .primary
                        )
                        
                        HighContrastButton(
                            title: "Search Items",
                            icon: "magnifyingglass",
                            style: .secondary
                        )
                        
                        HighContrastButton(
                            title: "Export Data",
                            icon: "square.and.arrow.up",
                            style: .outline
                        )
                    }
                    .padding(.horizontal)
                    
                    // High contrast item list
                    VStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            HighContrastItemRow(
                                title: "Item \(index + 1)",
                                category: "Category",
                                value: "$\(100 * (index + 1))",
                                isEven: index % 2 == 0
                            )
                        }
                    }
                    
                    // High contrast status indicators
                    VStack(spacing: 16) {
                        Text("Status Indicators")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HighContrastStatus(title: "Sync Complete", status: .success)
                            HighContrastStatus(title: "Warning: Low Storage", status: .warning)
                            HighContrastStatus(title: "Error: Connection Failed", status: .error)
                            HighContrastStatus(title: "Processing...", status: .info)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
        }
    }
}

struct HighContrastButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, outline
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary: return Color.black
        case .secondary: return Color(.systemGray2)
        case .outline: return Color.clear
        }
    }
    
    var foregroundColor: Color {
        switch style {
        case .primary: return Color.white
        case .secondary: return Color.black
        case .outline: return Color.black
        }
    }
    
    var borderColor: Color {
        style == .outline ? Color.black : Color.clear
    }
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
            .cornerRadius(8)
        }
    }
}

struct HighContrastItemRow: View {
    let title: String
    let category: String
    let value: String
    let isEven: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // High contrast icon
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.black, lineWidth: 2)
                )
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(category)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding()
        .background(isEven ? Color.white : Color(.systemGray6))
        .overlay(
            Rectangle()
                .strokeBorder(Color.black, lineWidth: 1)
        )
    }
}

struct HighContrastStatus: View {
    let title: String
    let status: StatusType
    
    enum StatusType {
        case success, warning, error, info
    }
    
    var statusColor: Color {
        switch status {
        case .success: return .black
        case .warning: return .black
        case .error: return .white
        case .info: return .white
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case .success: return .white
        case .warning: return .yellow
        case .error: return .black
        case .info: return .blue
        }
    }
    
    var statusIcon: String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .foregroundColor(statusColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.black, lineWidth: 2)
        )
        .cornerRadius(8)
    }
}

struct ReducedMotionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Reduced Motion Interface")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Static, non-animated interface elements")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Static loading indicators
            VStack(spacing: 20) {
                Text("Loading States (No Animation)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    StaticLoadingIndicator(title: "Loading items...", progress: 0.6)
                    StaticLoadingIndicator(title: "Syncing data...", progress: 0.3)
                    StaticLoadingIndicator(title: "Uploading photos...", progress: 0.8)
                }
                .padding(.horizontal)
            }
            
            // Static state indicators
            VStack(spacing: 20) {
                Text("Status Indicators (Static)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    StaticStatusRow(icon: "checkmark.circle", title: "Sync Complete", color: .green)
                    StaticStatusRow(icon: "exclamationmark.triangle", title: "Warning", color: .orange)
                    StaticStatusRow(icon: "info.circle", title: "Information", color: .blue)
                    StaticStatusRow(icon: "xmark.circle", title: "Error", color: .red)
                }
                .padding(.horizontal)
            }
            
            // Static interaction feedback
            VStack(spacing: 20) {
                Text("Interaction Feedback")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    StaticButton(title: "Add Item", isSelected: false)
                    StaticButton(title: "Selected Item", isSelected: true)
                    StaticButton(title: "Disabled Item", isSelected: false, isDisabled: true)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

struct StaticLoadingIndicator: View {
    let title: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StaticStatusRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            // Static timestamp instead of "time ago"
            Text("2:45 PM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StaticButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    
    init(title: String, isSelected: Bool, isDisabled: Bool = false) {
        self.title = title
        self.isSelected = isSelected
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isDisabled ? Color(.systemGray4) :
                    isSelected ? Color.blue : Color(.systemGray6)
                )
                .foregroundColor(
                    isDisabled ? Color(.systemGray2) :
                    isSelected ? .white : .primary
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? Color.blue.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .disabled(isDisabled)
    }
}

struct ColorBlindFriendlyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Color-Blind Friendly Design")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Status indicators with patterns and icons
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Status with Icons & Patterns")
                            .font(.headline)
                        
                        ColorBlindStatusRow(
                            icon: "checkmark.circle.fill",
                            title: "Backup Complete",
                            pattern: .solid,
                            semanticColor: .success
                        )
                        
                        ColorBlindStatusRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Storage Warning",
                            pattern: .striped,
                            semanticColor: .warning
                        )
                        
                        ColorBlindStatusRow(
                            icon: "xmark.circle.fill",
                            title: "Sync Failed",
                            pattern: .dotted,
                            semanticColor: .error
                        )
                        
                        ColorBlindStatusRow(
                            icon: "info.circle.fill",
                            title: "Update Available",
                            pattern: .dashed,
                            semanticColor: .info
                        )
                    }
                    .padding(.horizontal)
                    
                    // Chart with patterns instead of just colors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Visualization")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            PatternChartBar(
                                label: "Electronics",
                                value: 0.8,
                                pattern: .solid,
                                amount: "$4,200"
                            )
                            
                            PatternChartBar(
                                label: "Furniture",
                                value: 0.6,
                                pattern: .striped,
                                amount: "$3,100"
                            )
                            
                            PatternChartBar(
                                label: "Clothing",
                                value: 0.4,
                                pattern: .dotted,
                                amount: "$2,050"
                            )
                            
                            PatternChartBar(
                                label: "Books",
                                value: 0.3,
                                pattern: .dashed,
                                amount: "$1,540"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Priority levels with shapes and text
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Priority Indicators")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            PriorityRow(
                                shape: .circle,
                                title: "Critical - Warranty Expiring",
                                priority: "HIGH"
                            )
                            
                            PriorityRow(
                                shape: .triangle,
                                title: "Review Insurance Policy",
                                priority: "MEDIUM"
                            )
                            
                            PriorityRow(
                                shape: .square,
                                title: "Update Item Photos",
                                priority: "LOW"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct ColorBlindStatusRow: View {
    let icon: String
    let title: String
    let pattern: PatternType
    let semanticColor: SemanticColor
    
    enum PatternType {
        case solid, striped, dotted, dashed
    }
    
    enum SemanticColor {
        case success, warning, error, info
    }
    
    var color: Color {
        switch semanticColor {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Background pattern
                PatternBackground(pattern: pattern, color: color)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(semanticColor.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

extension ColorBlindStatusRow.SemanticColor {
    var description: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .info: return "Information"
        }
    }
}

struct PatternBackground: View {
    let pattern: ColorBlindStatusRow.PatternType
    let color: Color
    
    var body: some View {
        ZStack {
            color
            
            switch pattern {
            case .solid:
                EmptyView()
            case .striped:
                StripedPattern(color: .white.opacity(0.3))
            case .dotted:
                DottedPattern(color: .white.opacity(0.5))
            case .dashed:
                DashedPattern(color: .white.opacity(0.4))
            }
        }
    }
}

struct StripedPattern: View {
    let color: Color
    
    var body: some View {
        Path { path in
            for i in stride(from: -40, to: 80, by: 8) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i + 40, y: 40))
            }
        }
        .stroke(color, lineWidth: 2)
        .clipped()
    }
}

struct DottedPattern: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4) { col in
                        Circle()
                            .fill(color)
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }
}

struct DashedPattern: View {
    let color: Color
    
    var body: some View {
        Path { path in
            for i in stride(from: 0, to: 40, by: 8) {
                path.move(to: CGPoint(x: 4, y: i))
                path.addLine(to: CGPoint(x: 16, y: i))
                
                path.move(to: CGPoint(x: 24, y: i))
                path.addLine(to: CGPoint(x: 36, y: i))
            }
        }
        .stroke(color, lineWidth: 2)
    }
}

struct PatternChartBar: View {
    let label: String
    let value: Double
    let pattern: ColorBlindStatusRow.PatternType
    let amount: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                    
                    PatternBackground(pattern: pattern, color: .blue)
                        .frame(width: geometry.size.width * value, height: 20)
                        .cornerRadius(4)
                }
            }
            .frame(height: 20)
        }
    }
}

struct PriorityRow: View {
    let shape: ShapeType
    let title: String
    let priority: String
    
    enum ShapeType {
        case circle, triangle, square
    }
    
    var priorityColor: Color {
        switch priority {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        case "LOW": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                priorityColor.opacity(0.2)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                Group {
                    switch shape {
                    case .circle:
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 20, height: 20)
                    case .triangle:
                        TriangleShape()
                            .fill(priorityColor)
                            .frame(width: 20, height: 20)
                    case .square:
                        Rectangle()
                            .fill(priorityColor)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(priority) PRIORITY")
                    .font(.caption)
                    .foregroundColor(priorityColor)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}
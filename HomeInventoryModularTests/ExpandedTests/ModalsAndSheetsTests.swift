import XCTest
import SnapshotTesting
import SwiftUI

final class ModalsAndSheetsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testActionSheet() {
        let view = ActionSheetView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testConfirmationDialog() {
        let view = ConfirmationDialogView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testFilterSheet() {
        let view = FilterSheetView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
    }
    
    func testDetailModal() {
        let view = DetailModalView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct ActionSheetView: View {
    var body: some View {
        ZStack {
            // Background content
            VStack {
                Text("Tap and hold an item for options")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            
            // Action sheet overlay
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(["Share", "Edit", "Duplicate", "Move to Collection"], id: \.self) { action in
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: iconForAction(action))
                                        .frame(width: 20)
                                    Text(action)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .foregroundColor(action == "Delete" ? .red : .primary)
                            }
                            if action != "Move to Collection" {
                                Divider()
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "trash")
                                    .frame(width: 20)
                                Text("Delete")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .foregroundColor(.red)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    
                    Button(action: {}) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
    }
    
    func iconForAction(_ action: String) -> String {
        switch action {
        case "Share": return "square.and.arrow.up"
        case "Edit": return "pencil"
        case "Duplicate": return "doc.on.doc"
        case "Move to Collection": return "folder"
        case "Delete": return "trash"
        default: return "questionmark"
        }
    }
}

struct ConfirmationDialogView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Delete Item?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This action cannot be undone. The item and all associated data will be permanently deleted.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {}) {
                        Text("Delete")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 30)
            .padding(40)
        }
    }
}

struct FilterSheetView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Header
            HStack {
                Text("Filter & Sort")
                    .font(.headline)
                Spacer()
                Button("Reset") {}
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(["All", "Electronics", "Furniture", "Clothing", "Books", "Other"], id: \.self) { category in
                                FilterChip(title: category, isSelected: category == "Electronics")
                            }
                        }
                    }
                    
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price Range")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Min", text: .constant("$0"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("to")
                            TextField("Max", text: .constant("$1000"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Sort By
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sort By")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(["Name (A-Z)", "Name (Z-A)", "Price (Low-High)", "Price (High-Low)", "Recently Added"], id: \.self) { option in
                            HStack {
                                Text(option)
                                Spacer()
                                if option == "Recently Added" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Apply Button
            Button(action: {}) {
                Text("Apply Filters")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 20)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
    }
}

struct DetailModalView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Item Image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MacBook Pro 16\"")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label("Electronics", systemImage: "tv")
                            Spacer()
                            Text("$2,499")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        Text("High-performance laptop for professional use. Features M1 Pro chip, 16GB RAM, and 512GB SSD storage.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Details Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            DetailCard(title: "Purchase Date", value: "Jan 15, 2024", icon: "calendar")
                            DetailCard(title: "Warranty", value: "Until Jan 2025", icon: "shield")
                            DetailCard(title: "Location", value: "Home Office", icon: "location")
                            DetailCard(title: "Condition", value: "Excellent", icon: "star.fill")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {}
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
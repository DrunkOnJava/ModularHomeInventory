#!/usr/bin/env xcrun swift

import UIKit
import SwiftUI

// Mock components since we can't import modules directly
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}

struct LoadingOverlay: View {
    @Binding var isLoading: Bool
    var message: String = "Loading..."
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text(message)
                        .font(.headline)
                }
                .padding(30)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
    }
}

// Helper to generate snapshot
func generateSnapshot(for view: some View, name: String, size: CGSize) {
    let hostingController = UIHostingController(rootView: view)
    hostingController.view.frame = CGRect(origin: .zero, size: size)
    hostingController.view.backgroundColor = .white
    
    // Force layout
    hostingController.view.layoutIfNeeded()
    
    // Create image
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        hostingController.view.layer.render(in: context.cgContext)
    }
    
    // Save image
    if let data = image.pngData() {
        let url = URL(fileURLWithPath: "snapshots/\(name).png")
        try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try! data.write(to: url)
        print("✅ Generated: \(name).png")
    }
}

// Generate snapshots
print("🎨 Generating SwiftUI Component Snapshots...")
print("=" * 40)

// SearchBar snapshots
generateSnapshot(
    for: SearchBar(text: .constant(""), placeholder: "Search items..."),
    name: "SearchBar_Empty",
    size: CGSize(width: 375, height: 60)
)

generateSnapshot(
    for: SearchBar(text: .constant("MacBook Pro"), placeholder: "Search items..."),
    name: "SearchBar_WithText",
    size: CGSize(width: 375, height: 60)
)

// PrimaryButton snapshots
generateSnapshot(
    for: PrimaryButton(title: "Add Item", action: {}),
    name: "PrimaryButton_Default",
    size: CGSize(width: 200, height: 60)
)

generateSnapshot(
    for: PrimaryButton(title: "Saving...", isLoading: true, action: {}),
    name: "PrimaryButton_Loading",
    size: CGSize(width: 200, height: 60)
)

// LoadingOverlay snapshot
generateSnapshot(
    for: LoadingOverlay(isLoading: .constant(true), message: "Processing..."),
    name: "LoadingOverlay",
    size: CGSize(width: 300, height: 300)
)

// Settings List Section
let settingsSection = List {
    Section("Scanner Settings") {
        HStack {
            Image(systemName: "speaker.wave.2")
            Text("Sound Effects")
            Spacer()
            Toggle("", isOn: .constant(true))
                .labelsHidden()
        }
        
        HStack {
            Image(systemName: "iphone.radiowaves.left.and.right")
            Text("Haptic Feedback")
            Spacer()
            Toggle("", isOn: .constant(true))
                .labelsHidden()
        }
        
        HStack {
            Image(systemName: "square.and.arrow.down")
            Text("Auto-Save Scans")
            Spacer()
            Toggle("", isOn: .constant(false))
                .labelsHidden()
        }
    }
}
.listStyle(InsetGroupedListStyle())

generateSnapshot(
    for: settingsSection,
    name: "Settings_ScannerSection",
    size: CGSize(width: 375, height: 250)
)

// Complete Component View
let completeView = VStack(spacing: 20) {
    Text("Home Inventory")
        .font(.largeTitle)
        .bold()
    
    SearchBar(text: .constant(""), placeholder: "Search items...")
    
    HStack(spacing: 12) {
        PrimaryButton(title: "Add Item", action: {})
        PrimaryButton(title: "Scan", action: {})
    }
    
    Spacer()
}
.padding()

generateSnapshot(
    for: completeView,
    name: "ComponentShowcase",
    size: CGSize(width: 375, height: 400)
)

print("\n✨ All snapshots generated in ./snapshots/")
print("=" * 40)

// Extension to repeat string
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
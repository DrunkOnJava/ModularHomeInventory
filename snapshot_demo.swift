#!/usr/bin/env swift

import SwiftUI
import UIKit

// Demo SwiftUI Components that would be captured by snapshot tests

// 1. Primary Button Component
struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    
    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(10)
    }
}

// 2. Loading Overlay Component
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// 3. Item Card Component
struct ItemCard: View {
    let title: String
    let price: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.gray.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(price)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// 4. Search Bar Component
struct SearchBar: View {
    @State private var searchText = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items...", text: $searchText)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Demo Preview
struct DemoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SwiftUI Component Snapshots")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Primary Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Buttons").font(.headline)
                    PrimaryButton(title: "Save Changes", isLoading: false)
                    PrimaryButton(title: "Loading...", isLoading: true)
                }
                .padding()
                
                // Search Bar
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search Bar").font(.headline)
                    SearchBar()
                }
                .padding()
                
                // Item Cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Item Cards").font(.headline)
                    ScrollView(.horizontal) {
                        HStack(spacing: 16) {
                            ItemCard(title: "MacBook Pro", price: "$2,499", category: "Electronics")
                            ItemCard(title: "Office Chair", price: "$599", category: "Furniture")
                            ItemCard(title: "Coffee Maker", price: "$149", category: "Appliances")
                        }
                    }
                }
                .padding()
                
                // Loading Overlay
                VStack(alignment: .leading, spacing: 12) {
                    Text("Loading Overlay").font(.headline)
                    ZStack {
                        Color.gray.opacity(0.1)
                            .frame(height: 200)
                        LoadingOverlay(message: "Scanning barcode...")
                    }
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
    }
}

// Create and display the demo
print("📸 SwiftUI Component Snapshot Demo")
print("==================================")
print()
print("The snapshot tests would capture the following components:")
print()
print("1. PrimaryButton - Action buttons in default and loading states")
print("2. SearchBar - Search input with clear functionality")
print("3. ItemCard - Product display cards with image, title, and price")
print("4. LoadingOverlay - Loading indicators with messages")
print()
print("Each component would be captured in:")
print("• Light mode")
print("• Dark mode") 
print("• Different device sizes (iPhone, iPad)")
print("• Accessibility text sizes")
print()
print("Snapshots would be saved as PNG files in __Snapshots__ directories")
print("for visual regression testing during development.")
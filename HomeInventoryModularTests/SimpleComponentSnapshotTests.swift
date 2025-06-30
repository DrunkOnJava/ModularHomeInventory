//
//  SimpleComponentSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Description: Simplified snapshot tests for basic UI components
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class SimpleComponentSnapshotTests: SnapshotTestCase {
    
    // Test SearchBar component
    func testSearchBar_Empty() {
        let searchBar = SearchBar(text: .constant(""), placeholder: "Search items...")
            .frame(height: 60)
            .padding()
            .background(Color.white)
        
        assertSnapshot(matching: AnyView(searchBar), as: .image(size: CGSize(width: 375, height: 100)))
    }
    
    func testSearchBar_WithText() {
        let searchBar = SearchBar(text: .constant("MacBook Pro"), placeholder: "Search items...")
            .frame(height: 60)
            .padding()
            .background(Color.white)
        
        assertSnapshot(matching: AnyView(searchBar), as: .image(size: CGSize(width: 375, height: 100)))
    }
    
    // Test PrimaryButton component
    func testPrimaryButton_Default() {
        let button = PrimaryButton(title: "Add Item", action: {})
            .frame(width: 200, height: 50)
            .padding()
            .background(Color.white)
        
        assertSnapshot(matching: AnyView(button), as: .image(size: CGSize(width: 250, height: 100)))
    }
    
    func testPrimaryButton_Loading() {
        let button = PrimaryButton(title: "Saving...", isLoading: true, action: {})
            .frame(width: 200, height: 50)
            .padding()
            .background(Color.white)
        
        assertSnapshot(matching: AnyView(button), as: .image(size: CGSize(width: 250, height: 100)))
    }
    
    // Test LoadingOverlay component
    func testLoadingOverlay() {
        let overlay = LoadingOverlay(isLoading: .constant(true), message: "Processing...")
            .frame(width: 300, height: 300)
            .background(Color.gray.opacity(0.1))
        
        assertSnapshot(matching: AnyView(overlay), as: .image(size: CGSize(width: 300, height: 300)))
    }
    
    // Test simple list section
    func testSettingsListSection() {
        let section = List {
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
        .frame(width: 375, height: 250)
        
        assertSnapshot(matching: AnyView(section), as: .image(size: CGSize(width: 375, height: 250)))
    }
    
    // Test notification settings
    func testNotificationSettings() {
        let view = VStack(spacing: 20) {
            Text("Notification Settings")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Warranty Expiration", isOn: .constant(true))
                Toggle("Service Reminders", isOn: .constant(true))
                Toggle("Price Alerts", isOn: .constant(false))
                
                HStack {
                    Text("Reminder Time")
                    Spacer()
                    Text("30 days before")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .frame(width: 375)
        .background(Color.white)
        
        assertSnapshot(matching: AnyView(view), as: .image(size: CGSize(width: 375, height: 350)))
    }
}
//
//  ContentView.swift
//  HomeInventoryModular
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Main App Target
//  Dependencies: SwiftUI, SharedUI, Items, BarcodeScanner, AppSettings
//  Testing: HomeInventoryModularTests/ContentViewTests.swift
//
//  Description: Main content view with tab navigation and module integration
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI
import Items
import BarcodeScanner
import AppSettings
import Receipts
import Core
import Gmail

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0
    @State private var showingSearch = false
    @State private var showingBarcodeSearch = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Use enhanced iPad interface with all features
            IPadSidebarEnhanced()
                .environmentObject(coordinator)
        } else {
            TabView(selection: $selectedTab) {
                // Items Tab - Now using the Items module!
                NavigationView {
                    coordinator.itemsModule.makeItemsListView(onSearchTapped: {
                        showingSearch = true
                    }, onBarcodeSearchTapped: {
                        showingBarcodeSearch = true
                    })
                }
                    .tabItem {
                        Label("Items", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                // Insurance Tab
                NavigationView {
                    coordinator.itemsModule.makeInsuranceDashboardView()
                }
                    .tabItem {
                        Label("Insurance", systemImage: "shield.fill")
                    }
                    .tag(1)
                
                // Analytics Tab - Spending Dashboard
                NavigationView {
                    coordinator.itemsModule.makeSpendingDashboardView()
                }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                // Scanner Tab - Now using the Scanner module!
                NavigationView {
                    coordinator.scannerModule.makeScannerView()
                }
                    .tabItem {
                        Label("Scanner", systemImage: "barcode.viewfinder")
                    }
                    .tag(3)
                
                // Settings Tab - Now using the Settings module!
                NavigationView {
                    coordinator.settingsModule.makeSettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
            }
            .accentColor(AppColors.primary)
            .withOfflineIndicator()
            .sheet(isPresented: $showingSearch) {
                coordinator.itemsModule.makeNaturalLanguageSearchView()
            }
            .sheet(isPresented: $showingBarcodeSearch) {
                coordinator.itemsModule.makeBarcodeSearchView()
            }
            // Biometric lock would be added here when BiometricLockModifier is available
        }
    }
}

// Gmail banner for promoting Gmail integration
struct GmailBanner: View {
    @StateObject private var gmailModule = GmailModule()
    @State private var showingGmailSetup = false
    
    var body: some View {
        if !gmailModule.isAuthenticated {
            Button(action: { showingGmailSetup = true }) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect Gmail for Easy Receipt Import")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Automatically import receipts from your email")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .sheet(isPresented: $showingGmailSetup) {
                gmailModule.makeReceiptImportView()
            }
        }
    }
}

// Button style for subtle scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
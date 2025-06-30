//
//  ImportExportDashboard.swift
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
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI
import SharedUI
import Items
import Core

/// Dashboard view for import/export operations
struct ImportExportDashboard: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingCSVImport = false
    @State private var showingCSVExport = false
    @State private var showingPDFExport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.on.square.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        
                        Text("Import & Export")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Manage your inventory data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Import Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Import Data")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ImportExportCard(
                                title: "CSV Import",
                                description: "Import items from CSV file",
                                icon: "doc.text.fill",
                                color: .blue
                            ) {
                                showingCSVImport = true
                            }
                            
                            ImportExportCard(
                                title: "Backup Restore",
                                description: "Restore from backup file",
                                icon: "arrow.clockwise.circle.fill",
                                color: .green
                            ) {
                                // Show backup restore
                            }
                        }
                    }
                    
                    // Export Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Data")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ImportExportCard(
                                title: "CSV Export",
                                description: "Export all items to CSV",
                                icon: "square.and.arrow.up.fill",
                                color: .orange
                            ) {
                                showingCSVExport = true
                            }
                            
                            ImportExportCard(
                                title: "PDF Report",
                                description: "Generate PDF inventory report",
                                icon: "doc.richtext.fill",
                                color: .red
                            ) {
                                showingPDFExport = true
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Import & Export")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCSVImport) {
                coordinator.itemsModule.makeCSVImportView()
            }
            .sheet(isPresented: $showingCSVExport) {
                coordinator.itemsModule.makeCSVExportView()
            }
            .sheet(isPresented: $showingPDFExport) {
                Text("PDF Export - Coming Soon")
                    .padding()
            }
        }
    }
}

/// Reusable card component for import/export actions
struct ImportExportCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ImportExportDashboard()
        .environmentObject(AppCoordinator())
}
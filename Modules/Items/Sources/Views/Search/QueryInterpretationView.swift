//
//  QueryInterpretationView.swift
//  Items Module
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
//  Module: Items
//  Dependencies: SwiftUI, Core
//  Testing: ItemsTests/QueryInterpretationViewTests.swift
//
//  Description: View for interpreting and displaying natural language search query results
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import SwiftUI

// MARK: - Query Interpretation View
struct QueryInterpretationView: View {
    let interpretation: QueryInterpretation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Searching for:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(interpretation.components, id: \.self) { component in
                        InterpretationChip(component: component)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct InterpretationChip: View {
    let component: QueryComponent
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: component.icon)
                .font(.caption)
            Text(component.value)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: component.color).opacity(0.2))
        .foregroundStyle(Color(hex: component.color))
        .cornerRadius(15)
    }
}

// MARK: - Data Models
struct QueryInterpretation {
    let components: [QueryComponent]
}

struct QueryComponent: Hashable {
    enum ComponentType {
        case color, item, location, time, price, brand, category, action
    }
    
    let type: ComponentType
    let value: String
    let icon: String
    let color: String
}
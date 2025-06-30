//
//  IPadNavigationState.swift
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
import Combine

/// Navigation state management for iPad interface
@MainActor
final class IPadNavigationState: ObservableObject {
    @Published var selectedTab: IPadTab = .items
    @Published var selectedDetailItem: UUID?
    @Published var isSlideOverVisible = false
    @Published var slideOverContent: SlideOverContent = .scanner
    
    init() {}
}

/// iPad tab enumeration
enum IPadTab: String, CaseIterable {
    case items = "items"
    case insurance = "insurance"
    case locations = "locations"
    case categories = "categories"
    case analytics = "analytics"
    case reports = "reports"
    case budget = "budget"
    case scanner = "scanner"
    case search = "search"
    case importExport = "importExport"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .items: return "Items"
        case .insurance: return "Insurance"
        case .locations: return "Locations"
        case .categories: return "Categories"
        case .analytics: return "Analytics"
        case .reports: return "Reports"
        case .budget: return "Budget"
        case .scanner: return "Scanner"
        case .search: return "Search"
        case .importExport: return "Import/Export"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .items: return "shippingbox.fill"
        case .insurance: return "shield.fill"
        case .locations: return "location.fill"
        case .categories: return "square.grid.2x2.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .reports: return "doc.text.fill"
        case .budget: return "dollarsign.circle.fill"
        case .scanner: return "barcode.viewfinder"
        case .search: return "magnifyingglass"
        case .importExport: return "square.and.arrow.up.on.square.fill"
        case .settings: return "gear"
        }
    }
}
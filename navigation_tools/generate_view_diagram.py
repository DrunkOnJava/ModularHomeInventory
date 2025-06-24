#!/usr/bin/env python3
"""
Generate a visual diagram of SwiftUI view hierarchy and navigation links
for the Modular Home Inventory app.
"""

import graphviz
import os

def create_navigation_diagram():
    # Create a new directed graph
    dot = graphviz.Digraph('ViewHierarchy', 
                          comment='Modular Home Inventory Navigation',
                          format='png',
                          engine='dot')
    
    # Graph attributes for better layout
    dot.attr(rankdir='TB', splines='ortho', nodesep='0.5', ranksep='1.0')
    dot.attr('node', shape='box', style='rounded,filled', fillcolor='lightblue')
    
    # Define node styles for different view types
    root_style = {'fillcolor': 'darkseagreen', 'fontsize': '14', 'fontweight': 'bold'}
    tab_style = {'fillcolor': 'lightcoral', 'shape': 'tab'}
    sheet_style = {'fillcolor': 'lightyellow', 'style': 'rounded,filled,dashed'}
    nav_style = {'fillcolor': 'lightsteelblue'}
    
    # Root nodes
    dot.node('App', 'HomeInventoryModularApp', **root_style)
    dot.node('iPadApp', 'iPadApp', **root_style)
    
    # Main containers
    dot.node('ContentView', 'ContentView\n(iPhone)', **tab_style)
    dot.node('iPadSidebarView', 'iPadSidebarView\n(iPad)', **tab_style)
    
    # Connect roots to main views
    dot.edge('App', 'ContentView', label='WindowGroup')
    dot.edge('iPadApp', 'iPadSidebarView', label='NavigationSplitView')
    
    # Tab Views (iPhone)
    tabs = [
        ('ItemsListView', 'Items'),
        ('CollectionsListView', 'Collections'),
        ('SpendingDashboardView', 'Analytics'),
        ('ScannerView', 'Scanner'),
        ('SettingsView', 'Settings')
    ]
    
    for view_id, label in tabs:
        dot.node(view_id, label, **nav_style)
        dot.edge('ContentView', view_id, label='Tab')
    
    # Items Module Navigation
    items_sheets = [
        ('AddItemView', 'Add Item'),
        ('ItemDetailView', 'Item Detail'),
        ('CSVImportView', 'CSV Import'),
        ('CSVExportView', 'CSV Export'),
        ('ItemShareView', 'Share Item'),
        ('AdvancedFiltersView', 'Filters')
    ]
    
    for view_id, label in items_sheets:
        dot.node(view_id, label, **sheet_style)
        dot.edge('ItemsListView', view_id, label='sheet', style='dashed')
    
    # Item Detail Sub-views
    detail_sheets = [
        ('EditItemView', 'Edit Item'),
        ('PhotoGalleryView', 'Photos'),
        ('WarrantyDetailView', 'Warranty'),
        ('ItemDocumentsView', 'Documents'),
        ('CloudSyncView', 'Cloud Sync')
    ]
    
    for view_id, label in detail_sheets:
        dot.node(view_id, label, **sheet_style)
        dot.edge('ItemDetailView', view_id, label='sheet', style='dashed')
    
    # Collections Navigation
    dot.node('AddEditCollectionView', 'Add/Edit Collection', **sheet_style)
    dot.node('CollectionDetailView', 'Collection Detail', **nav_style)
    dot.edge('CollectionsListView', 'AddEditCollectionView', label='sheet', style='dashed')
    dot.edge('CollectionsListView', 'CollectionDetailView', label='navigate')
    
    # Analytics Sub-views
    analytics_views = [
        ('CategoryAnalyticsView', 'Category Analytics'),
        ('RetailerAnalyticsView', 'Retailer Analytics'),
        ('TimeBasedAnalyticsView', 'Time Analytics'),
        ('PurchasePatternsView', 'Purchase Patterns')
    ]
    
    for view_id, label in analytics_views:
        dot.node(view_id, label, **nav_style)
        dot.edge('SpendingDashboardView', view_id, label='link')
    
    # Settings Module (all sheets)
    settings_sheets = [
        ('NotificationSettingsView', 'Notifications'),
        ('SpotlightSettingsView', 'Spotlight'),
        ('AccessibilitySettingsView', 'Accessibility'),
        ('ScannerSettingsView', 'Scanner Settings'),
        ('BiometricSettingsView', 'Biometric'),
        ('PrivacyPolicyView', 'Privacy'),
        ('ExportDataView', 'Export Data'),
        ('SyncStatusView', 'Sync Status')
    ]
    
    # Create a subgraph for settings to group them
    with dot.subgraph(name='cluster_settings') as c:
        c.attr(label='Settings Module', style='rounded,dashed')
        for view_id, label in settings_sheets:
            c.node(view_id, label, **sheet_style)
            dot.edge('SettingsView', view_id, label='sheet', style='dashed')
    
    # Scanner Module
    scanner_tabs = [
        ('BarcodeScannerView', 'Barcode Scanner'),
        ('BatchScannerView', 'Batch Scanner'),
        ('ScanHistoryView', 'Scan History')
    ]
    
    with dot.subgraph(name='cluster_scanner') as c:
        c.attr(label='Scanner Module', style='rounded,dashed')
        dot.node('ScannerTabView', 'Scanner Tab View', **tab_style)
        dot.edge('ScannerView', 'ScannerTabView')
        
        for view_id, label in scanner_tabs:
            c.node(view_id, label, **nav_style)
            dot.edge('ScannerTabView', view_id, label='tab')
    
    # iPad Sidebar destinations
    ipad_destinations = [
        ('ItemsListView_iPad', 'Items'),
        ('CollectionsListView_iPad', 'Collections'),
        ('LocationsView', 'Locations'),
        ('CategoriesView', 'Categories'),
        ('SpendingDashboardView_iPad', 'Analytics'),
        ('ReportsView', 'Reports'),
        ('BudgetDashboardView', 'Budget'),
        ('ScannerView_iPad', 'Scanner'),
        ('SearchView', 'Search'),
        ('ImportExportView', 'Import/Export'),
        ('SettingsView_iPad', 'Settings')
    ]
    
    with dot.subgraph(name='cluster_ipad') as c:
        c.attr(label='iPad Navigation', style='rounded,dashed')
        for view_id, label in ipad_destinations:
            c.node(view_id, label, **nav_style)
            dot.edge('iPadSidebarView', view_id, label='sidebar')
    
    # Add legend
    with dot.subgraph(name='cluster_legend') as c:
        c.attr(label='Legend', style='rounded')
        c.node('legend_root', 'Root View', **root_style)
        c.node('legend_tab', 'Tab Container', **tab_style)
        c.node('legend_nav', 'Navigation Link', **nav_style)
        c.node('legend_sheet', 'Sheet/Modal', **sheet_style)
        
        # Invisible edges to align legend items
        c.edge('legend_root', 'legend_tab', style='invis')
        c.edge('legend_tab', 'legend_nav', style='invis')
        c.edge('legend_nav', 'legend_sheet', style='invis')
    
    return dot

def create_simplified_diagram():
    """Create a simplified high-level navigation diagram"""
    dot = graphviz.Digraph('SimplifiedNavigation', 
                          comment='Simplified Navigation Overview',
                          format='png',
                          engine='dot')
    
    dot.attr(rankdir='TB', splines='ortho')
    dot.attr('node', shape='box', style='rounded,filled')
    
    # Main app structure
    dot.node('App', 'App', fillcolor='darkseagreen', fontsize='16')
    dot.node('iPhone', 'iPhone\n(Tab-based)', fillcolor='lightcoral')
    dot.node('iPad', 'iPad\n(Sidebar)', fillcolor='lightcoral')
    
    dot.edge('App', 'iPhone')
    dot.edge('App', 'iPad')
    
    # Main modules
    modules = [
        ('Items', 'Items\nModule'),
        ('Collections', 'Collections\nModule'),
        ('Analytics', 'Analytics\nModule'),
        ('Scanner', 'Scanner\nModule'),
        ('Settings', 'Settings\nModule'),
        ('Budget', 'Budget\nModule'),
        ('Warranty', 'Warranty\nModule')
    ]
    
    for module_id, label in modules:
        dot.node(module_id, label, fillcolor='lightsteelblue')
        if module_id in ['Items', 'Collections', 'Analytics', 'Scanner', 'Settings']:
            dot.edge('iPhone', module_id)
        dot.edge('iPad', module_id)
    
    return dot

if __name__ == '__main__':
    # Generate detailed diagram
    detailed = create_navigation_diagram()
    detailed.render('navigation_diagram_detailed', cleanup=True)
    print("Generated: navigation_diagram_detailed.png")
    
    # Generate simplified diagram
    simplified = create_simplified_diagram()
    simplified.render('navigation_diagram_simplified', cleanup=True)
    print("Generated: navigation_diagram_simplified.png")
    
    # Generate DOT files for manual editing
    with open('navigation_detailed.dot', 'w') as f:
        f.write(detailed.source)
    print("Generated: navigation_detailed.dot")
    
    with open('navigation_simplified.dot', 'w') as f:
        f.write(simplified.source)
    print("Generated: navigation_simplified.dot")
    
    print("\nDiagrams generated successfully!")
    print("You can view the PNG files or edit the DOT files for customization.")
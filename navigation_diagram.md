# Navigation Diagram - Modular Home Inventory

## Overview
This document contains Mermaid diagrams showing the navigation structure of the app. You can view these diagrams in any Markdown viewer that supports Mermaid (GitHub, VS Code with Mermaid extension, etc.).

## Simplified Navigation Overview

```mermaid
graph TB
    App[App Entry Points]
    App --> iPhone[iPhone<br/>Tab-based Navigation]
    App --> iPad[iPad<br/>Sidebar Navigation]
    
    iPhone --> Tab1[Items]
    iPhone --> Tab2[Collections]
    iPhone --> Tab3[Analytics]
    iPhone --> Tab4[Scanner]
    iPhone --> Tab5[Settings]
    
    iPad --> Sidebar[Sidebar Menu]
    Sidebar --> I1[Items]
    Sidebar --> I2[Collections]
    Sidebar --> I3[Locations]
    Sidebar --> I4[Categories]
    Sidebar --> I5[Analytics]
    Sidebar --> I6[Reports]
    Sidebar --> I7[Budget]
    Sidebar --> I8[Scanner]
    Sidebar --> I9[Search]
    Sidebar --> I10[Import/Export]
    Sidebar --> I11[Settings]
    
    style App fill:#90EE90
    style iPhone fill:#FFA07A
    style iPad fill:#FFA07A
```

## Detailed Items Module Navigation

```mermaid
graph TD
    ItemsList[ItemsListView]
    
    ItemsList -.->|sheet| AddItem[AddItemView]
    ItemsList -.->|sheet| ItemDetail[ItemDetailView]
    ItemsList -.->|sheet| CSVImport[CSVImportView]
    ItemsList -.->|sheet| CSVExport[CSVExportView]
    ItemsList -.->|sheet| Share[ItemShareView]
    ItemsList -.->|sheet| Filters[AdvancedFiltersView]
    
    ItemDetail -.->|sheet| Edit[EditItemView]
    ItemDetail -.->|sheet| Photos[PhotoGalleryView]
    ItemDetail -.->|sheet| Warranty[WarrantyDetailView]
    ItemDetail -.->|sheet| Docs[ItemDocumentsView]
    ItemDetail -.->|sheet| Sync[CloudSyncView]
    
    style ItemsList fill:#B0C4DE
    style ItemDetail fill:#FFFFE0
    style AddItem fill:#FFFFE0
    style Edit fill:#FFFFE0
```

## Settings Module Navigation (All Sheets)

```mermaid
graph TD
    Settings[SettingsView]
    
    Settings -.->|sheet| Notif[NotificationSettingsView]
    Settings -.->|sheet| Spot[SpotlightSettingsView]
    Settings -.->|sheet| Access[AccessibilitySettingsView]
    Settings -.->|sheet| ScanSet[ScannerSettingsView]
    Settings -.->|sheet| Bio[BiometricSettingsView]
    Settings -.->|sheet| Privacy[PrivacyPolicyView]
    Settings -.->|sheet| Terms[TermsOfServiceView]
    Settings -.->|sheet| Export[ExportDataView]
    Settings -.->|sheet| Cache[ClearCacheView]
    Settings -.->|sheet| Crash[CrashReportingSettingsView]
    Settings -.->|sheet| SyncStat[SyncStatusView]
    Settings -.->|sheet| Conflicts[ConflictResolutionView]
    Settings -.->|sheet| Offline[OfflineDataView]
    Settings -.->|sheet| Rate[RateAppView]
    Settings -.->|sheet| ShareApp[ShareAppView]
    
    style Settings fill:#B0C4DE
```

## Analytics Module Navigation

```mermaid
graph TD
    Dashboard[SpendingDashboardView]
    
    Dashboard -->|NavigationLink| Cat[CategoryAnalyticsView]
    Dashboard -->|NavigationLink| Retail[RetailerAnalyticsView]
    Dashboard -->|NavigationLink| Time[TimeBasedAnalyticsView]
    Dashboard -->|NavigationLink| Patterns[PurchasePatternsView]
    
    style Dashboard fill:#B0C4DE
```

## Complete Navigation Flow

```mermaid
graph TB
    subgraph "App Entry"
        App[HomeInventoryModularApp]
        iPadApp[iPadApp]
    end
    
    subgraph "iPhone Navigation"
        Content[ContentView<br/>TabView]
        T1[Items Tab]
        T2[Collections Tab]
        T3[Analytics Tab]
        T4[Scanner Tab]
        T5[Settings Tab]
    end
    
    subgraph "iPad Navigation"
        Sidebar[iPadSidebarView<br/>NavigationSplitView]
        S1[Inventory Section]
        S2[Insights Section]
        S3[Tools Section]
        S4[Settings Section]
    end
    
    App --> Content
    iPadApp --> Sidebar
    
    Content --> T1
    Content --> T2
    Content --> T3
    Content --> T4
    Content --> T5
    
    Sidebar --> S1
    Sidebar --> S2
    Sidebar --> S3
    Sidebar --> S4
    
    style App fill:#90EE90
    style iPadApp fill:#90EE90
    style Content fill:#FFA07A
    style Sidebar fill:#FFA07A
```

## Navigation Types Legend

- **Solid Arrow (→)**: NavigationLink (push navigation)
- **Dashed Arrow (-.->)**: Sheet presentation (modal)
- **Tab Container**: TabView navigation
- **Sidebar**: NavigationSplitView (iPad)

## Key Navigation Patterns

1. **iPhone**: Uses TabView with 5 main tabs, each containing NavigationView
2. **iPad**: Uses NavigationSplitView with sidebar sections
3. **Modal Sheets**: Used extensively for forms, settings, and detail views
4. **NavigationLinks**: Used for hierarchical navigation within modules
5. **Programmatic Navigation**: Handled via view models and callbacks
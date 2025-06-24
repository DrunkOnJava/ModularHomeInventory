# Navigation Analysis Tools

This folder contains tools and documentation for analyzing and visualizing the SwiftUI navigation structure of the Modular Home Inventory app.

## Contents

### Analysis Tools
- **`advanced_nav_analyzer.py`** - Comprehensive Python analyzer that extracts navigation patterns
- **`quick_nav_analyzer.sh`** - Quick bash script for basic navigation analysis
- **`generate_view_diagram.py`** - Python script for generating GraphViz diagrams (requires graphviz)

### Documentation
- **`free_cli_tools_summary.md`** - Summary of all free CLI tools available
- **`automated_diagram_tools.md`** - List of automated diagram generation tools
- **`reveal_setup.md`** - Guide for setting up Reveal app (commercial tool)
- **`navigation_analysis_report.md`** - Comprehensive report on the app's navigation architecture
- **`navigation_diagram.md`** - Mermaid diagrams of the navigation structure

### Analysis Results
- **`navigation_analysis/`** - Output directory containing:
  - `navigation.mmd` - Mermaid diagram
  - `navigation.dot` - GraphViz diagram
  - `navigation_data.json` - Raw navigation data
  - `report.txt` - Analysis summary
  - Various `.txt` files with extracted patterns

## Quick Start

1. Run the comprehensive analyzer:
   ```bash
   cd navigation_tools
   python3 advanced_nav_analyzer.py
   ```

2. View the Mermaid diagram:
   - Copy contents of `navigation_analysis/navigation.mmd`
   - Paste into https://mermaid.live

3. Generate PNG (requires GraphViz):
   ```bash
   brew install graphviz
   dot -Tpng navigation_analysis/navigation.dot -o navigation.png
   ```

## Key Findings

- **367** SwiftUI views detected
- **104** navigation connections
  - 89 sheet presentations (86%)
  - 14 navigation links (13%)
  - 1 fullscreen cover (1%)
- Most connected view: `SpendingDashboardView` (9 connections)
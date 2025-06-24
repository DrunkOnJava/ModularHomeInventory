# Free CLI Tools for SwiftUI Navigation Diagram Generation

## Successfully Tested Tools

### 1. **Python-based Advanced Analyzer** ✅
```bash
python3 advanced_nav_analyzer.py
```
- **Results**: Found 104 navigation connections (89 sheets, 14 nav links, 1 fullscreen)
- **Output**: Mermaid diagram, GraphViz DOT, JSON data, text report
- **Best for**: Comprehensive analysis with multiple output formats

### 2. **Bash Script Quick Analyzer** ⚡
```bash
./quick_nav_analyzer.sh
```
- **Results**: Basic view detection, needs pattern improvements
- **Output**: Simple text files and basic diagrams
- **Best for**: Quick overview and shell-based workflows

### 3. **SourceKitten** (Requires installation)
```bash
brew install sourcekitten
sourcekitten structure --file SomeView.swift | jq '.["key.substructure"]'
```
- **Best for**: Deep Swift AST analysis
- **Note**: More complex but provides richer data

## Available Free Tools

### Static Analysis
1. **grep/awk/sed** - Built into macOS, pattern matching
2. **Python with regex** - Cross-platform, customizable
3. **SourceKitten** - Swift AST parser
4. **SwiftPlantUML** - UML diagram generator
5. **swift-ast-explorer** - AST navigation tool

### Visualization
1. **Mermaid** - Web-based diagram viewer (mermaid.live)
2. **GraphViz** - Install with `brew install graphviz`
3. **PlantUML** - Text-to-diagram tool
4. **ASCII diagrams** - Terminal-friendly output

## Quick Start Commands

```bash
# 1. Run the Python analyzer (most comprehensive)
python3 advanced_nav_analyzer.py

# 2. View Mermaid diagram
# Copy navigation_analysis/navigation.mmd content to https://mermaid.live

# 3. Generate PNG with GraphViz (if installed)
dot -Tpng navigation_analysis/navigation.dot -o navigation.png

# 4. View JSON data for custom processing
cat navigation_analysis/navigation_data.json | jq '.'
```

## Key Findings from Analysis

- **Total views**: 367 SwiftUI views
- **Navigation connections**: 104 total
  - Sheet presentations: 89 (86%)
  - Navigation links: 14 (13%)
  - Fullscreen covers: 1 (1%)
- **Most connected view**: SpendingDashboardView (9 connections)
- **Root views identified**: 32 views with no incoming connections

## Recommended Workflow

1. Use `advanced_nav_analyzer.py` for comprehensive analysis
2. View diagrams at mermaid.live (no installation needed)
3. Install GraphViz only if you need high-quality PNG/PDF output
4. Use the JSON output for custom visualizations or further analysis

All these tools are completely free and work from the command line!
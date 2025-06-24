#!/bin/bash
# Quick navigation analyzer for SwiftUI projects

echo "=== SwiftUI Navigation Analysis ==="
echo "Running analysis on: $(pwd)"
echo "=================================="

# Create output directory
mkdir -p navigation_analysis

# 1. Find all SwiftUI Views
echo -e "\n📁 Finding all SwiftUI Views..."
grep -r "struct.*:.*View" --include="*.swift" . | \
  sed 's/.*\/\([^\/]*\.swift\):.*struct \([^:]*\):.*/\1:\2/' | \
  sort > navigation_analysis/all_views.txt
echo "Found $(wc -l < navigation_analysis/all_views.txt) views"

# 2. Extract NavigationLinks
echo -e "\n🔗 Extracting NavigationLinks..."
grep -r "NavigationLink" --include="*.swift" . | \
  while IFS=: read -r file line content; do
    source=$(basename "$file" .swift)
    dest=$(echo "$content" | grep -oE 'destination:[[:space:]]*\{[[:space:]]*([A-Z][a-zA-Z]*)' | sed 's/.*{[[:space:]]*//')
    if [ ! -z "$dest" ]; then
      echo "$source -> $dest [NavigationLink]"
    fi
  done | sort | uniq > navigation_analysis/navigation_links.txt
echo "Found $(wc -l < navigation_analysis/navigation_links.txt) navigation links"

# 3. Extract Sheet Presentations
echo -e "\n📄 Extracting Sheet Presentations..."
grep -r "\.sheet" --include="*.swift" . | \
  while IFS=: read -r file line content; do
    source=$(basename "$file" .swift)
    dest=$(echo "$content" | grep -oE '\{[[:space:]]*([A-Z][a-zA-Z]*View)' | sed 's/.*{[[:space:]]*//')
    if [ ! -z "$dest" ]; then
      echo "$source -> $dest [Sheet]"
    fi
  done | sort | uniq > navigation_analysis/sheets.txt
echo "Found $(wc -l < navigation_analysis/sheets.txt) sheet presentations"

# 4. Extract TabView Items
echo -e "\n📑 Extracting TabView Items..."
grep -B5 -A5 "TabView" --include="*.swift" -r . | \
  grep -E "Label\(|\.tag\(" | \
  grep -oE '[A-Z][a-zA-Z]*View' | \
  sort | uniq > navigation_analysis/tab_items.txt
echo "Found $(wc -l < navigation_analysis/tab_items.txt) tab items"

# 5. Generate Mermaid Diagram
echo -e "\n📊 Generating Mermaid Diagram..."
cat > navigation_analysis/navigation.mmd << 'EOF'
graph TD
    App[App Entry]
    
    %% Main Navigation Structure
    App --> ContentView[ContentView<br/>iPhone]
    App --> iPadSidebarView[iPadSidebarView<br/>iPad]
    
    %% Tab Structure
    ContentView --> ItemsTab[Items Tab]
    ContentView --> CollectionsTab[Collections Tab]
    ContentView --> AnalyticsTab[Analytics Tab]
    ContentView --> ScannerTab[Scanner Tab]
    ContentView --> SettingsTab[Settings Tab]
    
EOF

# Add navigation links
echo "    %% Navigation Links" >> navigation_analysis/navigation.mmd
while IFS= read -r line; do
    source=$(echo "$line" | cut -d' ' -f1)
    dest=$(echo "$line" | cut -d' ' -f3)
    echo "    $source --> $dest" >> navigation_analysis/navigation.mmd
done < navigation_analysis/navigation_links.txt

# Add sheets
echo "    %% Sheet Presentations" >> navigation_analysis/navigation.mmd
while IFS= read -r line; do
    source=$(echo "$line" | cut -d' ' -f1)
    dest=$(echo "$line" | cut -d' ' -f3)
    echo "    $source -.-> $dest" >> navigation_analysis/navigation.mmd
done < navigation_analysis/sheets.txt

# 6. Generate GraphViz DOT file
echo -e "\n📈 Generating GraphViz DOT file..."
cat > navigation_analysis/navigation.dot << 'EOF'
digraph NavigationFlow {
    rankdir=TB;
    node [shape=box, style="rounded,filled", fillcolor=lightblue];
    edge [fontsize=10];
    
    // Main entry points
    App [label="App", fillcolor=darkseagreen];
    ContentView [label="ContentView\n(iPhone)", fillcolor=lightcoral];
    iPadSidebarView [label="iPadSidebarView\n(iPad)", fillcolor=lightcoral];
    
    App -> ContentView;
    App -> iPadSidebarView;
    
EOF

# Add all relationships
echo "    // Navigation Links" >> navigation_analysis/navigation.dot
awk '{print "    " $1 " -> " $3 " [label=\"nav\"];"}' navigation_analysis/navigation_links.txt >> navigation_analysis/navigation.dot

echo "    // Sheet Presentations" >> navigation_analysis/navigation.dot
awk '{print "    " $1 " -> " $3 " [label=\"sheet\", style=dashed];"}' navigation_analysis/sheets.txt >> navigation_analysis/navigation.dot

echo "}" >> navigation_analysis/navigation.dot

# 7. Generate Summary Report
echo -e "\n📋 Generating Summary Report..."
cat > navigation_analysis/summary.txt << EOF
SwiftUI Navigation Analysis Summary
===================================
Generated: $(date)
Project: $(basename $(pwd))

Statistics:
-----------
Total Views: $(wc -l < navigation_analysis/all_views.txt)
Navigation Links: $(wc -l < navigation_analysis/navigation_links.txt)
Sheet Presentations: $(wc -l < navigation_analysis/sheets.txt)
Tab Items: $(wc -l < navigation_analysis/tab_items.txt)

Top Source Views (by outgoing connections):
EOF

# Count outgoing connections
cat navigation_analysis/navigation_links.txt navigation_analysis/sheets.txt | \
  cut -d' ' -f1 | sort | uniq -c | sort -rn | head -10 >> navigation_analysis/summary.txt

echo -e "\nTop Destination Views (by incoming connections):" >> navigation_analysis/summary.txt
cat navigation_analysis/navigation_links.txt navigation_analysis/sheets.txt | \
  cut -d' ' -f3 | sort | uniq -c | sort -rn | head -10 >> navigation_analysis/summary.txt

# 8. Final output
echo -e "\n✅ Analysis Complete!"
echo "=================================="
echo "Generated files in navigation_analysis/:"
echo "  - all_views.txt: List of all SwiftUI views"
echo "  - navigation_links.txt: NavigationLink relationships"
echo "  - sheets.txt: Sheet presentation relationships"
echo "  - tab_items.txt: TabView items"
echo "  - navigation.mmd: Mermaid diagram"
echo "  - navigation.dot: GraphViz diagram"
echo "  - summary.txt: Analysis summary"
echo ""
echo "To view diagrams:"
echo "  - Mermaid: Copy navigation.mmd to https://mermaid.live"
echo "  - GraphViz: dot -Tpng navigation_analysis/navigation.dot -o navigation.png"
echo "  - Or install graphviz: brew install graphviz"
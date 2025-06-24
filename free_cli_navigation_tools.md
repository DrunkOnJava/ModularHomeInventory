# Free Command-Line Tools for SwiftUI Navigation Visualization

## 1. **SourceKitten** + Custom Script
```bash
# Install
brew install sourcekitten

# Extract structure
sourcekitten structure --file ContentView.swift > structure.json

# Parse navigation with jq
cat structure.json | jq '.key.substructure[] | select(.key.name | contains("NavigationLink"))'
```

## 2. **SwiftSyntax-based Parser**
```bash
# Create a Swift script using swift-syntax
swift package init --type executable --name NavParser
# Add SwiftSyntax dependency and parse navigation patterns
```

## 3. **grep/awk/sed Pipeline**
```bash
#!/bin/bash
# find_navigation.sh

# Find all NavigationLinks
echo "=== NavigationLinks ==="
grep -r "NavigationLink" --include="*.swift" . | \
  sed -n 's/.*destination:.*{\s*\([A-Z][a-zA-Z]*\).*/\1/p' | \
  sort | uniq

# Find all sheets
echo -e "\n=== Sheet Presentations ==="
grep -r "\.sheet" --include="*.swift" . | \
  grep -oE "[A-Z][a-zA-Z]*View" | \
  sort | uniq

# Find TabView items
echo -e "\n=== TabView Items ==="
grep -A5 -r "TabView" --include="*.swift" . | \
  grep -E "\.tag\(|Label\(" | \
  sed 's/.*Label("\([^"]*\)".*/\1/'
```

## 4. **swift-ast-explorer** (if available)
```bash
# Parse AST and extract navigation
swift-ast-explorer --path . --query "NavigationLink"
```

## 5. **SwiftPlantUML**
```bash
# Install via SPM
git clone https://github.com/MarcoEidinger/SwiftPlantUML.git
cd SwiftPlantUML
swift build -c release

# Generate diagram
./.build/release/swiftplantuml classdiagram \
  --path /path/to/your/project \
  --output navigation.puml
```

## 6. **Custom Python Script with Regex**
```python
#!/usr/bin/env python3
# navigation_extractor.py

import re
import os
import json
from pathlib import Path

def find_swift_files(directory):
    return Path(directory).rglob("*.swift")

def extract_navigation(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    navigation = {
        'file': str(file_path),
        'navigation_links': re.findall(r'NavigationLink.*?destination:\s*{\s*([A-Z]\w+)', content),
        'sheets': re.findall(r'\.sheet.*?{\s*([A-Z]\w+)', content),
        'fullscreen': re.findall(r'\.fullScreenCover.*?{\s*([A-Z]\w+)', content),
        'tabs': re.findall(r'\.tag\([^)]+\).*?{\s*([A-Z]\w+)', content)
    }
    return navigation

# Usage
for swift_file in find_swift_files('.'):
    nav = extract_navigation(swift_file)
    if any(nav[k] for k in ['navigation_links', 'sheets', 'fullscreen', 'tabs']):
        print(json.dumps(nav, indent=2))
```

## 7. **GraphViz with Shell Script**
```bash
#!/bin/bash
# generate_nav_graph.sh

echo "digraph Navigation {" > navigation.dot
echo "  rankdir=LR;" >> navigation.dot
echo "  node [shape=box, style=rounded];" >> navigation.dot

# Extract navigation relationships
grep -r "NavigationLink" --include="*.swift" . | while read line; do
    source=$(echo "$line" | cut -d: -f1 | xargs basename | sed 's/.swift//')
    dest=$(echo "$line" | grep -oE 'destination:.*{[[:space:]]*([A-Z][a-zA-Z]*)' | \
           sed 's/.*{\s*//')
    if [ ! -z "$dest" ]; then
        echo "  $source -> $dest;" >> navigation.dot
    fi
done

echo "}" >> navigation.dot

# Generate image
dot -Tpng navigation.dot -o navigation.png
```

## 8. **Combine Tools Pipeline**
```bash
#!/bin/bash
# full_analysis.sh

# 1. Extract all Swift structures
find . -name "*.swift" -exec sourcekitten structure --file {} \; > all_structures.json

# 2. Parse with jq and create relationships
cat all_structures.json | \
  jq -r '.["key.substructure"][]? | 
         select(.["key.kind"] == "source.lang.swift.decl.struct") | 
         .["key.name"]' > views.txt

# 3. Find navigation patterns
grep -h -A5 -B5 "NavigationLink\|\.sheet\|\.fullScreenCover" *.swift > navigation_context.txt

# 4. Generate Mermaid diagram
echo "graph TD" > navigation.mmd
while IFS= read -r view; do
    grep -l "$view" *.swift | while read file; do
        grep -A3 "NavigationLink.*$view" "$file" | \
          grep -oE "destination:.*{[[:space:]]*([A-Z][a-zA-Z]*)" | \
          sed "s/.*{\s*//" | while read dest; do
            echo "  $view --> $dest" >> navigation.mmd
        done
    done
done < views.txt
```

## 9. **Using Xcode's swiftc**
```bash
# Generate interface files
xcrun swiftc -emit-interface-path - ContentView.swift > interface.swiftinterface

# Parse the interface for navigation
grep -E "NavigationLink|sheet|fullScreenCover" interface.swiftinterface
```

## Quick One-Liner Examples

```bash
# Count navigation methods
echo "Navigation Summary:"
echo -n "NavigationLinks: "; grep -r "NavigationLink" --include="*.swift" . | wc -l
echo -n "Sheets: "; grep -r "\.sheet" --include="*.swift" . | wc -l
echo -n "FullScreenCovers: "; grep -r "\.fullScreenCover" --include="*.swift" . | wc -l

# Extract view relationships
grep -r "NavigationLink\|\.sheet" --include="*.swift" . | \
  sed -E 's/.*\/([^\/]+\.swift):.*destination:.*{[[:space:]]*([A-Z][a-zA-Z]*).*/\1 -> \2/' | \
  sort | uniq

# Generate quick ASCII diagram
echo "=== Navigation Flow ==="
grep -r "struct.*:.*View" --include="*.swift" . | \
  cut -d: -f1 | xargs -I {} basename {} .swift | \
  while read view; do
    echo -n "$view -> "
    grep -l "$view" *.swift | xargs grep -h "NavigationLink\|sheet" | \
      grep -oE "[A-Z][a-zA-Z]*View" | tr '\n' ', '
    echo
  done
```

## Recommended Approach

For your project, I recommend this combination:

```bash
#!/bin/bash
# analyze_navigation.sh

# 1. Find all views
echo "Finding all SwiftUI views..."
grep -r "struct.*:.*View" --include="*.swift" . > all_views.txt

# 2. Extract navigation patterns
echo "Extracting navigation patterns..."
grep -rn "NavigationLink\|\.sheet\|\.fullScreenCover\|TabView" \
  --include="*.swift" . > navigation_patterns.txt

# 3. Generate Mermaid diagram
python3 navigation_extractor.py > navigation_data.json

# 4. Create visual representation
echo "Creating diagram..."
cat navigation_data.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print('graph TD')
for item in data:
    source = item['file'].split('/')[-1].replace('.swift','')
    for dest in item['navigation_links'] + item['sheets']:
        print(f'  {source} --> {dest}')
" > navigation.mmd

echo "Done! View navigation.mmd in any Mermaid viewer"
```

These tools are all free and work from the command line to analyze your SwiftUI navigation structure.
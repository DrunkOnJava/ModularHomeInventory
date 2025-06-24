# Automated SwiftUI Navigation Diagram Tools

## 1. **ViewInspector + Custom Script**
```bash
# Install via SPM or CocoaPods
# https://github.com/nalexn/ViewInspector
```
- Can programmatically inspect SwiftUI view hierarchies
- Requires writing custom traversal logic
- Best for unit testing but can be adapted for documentation

## 2. **SwiftUI-Introspect**
```bash
# https://github.com/siteline/SwiftUI-Introspect
```
- Runtime introspection of SwiftUI views
- Can extract navigation structure dynamically
- Requires app to be running

## 3. **SourceKit-LSP Based Tools**

### **Swift-AST-Explorer**
```bash
# Parse Swift files and extract view relationships
swift-ast-explorer analyze --path ./Sources
```

### **SourceKitten**
```bash
brew install sourcekitten
sourcekitten structure --file ContentView.swift | jq
```
- Parses Swift source code
- Can extract type information and relationships
- Requires custom script to build navigation graph

## 4. **Xcode Build Tools**

### **View Hierarchy Debugger Export**
```bash
# During debug session in Xcode:
# Debug > View Debugging > Capture View Hierarchy
# Then export as .viewhierarchy file
```

### **xcresult Bundle Analysis**
```bash
# Extract view hierarchy from test results
xcrun xcresulttool get --path MyApp.xcresult --format json
```

## 5. **Commercial/Professional Tools**

### **Reveal**
- https://revealapp.com
- Runtime inspection with export capabilities
- Can export view hierarchies as JSON/XML

### **Sherlock**
- https://sherlock.inspiredcode.io
- Specifically designed for SwiftUI
- Automatic navigation graph generation

### **PaintCode**
- Can import and visualize navigation flows
- More focused on design but handles navigation

## 6. **Custom Swift Package Solution**

Create a Swift package that uses Swift's reflection and parsing:

```swift
// NavigationMapper.swift
import SwiftSyntax
import SwiftParser

public struct NavigationMapper {
    public static func generateDiagram(from directory: URL) throws -> String {
        // 1. Parse all .swift files
        // 2. Find View conformances
        // 3. Extract NavigationLink, sheet, fullScreenCover
        // 4. Build graph structure
        // 5. Export as Mermaid/GraphViz
    }
}
```

## 7. **GitHub Actions / CI Integration**

### **swift-doc**
```bash
brew install swiftdocorg/formulae/swift-doc
swift-doc generate ./Sources --format html
```
- Can be extended to extract navigation patterns

### **SwiftPlantUML**
```bash
# https://github.com/MarcoEidinger/SwiftPlantUML
swiftplantuml classdiagram --path ./Sources
```
- Generates UML diagrams from Swift code
- Can be customized for navigation flows

## 8. **Regex/Script-Based Approaches**

### Quick Bash/Python Script
```bash
# Find all NavigationLinks
grep -r "NavigationLink" --include="*.swift" . | \
  sed 's/.*destination: *\([^,)]*\).*/\1/' | \
  sort | uniq

# Find all sheet presentations
grep -r "\.sheet" --include="*.swift" . | \
  awk -F'[{}]' '{print $2}' | \
  grep -o '[A-Z][a-zA-Z]*View'
```

## 9. **SwiftUI Preview Providers**

Use preview providers to generate static diagrams:

```swift
struct NavigationDiagramProvider: PreviewProvider {
    static var previews: some View {
        NavigationGraphView(
            extractedFrom: Bundle.main
        )
    }
}
```

## 10. **Recommended Approach**

For your project, I recommend:

1. **Quick Solution**: Use SourceKitten + custom Python script
2. **Comprehensive**: Build a Swift package using SwiftSyntax
3. **Commercial**: Sherlock or Reveal for professional needs

### Example SourceKitten + Python approach:

```bash
#!/bin/bash
# extract_navigation.sh

# Extract all Swift files structure
find . -name "*.swift" -exec sourcekitten structure --file {} \; > structure.json

# Parse with Python
python3 parse_navigation.py structure.json > navigation_diagram.dot

# Generate image
dot -Tpng navigation_diagram.dot -o navigation_diagram.png
```

Would you like me to implement any of these solutions for your project?
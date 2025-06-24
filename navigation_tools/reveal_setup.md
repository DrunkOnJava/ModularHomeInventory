# Reveal Setup Guide for Navigation Analysis

## 1. Download and Install Reveal

1. Visit https://revealapp.com and download the latest version
2. They offer a 30-day free trial
3. Current pricing: $59-$199/year depending on team size

## 2. Integrate Reveal with Your App

### Method A: CocoaPods Integration
```ruby
# Add to your Podfile (Debug configuration only)
pod 'Reveal-SDK', :configurations => ['Debug']
```

### Method B: Swift Package Manager
```swift
// In Xcode: File > Add Package Dependencies
// URL: https://github.com/RevealApp/Reveal-SPM
// Add to Debug configuration only
```

### Method C: Manual Integration (Recommended for temporary use)
1. In Reveal app, go to Help > Show Reveal Library in Finder
2. Drag `RevealServer.xcframework` into your Xcode project
3. Set "Embed & Sign" for the framework
4. Add to Debug configuration only

## 3. Configure Your App

### SwiftUI App Configuration
```swift
// In your App file (HomeInventoryModularApp.swift)
#if DEBUG
import RevealServer
#endif

@main
struct HomeInventoryModularApp: App {
    init() {
        #if DEBUG
        if NSClassFromString("IBARevealLoader") == nil {
            Bundle(path: "/Applications/Reveal.app/Contents/SharedSupport/iOS-Libraries/RevealServer.framework")?.load()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 4. Build and Run

1. Build your app in Debug configuration
2. Run on Simulator or Device
3. Open Reveal app on your Mac
4. Your app should appear in Reveal's device list

## 5. Inspecting Navigation

### View Hierarchy Features:
- **3D View**: Rotate and explore your view hierarchy in 3D
- **2D Outline**: See the complete view tree structure
- **Properties Inspector**: View all properties of selected views
- **Constraints Debugger**: Visualize Auto Layout constraints

### Navigation Analysis Steps:
1. Navigate through your app while Reveal is connected
2. Use Reveal's snapshot feature to capture different navigation states
3. Export snapshots as images or data files
4. Compare navigation states across different screens

## 6. Exporting Navigation Data

### Export Options:
- **Screenshot**: File > Export > Screenshot
- **View Hierarchy**: File > Export > View Hierarchy (XML format)
- **Property List**: File > Export > Property List

### Automated Export Script:
```bash
# Use Reveal's command-line tools (if available)
reveal export --format=xml --output=navigation_state.xml
```

## 7. Best Practices for Navigation Analysis

1. **Capture Key States**: Take snapshots at each major navigation point
2. **Document Transitions**: Note the navigation method (push, modal, tab)
3. **Track View Controllers**: Identify the view controller hierarchy
4. **Export Regularly**: Save snapshots for documentation

## 8. Alternative: Using Xcode's View Debugger

If Reveal setup is complex, use Xcode's built-in debugger:
1. Run your app
2. Debug menu > View Debugging > Capture View Hierarchy
3. Export the captured hierarchy
4. Similar 3D inspection capabilities

## 9. Removing Reveal (After Analysis)

```bash
# Remove from Podfile or Package.swift
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/
```

## Note on SwiftUI Limitations

Reveal works best with UIKit. For SwiftUI:
- Some views may appear as `HostingView` containers
- Navigation structure might be less clear
- Consider combining with SwiftUI-specific tools
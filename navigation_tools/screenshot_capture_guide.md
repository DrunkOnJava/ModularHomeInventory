# SwiftUI View Screenshot Capture Guide

## Method 1: Automated UI Testing with Screenshots

### Create UI Test Target
```swift
// In your UI Test file
import XCTest

class ScreenshotUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app) // If using Fastlane Snapshot
        app.launch()
    }
    
    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        
        // Main tabs
        captureScreen("01_ItemsList")
        
        app.tabBars.buttons["Collections"].tap()
        captureScreen("02_Collections")
        
        app.tabBars.buttons["Analytics"].tap()
        captureScreen("03_Analytics")
        
        app.tabBars.buttons["Scanner"].tap()
        captureScreen("04_Scanner")
        
        app.tabBars.buttons["Settings"].tap()
        captureScreen("05_Settings")
        
        // Navigate to detail views
        app.tabBars.buttons["Items"].tap()
        if app.cells.firstMatch.exists {
            app.cells.firstMatch.tap()
            captureScreen("06_ItemDetail")
        }
    }
    
    func captureScreen(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

### Run UI Tests for Screenshots
```bash
# Run UI tests and save screenshots
xcodebuild test \
  -scheme "HomeInventoryModular" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath ./screenshots.xcresult

# Extract screenshots from result bundle
xcparse screenshots ./screenshots.xcresult ./exported_screenshots
```

## Method 2: SwiftUI Preview Screenshots

### Add Preview Provider with Screenshots
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 15 Pro", "iPad Pro"], id: \.self) { deviceName in
            ContentView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}

// Use Xcode's Preview Screenshot feature:
// 1. Open preview
// 2. Click camera icon in preview toolbar
// 3. Screenshots saved to Desktop
```

## Method 3: Fastlane Snapshot

### Install Fastlane
```bash
brew install fastlane
cd /Users/griffin/Projects/ModularHomeInventory
fastlane init
```

### Create Snapfile
```ruby
# Snapfile
devices([
  "iPhone 15 Pro",
  "iPhone 15 Pro Max",
  "iPad Pro (12.9-inch)"
])

languages([
  "en-US"
])

scheme("HomeInventoryModular")

clear_previous_screenshots(true)

# Where to save screenshots
output_directory("./screenshots")
```

### Create UI Test File
```swift
// SnapshotUITests.swift
import XCTest

class SnapshotUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testSnapshot() {
        let app = XCUIApplication()
        
        // Items List
        snapshot("01_ItemsList")
        
        // Collections
        app.tabBars.buttons["Collections"].tap()
        snapshot("02_Collections")
        
        // Analytics
        app.tabBars.buttons["Analytics"].tap()
        snapshot("03_Analytics")
        
        // Add more screens...
    }
}
```

### Run Fastlane Snapshot
```bash
fastlane snapshot
```

## Method 4: Manual Script with Simulator

### Create Screenshot Script
```bash
#!/bin/bash
# capture_screenshots.sh

DEVICE="iPhone 15 Pro"
SCHEME="HomeInventoryModular"

# Build and install app
xcodebuild -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  build

# Launch simulator
open -a Simulator

# Wait for simulator to boot
sleep 5

# Launch app
xcrun simctl launch booted com.yourcompany.homeinventory

# Function to take screenshot
take_screenshot() {
    local name=$1
    xcrun simctl io booted screenshot "$name.png"
    echo "Captured: $name.png"
}

# Navigate and capture
echo "Starting screenshot capture..."

# Main screen
sleep 2
take_screenshot "01_ItemsList"

# Use accessibility identifiers to navigate
# This requires adding identifiers to your SwiftUI views
```

## Method 5: SwiftUI View Extension

### Add Screenshot Capability to Views
```swift
import SwiftUI

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// Usage in previews or tests
struct ScreenshotGenerator {
    static func generateAllScreenshots() {
        let itemsList = ItemsListView().snapshot()
        save(itemsList, as: "ItemsList")
        
        let collections = CollectionsListView().snapshot()
        save(collections, as: "Collections")
        
        // Continue for all views...
    }
    
    static func save(_ image: UIImage, as name: String) {
        if let data = image.pngData() {
            let url = FileManager.default.urls(for: .documentDirectory, 
                                             in: .userDomainMask)[0]
                .appendingPathComponent("\(name).png")
            try? data.write(to: url)
        }
    }
}
```

## Method 6: Using xcparse (Recommended)

### Install xcparse
```bash
brew install xcparse
```

### Create Comprehensive UI Test
```swift
class ScreenshotCaptureTests: XCTestCase {
    
    func testCaptureAllViews() {
        let app = XCUIApplication()
        app.launch()
        
        // Create a navigation map
        let screens = [
            ("Items", "Items Tab"),
            ("Collections", "Collections Tab"),
            ("Analytics", "Analytics Tab"),
            ("Scanner", "Scanner Tab"),
            ("Settings", "Settings Tab")
        ]
        
        for (identifier, name) in screens {
            if app.tabBars.buttons[identifier].exists {
                app.tabBars.buttons[identifier].tap()
                captureScreen(name)
                
                // Capture any modal presentations
                captureModals(for: identifier)
            }
        }
    }
    
    func captureModals(for tab: String) {
        let app = XCUIApplication()
        
        switch tab {
        case "Items":
            // Try to open add item
            if app.navigationBars.buttons["Add"].exists {
                app.navigationBars.buttons["Add"].tap()
                captureScreen("\(tab)_AddItem")
                app.navigationBars.buttons["Cancel"].tap()
            }
        default:
            break
        }
    }
}
```

### Extract Screenshots
```bash
# Run tests
xcodebuild test \
  -scheme HomeInventoryModular \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -resultBundlePath screenshots.xcresult

# Extract all screenshots
xcparse screenshots screenshots.xcresult ./screenshot_output
```

## Quick Start Recommendation

For your project, I recommend:

1. **Fastlane Snapshot** for automated multi-device screenshots
2. **UI Tests with xcparse** for single device comprehensive capture
3. **Manual Xcode Previews** for quick individual view screenshots

Would you like me to set up one of these methods for your project?
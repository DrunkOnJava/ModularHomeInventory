# Screenshot Generation Guide

This project uses a hybrid approach for screenshot generation, combining fast component screenshots with comprehensive UI flow captures.

## Quick Start

Generate all screenshots with a single command:

```bash
make screenshots
# or
make ss
```

## Available Commands

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make screenshots` | Generate all screenshots (components + UI flow + App Store) |
| `make screenshots-components` | Generate only component screenshots using ImageRenderer |
| `make screenshots-ui` | Generate only UI flow screenshots using XCUITest |
| `make screenshots-clean` | Clean all screenshot directories |

### Shortcuts

- `make ss` - All screenshots
- `make ssc` - Component screenshots only
- `make ssu` - UI flow screenshots only
- `make ssa` - All screenshots (same as `ss`)
- `make ssx` - Clean screenshots

### Fastlane Commands

```bash
# Generate App Store formatted screenshots
bundle exec fastlane screenshots

# Clean screenshot directories
bundle exec fastlane clear_screenshots
```

## Screenshot Types

### 1. Component Screenshots (ImageRenderer)

Fast, isolated screenshots of individual UI components:
- Item cards
- Detail headers
- Settings sections
- Empty states
- Statistics cards

**Location**: `Screenshots/Components/`

### 2. UI Flow Screenshots (XCUITest)

Full app navigation screenshots:
- Items list
- Add item screen
- Barcode scanner
- Receipts
- Analytics
- Settings screens
- Premium features

**Location**: `Screenshots/AppFlow/`

### 3. App Store Screenshots (Fastlane)

Device-specific screenshots formatted for App Store submission:
- iPhone 16 Pro Max (6.9")
- iPhone 16 Pro (6.3")
- iPhone 16 (6.1")
- iPad Pro 13" (M4)
- iPad Pro 11" (M4)

**Location**: `Screenshots/AppStore/` and `fastlane/screenshots/`

## Implementation Details

### Component Tests

Located in `HomeInventoryModularTests/ViewScreenshotTests.swift`

```swift
@MainActor
func testItemCardScreenshot() throws {
    let mockItem = Item(...)
    let itemCard = ItemCard(item: mockItem)
    try captureScreenshot(of: itemCard, named: "ItemCard")
}
```

### UI Flow Tests

Located in `HomeInventoryModularUITests/HomeInventoryModularUITests.swift`

```swift
func testTakeScreenshots() throws {
    captureScreenshot(named: "01_ItemsList", directory: screenshotDir)
    navigateToTab("Scanner")
    captureScreenshot(named: "03_BarcodeScanner", directory: screenshotDir)
}
```

## Adding New Screenshots

### For a New Component

1. Add a test method to `ViewScreenshotTests.swift`
2. Create your SwiftUI view
3. Use `captureScreenshot(of:named:)` helper

### For a New UI Flow

1. Add navigation logic to `HomeInventoryModularUITests.swift`
2. Use `captureScreenshot(named:directory:)` helper
3. Consider adding accessibility identifiers for reliable element selection

## Best Practices

1. **Use Mock Data**: Create realistic mock data for components
2. **Consistent Naming**: Follow the naming pattern (01_ScreenName, 02_ScreenName)
3. **Wait for UI**: Use `waitForExistence` and `sleep()` appropriately
4. **Accessibility IDs**: Add identifiers to UI elements for reliable testing
5. **Clean State**: Start each test with a clean app state

## Troubleshooting

### Screenshots Not Appearing

1. Check simulator is booted: `xcrun simctl list devices`
2. Verify build succeeded: `make build`
3. Check console output for errors
4. Look in alternate locations:
   - `~/Documents/ComponentScreenshots/`
   - `~/Documents/UITestScreenshots/`
   - Test results in Xcode

### Test Failures

1. Update simulator device IDs in Makefile if needed
2. Ensure all dependencies are installed: `make install-deps`
3. Clean and rebuild: `make clean build`
4. Check for UI changes that may have broken selectors

### Performance Issues

- Component tests should run in < 10 seconds
- UI tests may take 2-3 minutes
- Use `make ssc` for quick component-only captures
- Disable animations in tests for speed

## CI/CD Integration

Add to your CI workflow:

```yaml
- name: Generate Screenshots
  run: make screenshots-all
  
- name: Upload Screenshots
  uses: actions/upload-artifact@v3
  with:
    name: screenshots
    path: Screenshots/
```
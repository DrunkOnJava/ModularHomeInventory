# Screenshot Automation Guide

## Overview
This guide covers the automated screenshot generation system for capturing all app views across multiple devices for App Store submission.

## Quick Start

### 1. Run Automated Screenshots
```bash
# Capture screenshots for all devices and views
./scripts/capture_all_screenshots.sh
```

### 2. Using Fastlane Directly
```bash
# Initialize snapshot (only needed once)
bundle exec fastlane snapshot init

# Run snapshot
bundle exec fastlane snapshot
```

## Configuration Files

### Snapfile
Located at `fastlane/Snapfile`, configures:
- Target devices (iPhone & iPad)
- Languages
- Output directory
- UI test scheme

### UI Test Files
- `HomeInventoryModularUITests/HomeInventoryModularUITests.swift` - Main test runner
- `HomeInventoryModularUITests/ScreenshotTests.swift` - Comprehensive screenshot tests
- `HomeInventoryModularUITests/SnapshotHelper.swift` - Fastlane helper

## Screenshots Captured

### Main Views (All Devices)
1. **Items List** - Main inventory view
2. **Item Detail** - Detailed item information
3. **Add Item** - Item creation screen
4. **Barcode Scanner** - Scanning interface
5. **Analytics Dashboard** - Overview of insights
6. **Spending Dashboard** - Financial analytics
7. **Purchase Patterns** - Buying behavior analysis
8. **Depreciation Report** - Asset value tracking
9. **Collections** - Organized groups
10. **Collection Detail** - Items in collection

### Feature Views
11. **Budget Dashboard** - Budget tracking
12. **Add Budget** - Budget creation
13. **Insurance Dashboard** - Coverage overview
14. **Claim Assistance** - Filing claims
15. **Warranty List** - Active warranties
16. **Warranty Detail** - Warranty information
17. **Search View** - Search interface
18. **Search Results** - Filtered items
19. **Settings** - App preferences
20. **Category Management** - Organize categories
21. **Export Data** - Data export options
22. **Documents Dashboard** - Document storage

### iPad-Specific Views
23. **Split View** - Multi-pane layout
24. **Detail View** - Large screen optimization
25. **Context Menu** - Right-click actions

## Device Requirements

### iPhone Sizes
- **iPhone 16 Pro Max** (6.9") - Required
- **iPhone 15 Pro** (6.1") - Recommended
- **iPhone SE** (4.7") - Small screen

### iPad Sizes
- **iPad Pro 12.9"** - Large iPad
- **iPad Pro 11"** - Standard iPad

## Customization

### Adding More Screenshots
Edit `ScreenshotTests.swift` to add new screenshot captures:

```swift
func captureCustomView() {
    // Navigate to view
    app.buttons["CustomButton"].tap()
    sleep(1)
    
    // Capture screenshot
    snapshot("26_CustomView")
}
```

### Adding Languages
Edit `Snapfile` to add more languages:

```ruby
languages([
  "en-US",    # English
  "es-ES",    # Spanish
  "fr-FR",    # French
  "de-DE",    # German
  "ja"        # Japanese
])
```

### Mock Data Configuration
The app launches with these arguments for screenshots:
- `-FASTLANE_SNAPSHOT` - Enables snapshot mode
- `-DisableAnimations` - Disables animations
- `-MockDataEnabled` - Uses mock data

## Troubleshooting

### Screenshots Not Appearing
1. Ensure UI tests build successfully
2. Check that `SnapshotHelper.swift` is included in test target
3. Verify simulators are installed for target devices

### Build Errors
```bash
# Clean and rebuild
make clean
make build

# Build UI tests specifically
xcodebuild build-for-testing \
  -workspace HomeInventoryModular.xcworkspace \
  -scheme HomeInventoryModular \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"
```

### Simulator Issues
```bash
# Reset simulators
xcrun simctl shutdown all
xcrun simctl erase all

# Boot specific simulator
xcrun simctl boot "iPhone 16 Pro Max"
```

## Output Structure

Screenshots are saved in:
```
fastlane/screenshots/
├── en-US/
│   ├── iPhone 16 Pro Max/
│   │   ├── 01_ItemsList.png
│   │   ├── 02_ItemDetail.png
│   │   └── ...
│   ├── iPad Pro 12.9-inch/
│   │   └── ...
└── screenshots.html (Preview)

AppStoreAssets/Screenshots/
├── iPhone-6.9/
├── iPhone-6.1/
├── iPhone-4.7/
├── iPad-12.9/
└── iPad-11/
```

## Best Practices

### Screenshot Quality
1. Use mock data that looks realistic
2. Show variety in content (different categories, prices)
3. Highlight key features prominently
4. Ensure text is readable at all sizes

### App Store Requirements
- At least one screenshot per device family
- Maximum 10 screenshots per size
- PNG or JPEG format
- No alpha channel
- sRGB color space

### Naming Convention
Use descriptive names with numbers for ordering:
- `01_MainScreen`
- `02_KeyFeature`
- `03_UniqueValue`

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Capture Screenshots
  run: |
    bundle install
    bundle exec fastlane snapshot
```

### Local Development
```bash
# Quick test on one device
bundle exec fastlane snapshot \
  --devices "iPhone 16 Pro Max" \
  --languages "en-US"
```

## Next Steps

After capturing screenshots:
1. Review in `fastlane/screenshots/screenshots.html`
2. Edit/enhance in image editor if needed
3. Add device frames using `fastlane frameit`
4. Upload to App Store Connect
5. Add localized captions for each screenshot

## Support

For issues:
- Check `fastlane/test_output/` for logs
- Review Xcode console for UI test failures
- Ensure all dependencies are up to date
# Screenshot Generation System

## Overview

The Home Inventory app uses a comprehensive dual-approach screenshot generation system that combines:
1. **ImageRenderer** for fast component screenshots
2. **XCUITest** for full app flow screenshots
3. **Fastlane Snapshot** for App Store screenshots

## Current Status

✅ **Infrastructure Complete**
- Test targets added via Ruby scripts
- Makefile commands configured
- Placeholder image generator working
- All directories structured properly

⚠️ **Pending**
- ViewScreenshotTests.swift needs proper imports from app modules
- UI tests need to be run with actual app data

## Generated Screenshots

### Component Screenshots (350x150 to 400x300)
- `ItemCard.png` - Individual item card display
- `EmptyState.png` - Empty state placeholder
- `ItemsList.png` - List of multiple items
- `StatsCard.png` - Statistics card
- `SettingsSection.png` - Settings section view
- `DetailHeader.png` - Item detail header

### App Flow Screenshots (393x852 - iPhone)
- `01_ItemsList.png` - Main items list
- `02_AddItem.png` - Add item screen
- `03_BarcodeScanner.png` - Barcode scanner
- `04_ItemDetail.png` - Item detail view
- `05_Receipts.png` - Receipts screen
- `06_Analytics.png` - Analytics dashboard
- `07_Settings.png` - Settings screen
- `08_Premium.png` - Premium features

### App Store Screenshots
- **iPhone 16 Pro Max** (430x932)
- **iPhone 16 Pro** (393x852)
- **iPad Pro 13"** (1024x1366)

## Commands

```bash
# Generate all screenshots
make screenshots
# or
make ss

# Component screenshots only
make screenshots-components
# or
make ssc

# UI flow screenshots only
make screenshots-ui
# or
make ssu

# Clean screenshots
make screenshots-clean
# or
make ssx
```

## Implementation Details

### Ruby Scripts
- `add_test_target.rb` - Adds unit test target to Xcode project
- `update_scheme.rb` - Updates scheme to include test targets
- `fix_test_target_path.rb` - Fixes file path issues

### Swift Scripts
- `generate_real_screenshots_simple.swift` - Creates placeholder PNG images with actual visual content

### Test Files
- `ViewScreenshotTests.swift` - Component screenshot tests (needs module imports)
- `HomeInventoryModularUITests.swift` - UI flow screenshot tests

## Next Steps

To generate real app screenshots:

1. **Fix Component Tests**
   ```swift
   // Add to ViewScreenshotTests.swift
   import Core
   import SharedUI
   import Items
   ```

2. **Run with Live App**
   ```bash
   make build
   make screenshots
   ```

3. **Review Output**
   - Check `Screenshots/` directory
   - Verify all images have content
   - Review for App Store compliance

## Troubleshooting

### Zero-byte PNG files
- Use `swift scripts/generate_real_screenshots_simple.swift` to regenerate

### Test compilation errors
- Ensure all SPM modules are built first with `make prebuild-modules`
- Check that test target has proper dependencies

### UI test failures
- Verify simulator is booted
- Check bundle ID matches: `com.homeinventory.app`
- Ensure app is installed on simulator

## Technical Architecture

The system uses:
- **CoreGraphics** for image generation
- **XCTest** for UI automation
- **Fastlane Snapshot** for device management
- **Ruby xcodeproj** for project configuration

All screenshots are generated at appropriate resolutions with proper color profiles for App Store submission.
# Screenshot Capture System Usage

## Setup Complete ✅

- **xcparse** installed via Homebrew
- **UI Test file** created at `HomeInventoryModularUITests/ScreenshotCaptureTests.swift`
- **Capture script** ready at `navigation_tools/capture_all_screenshots.sh`

## Quick Start

### 1. Capture All Screenshots (All Devices)
```bash
./navigation_tools/capture_all_screenshots.sh
```

### 2. Capture for Specific Device
```bash
./navigation_tools/capture_all_screenshots.sh --device "iPhone 15 Pro"
```

### 3. View Results
Open the generated HTML gallery:
```bash
open screenshots_output/gallery.html
```

## What Gets Captured

### Main Screens
- All 5 main tabs (Items, Collections, Analytics, Scanner, Settings)
- iPad sidebar navigation

### Items Module
- Items list view
- Add item form
- Item detail view
- Edit item form
- Filters view
- Search interface

### Collections Module
- Collections list
- Add collection form
- Collection detail view

### Analytics Module
- Main dashboard
- Category analytics
- Retailer analytics
- Time-based analytics
- Purchase patterns

### Scanner Module
- Main scanner view
- Different scanner tabs (Barcode, Batch, History)

### Settings Module
- Main settings
- All sub-settings screens:
  - Notifications
  - Spotlight
  - Accessibility
  - Scanner Settings
  - Biometric
  - Privacy
  - Export Data
  - Sync Status

## Output Structure

```
screenshots_output/
├── iPhone_15_Pro/
│   ├── 01_MainScreen_ItemsList.png
│   ├── 02_MainScreen_Collections.png
│   └── ...
├── iPhone_15_Pro_Max/
│   └── ... (same screenshots)
├── iPad_Pro_13-inch_M4/
│   └── ... (iPad-specific screenshots)
├── organized/
│   ├── by_screen/
│   │   ├── MainScreen_ItemsList/
│   │   └── MainScreen_Collections/
│   └── by_device/
│       ├── iPhone_15_Pro/
│       └── iPad_Pro_13-inch_M4/
└── gallery.html
```

## Troubleshooting

### If tests fail but you still want screenshots:
The script continues even if tests fail, so you'll still get partial screenshots.

### To run tests manually:
```bash
xcodebuild test \
  -scheme "HomeInventoryModular" \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
  -only-testing:"HomeInventoryModularUITests/ScreenshotCaptureTests" \
  -resultBundlePath screenshots.xcresult
```

### To extract screenshots manually:
```bash
xcparse screenshots screenshots.xcresult ./manual_screenshots
```

## Customizing Screenshots

Edit `ScreenshotCaptureTests.swift` to:
- Add more screens
- Change navigation paths
- Add wait times for animations
- Capture specific states (with data, empty states, etc.)

## Tips

1. **Run on a clean simulator** for consistent screenshots
2. **Close other apps** to ensure simulator performance
3. **Use specific device** option for faster capture during development
4. **Check the HTML gallery** for easy browsing of all screenshots
5. **Screenshots are numbered** for easy ordering (01_, 02_, etc.)

## Next Steps

After capturing screenshots, you can:
1. Use them for documentation
2. Create a visual site map
3. Include in app store submissions
4. Use for UI/UX reviews
5. Generate navigation diagrams based on actual screens
# SwiftUI Component Snapshot Tests Overview

## 📸 What Are Snapshot Tests?

Snapshot tests capture visual screenshots of your UI components and compare them against baseline images to detect unintended visual changes. The Home Inventory app has snapshot tests configured for all major UI components.

## 🎨 Components with Snapshot Tests

### 1. **PrimaryButton** (`SharedUI/Components/PrimaryButton.swift`)
- **Default State**: Blue button with white text
- **Loading State**: Shows progress indicator + text
- **Disabled State**: Grayed out appearance
- **Test File**: `HomeInventoryModularTests/SharedUI/PrimaryButtonSnapshotTests.swift`

### 2. **LoadingOverlay** (`SharedUI/Views/LoadingOverlay.swift`)
- **Default Message**: "Loading..." with spinner
- **Custom Messages**: "Scanning barcode...", "Saving changes..."
- **Dark Background**: Semi-transparent overlay
- **Test File**: `HomeInventoryModularTests/SharedUI/LoadingOverlaySnapshotTests.swift`

### 3. **SearchBar** (`SharedUI/Components/SearchBar.swift`)
- **Empty State**: Placeholder text visible
- **With Text**: Shows clear button
- **With Filters**: Filter chips displayed
- **Test File**: `HomeInventoryModularTests/SharedUI/SearchBarSnapshotTests.swift`

### 4. **ItemCard** (Product Display Cards)
- **Standard Layout**: Image, title, price, category
- **Long Text**: Text truncation handling
- **Various States**: New, on sale, out of stock
- **Test File**: `HomeInventoryModularTests/ItemCardSnapshotTests.swift`

### 5. **Full Screens**
- **ItemsListView**: Main inventory grid/list
- **ItemDetailView**: Product detail screen
- **AddItemView**: Add new item form
- **SettingsView**: App settings
- **ScannerView**: Barcode scanner UI
- **ReceiptsView**: Receipt management

## 🌓 Test Configurations

Each component is tested in:
- ☀️ **Light Mode**
- 🌙 **Dark Mode**
- 📱 **iPhone** (various models)
- 📱 **iPad** (different sizes)
- 🔍 **Accessibility Text Sizes**

## 📁 Snapshot File Structure

```
HomeInventoryModularTests/
├── __Snapshots__/
│   ├── PrimaryButtonSnapshotTests/
│   │   ├── testPrimaryButton_Default.png
│   │   ├── testPrimaryButton_Loading.png
│   │   ├── testPrimaryButton_Disabled.png
│   │   ├── testPrimaryButton_Default_dark.png
│   │   └── ...
│   ├── LoadingOverlaySnapshotTests/
│   │   ├── testLoadingOverlay_Default.png
│   │   ├── testLoadingOverlay_WithMessage.png
│   │   └── ...
│   └── ...
```

## 🔧 Current Status

The snapshot tests are configured but need compilation fixes before they can generate the actual PNG files. Once fixed, running `make record-snapshots` will:

1. Launch the iOS Simulator
2. Render each component
3. Capture PNG screenshots
4. Save them in `__Snapshots__` directories

## 🚀 Benefits

- **Visual Regression Testing**: Catch unintended UI changes
- **Design Documentation**: Visual record of all components
- **Cross-Device Testing**: Ensure consistency across devices
- **Accessibility Testing**: Verify UI works with large text
- **Dark Mode Support**: Test both appearance modes

## 💡 Usage

```bash
# Record new baseline snapshots
make record-snapshots

# Run tests against existing snapshots
make test-snapshots

# View snapshot differences (if tests fail)
# Snapshots are compared pixel-by-pixel
```

The snapshot testing infrastructure uses the `swift-snapshot-testing` library from Point-Free, providing powerful visual regression testing capabilities for the SwiftUI components.
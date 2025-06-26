# Snapshot Testing Guide

This project uses [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) from Point-Free for visual regression testing of UI components.

## Overview

Snapshot tests capture the visual appearance of views and compare them against reference images. This helps catch unintended UI changes and ensures consistency across different configurations.

## Running Snapshot Tests

### Run All Snapshot Tests
```bash
make test-snapshots
# or
make ts
```

### Record New Snapshots
```bash
make record-snapshots
# or
make rs
```

### Clean Old Snapshots
```bash
make clean-snapshots
```

## Writing Snapshot Tests

### Basic Example

```swift
import XCTest
import SnapshotTesting
import SwiftUI
@testable import SharedUI

final class MyViewSnapshotTests: SnapshotTestCase {
    
    func testMyView() {
        let view = MyView()
        assertSnapshot(matching: view, as: .image)
    }
}
```

### Using Helper Methods

The `SnapshotTestCase` base class provides helpful methods:

```swift
// Test in both light and dark modes
assertSnapshotInBothModes(matching: view)

// Test on all device sizes
assertSnapshotOnAllDevices(matching: view)

// Test accessibility configurations
assertAccessibilitySnapshots(matching: view)
```

## Test Organization

```
HomeInventoryModularTests/
├── SnapshotTestCase.swift           # Base class with helpers
├── SnapshotTestingConfiguration.swift # Global configuration
├── SharedUI/                        # SharedUI component tests
│   ├── PrimaryButtonSnapshotTests.swift
│   ├── SearchBarSnapshotTests.swift
│   └── LoadingOverlaySnapshotTests.swift
├── Items/                           # Items module tests
│   ├── ItemsListViewSnapshotTests.swift
│   └── AddItemViewSnapshotTests.swift
├── Settings/                        # Settings module tests
│   └── SettingsViewSnapshotTests.swift
├── Scanner/                         # Scanner module tests
│   └── ScannerViewSnapshotTests.swift
├── Receipts/                        # Receipts module tests
│   └── ReceiptsViewSnapshotTests.swift
└── Accessibility/                   # Accessibility-focused tests
    └── AccessibilitySnapshotTests.swift
```

## Best Practices

### 1. Test Multiple Configurations
Always test views in different configurations:
- Light and dark modes
- Different device sizes (iPhone, iPad)
- Various text sizes for Dynamic Type
- Different orientations when relevant

### 2. Use Consistent Frame Sizes
When testing components, use consistent frame sizes:
```swift
let view = MyComponent()
    .frame(width: 350)  // Standard width for component tests
    .padding()
```

### 3. Test Real Data
Use realistic sample data that represents actual use cases:
```swift
extension Item {
    static var sample: Item { /* ... */ }
    static var sampleMinimal: Item { /* ... */ }
    static var sampleComplete: Item { /* ... */ }
}
```

### 4. Name Tests Clearly
Use descriptive test names that indicate what's being tested:
- `testItemCard_Standard`
- `testItemCard_DarkMode`
- `testItemCard_NoPhoto`
- `testItemCard_LongName`

### 5. Handle Async Content
For views with async content, ensure data is loaded before snapshotting:
```swift
func testAsyncView() {
    let expectation = expectation(description: "View loaded")
    let view = AsyncView()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
        }
    
    wait(for: [expectation], timeout: 1.0)
    assertSnapshot(matching: view, as: .image)
}
```

## Recording New Snapshots

### Method 1: Environment Variable (Recommended)
1. Open Xcode
2. Edit the `HomeInventoryModularTests` scheme
3. Go to Test > Arguments > Environment Variables
4. Add `RECORD_SNAPSHOTS = true`
5. Run tests
6. Remove or set to `false` when done

### Method 2: Code Modification
Temporarily set `isRecording = true` in your test:
```swift
override func setUp() {
    super.setUp()
    isRecording = true  // Remember to remove this!
}
```

### Method 3: Command Line
```bash
make record-snapshots
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Snapshot Tests
  run: make test-snapshots
  
- name: Upload Failed Snapshots
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: failed-snapshots
    path: |
      **/__Snapshots__/
      **/FailureDiffs/
```

## Troubleshooting

### Snapshots Failing on CI
- Ensure CI uses the same Xcode version as development
- Check that simulator versions match
- Consider using more permissive precision: `.image(precision: 0.98)`

### Large Snapshot Files
- Snapshots are stored as PNGs in `__Snapshots__` directories
- Consider using Git LFS for snapshot files
- Regularly clean old snapshots with `make clean-snapshots`

### Flaky Tests
If tests are flaky due to animations or async content:
```swift
// Disable animations
UIView.setAnimationsEnabled(false)

// Wait for content
let view = MyView()
    .transaction { transaction in
        transaction.disablesAnimations = true
    }
```

## Advanced Usage

### Custom Snapshot Strategies
```swift
// Snapshot as JSON
assertSnapshot(matching: viewModel, as: .json)

// Snapshot with custom size
assertSnapshot(
    matching: view,
    as: .image(size: CGSize(width: 200, height: 100))
)

// Snapshot with traits
assertSnapshot(
    matching: view,
    as: .image(traits: .init(userInterfaceStyle: .dark))
)
```

### Perceptual Precision
For views with slight rendering differences:
```swift
assertSnapshot(
    matching: view,
    as: .image(precision: 0.98),  // 98% similarity required
    perceptualPrecision: 0.98      // Uses perceptual diff algorithm
)
```

## References

- [swift-snapshot-testing Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [Point-Free Episode on Snapshot Testing](https://www.pointfree.co/episodes/ep41-a-tour-of-snapshot-testing)
- [Advanced Snapshot Testing Strategies](https://www.pointfree.co/blog/posts/43-snapshot-testing-1-0-delightful-swift-testing)
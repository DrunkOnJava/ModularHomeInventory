# AppSettings Snapshot Tests

This directory contains snapshot tests for the AppSettings module using the swift-snapshot-testing library.

## Overview

Snapshot testing helps ensure UI consistency by capturing visual representations of views and comparing them against reference images. This is particularly useful for settings screens where layout and visual consistency are important.

## Test Files

- **SettingsSnapshotTests.swift**: Main snapshot tests for all settings views
- **SettingsComponentSnapshotTests.swift**: Tests for individual components and edge cases
- **SnapshotTestHelpers.swift**: Helper utilities and extensions for snapshot testing

## Running Tests

### From Xcode
1. Open the project in Xcode
2. Select the AppSettings scheme
3. Press `Cmd+U` to run all tests

### From Command Line
```bash
cd /Users/griffin/Projects/ModularHomeInventory/Modules/AppSettings
swift test
```

## Recording New Snapshots

To record new reference snapshots:

1. Set `isRecording = true` in the test's `setUp()` method
2. Run the tests
3. Review the generated snapshots in `__Snapshots__` directories
4. Set `isRecording = false` before committing

## Test Coverage

The snapshot tests cover:

### Views Tested
- EnhancedSettingsView (main settings screen)
- AboutView
- PrivacyPolicyView
- TermsOfServiceView
- NotificationSettingsView
- SyncSettingsView
- AccessibilitySettingsView
- BiometricSettingsView
- ScannerSettingsView
- CategoryManagementView
- ExportDataView
- And more...

### Test Scenarios
- Light and dark mode
- Different device sizes (iPhone, iPad)
- Accessibility text sizes
- RTL layouts
- Various toggle states
- Edge cases (long text, landscape orientation)

## Adding New Tests

When adding new settings views, create corresponding snapshot tests:

```swift
func testNewSettingsView() {
    let viewModel = SettingsViewModel()
    let view = NewSettingsView(viewModel: viewModel)
    
    // Use the helper method for standard configurations
    assertSettingsSnapshots(matching: view, named: "NewSettings")
    
    // Or test specific configurations
    assertSnapshot(
        matching: view,
        as: .image(on: .iPhone13ProMax),
        named: "NewSettings_iPhone"
    )
}
```

## Best Practices

1. **Naming**: Use descriptive names that include the device and configuration
2. **Coverage**: Test both light and dark modes for all views
3. **Accessibility**: Include tests with different text sizes
4. **States**: Test different states (enabled/disabled, empty/populated)
5. **Devices**: Test on at least iPhone and iPad configurations

## Troubleshooting

### Tests Failing
- Check if UI changes were intentional
- Review the failure diffs in Xcode
- Re-record snapshots if changes are expected

### Missing Snapshots
- Ensure `isRecording = true` when creating new tests
- Check that `__Snapshots__` directories are being created

### Performance
- Snapshot tests can be slow; consider using focused test runs during development
- Use `assertSettingsSnapshot` for single configurations to speed up tests

## Dependencies

The tests depend on:
- swift-snapshot-testing (1.15.0+)
- SwiftUI
- XCTest
- AppSettings module
- Core module  
- SharedUI module
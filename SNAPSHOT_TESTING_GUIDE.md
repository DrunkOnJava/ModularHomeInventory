# Home Inventory Snapshot Testing Guide

## Overview

This project uses snapshot testing to ensure UI consistency across all modules. Each module has its own dedicated snapshot tests that can be run individually or as a complete suite.

## Generated Snapshots

Successfully generated **42 snapshots** across **6 modules**:
- Items: 7 snapshots
- BarcodeScanner: 7 snapshots  
- Receipts: 7 snapshots
- AppSettings: 7 snapshots
- Premium: 7 snapshots
- Onboarding: 7 snapshots

## Running Snapshot Tests

### Interactive Menu
```bash
./scripts/run-snapshot-tests.sh
```

### Individual Module Tests
```bash
# Items module
./scripts/test-runners/test-items.sh

# BarcodeScanner module  
./scripts/test-runners/test-barcodescanner.sh

# Receipts module
./scripts/test-runners/test-receipts.sh

# AppSettings module
./scripts/test-runners/test-appsettings.sh

# Premium module
./scripts/test-runners/test-premium.sh

# Onboarding module
./scripts/test-runners/test-onboarding.sh
```

### Recording New Snapshots
To generate new baseline snapshots:
```bash
RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[module].sh
```

### Running All Tests
```bash
# Run all tests in verification mode
for script in scripts/test-runners/test-*.sh; do
  $script
done

# Record all new snapshots
for script in scripts/test-runners/test-*.sh; do
  RECORD_SNAPSHOTS=YES $script
done
```

## Test Structure

Each module test includes:
1. **Main View Test** - Tests the primary module UI on iPhone 13, iPhone 13 Pro Max, and iPad Pro 11"
2. **Dark Mode Test** - Tests the main view in dark mode
3. **Component Tests** - Tests individual components within each module

## File Locations

- **Test Files**: `HomeInventoryModularTests/IndividualTests/[Module]SnapshotTests.swift`
- **Snapshots**: `HomeInventoryModularTests/IndividualTests/__Snapshots__/[Module]SnapshotTests/`
- **Test Results**: `TestResults/[Module]/[Module].xcresult`

## Viewing Test Results

After running tests, you can view the results:
```bash
open TestResults/[Module]/[Module].xcresult
```

## Adding New Tests

To add snapshot tests for a new component:

1. Edit the appropriate module test file in `HomeInventoryModularTests/IndividualTests/`
2. Add a new test method following the existing pattern
3. Run with `RECORD_SNAPSHOTS=YES` to generate the baseline
4. Commit the new snapshot files to version control

## Troubleshooting

### Tests Failing After Code Changes
If tests fail after making UI changes:
1. Review the failures to ensure changes are intentional
2. If changes are correct, update snapshots: `RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[module].sh`
3. Review and commit the new snapshots

### Build Errors
If you encounter build errors:
1. Clean build folder: `xcodebuild clean`
2. Reset simulators: `xcrun simctl shutdown all && xcrun simctl erase all`
3. Re-run the tests

## Best Practices

1. **Review Changes**: Always review snapshot differences before updating baselines
2. **Consistent Environment**: Run tests on the same simulator versions for consistency
3. **Version Control**: Commit snapshot files to track UI changes over time
4. **CI Integration**: Include snapshot tests in your CI pipeline to catch regressions

## Module-Specific Notes

- **Items**: Tests inventory item cards and list views
- **BarcodeScanner**: Tests scanner UI and recent scans list
- **Receipts**: Tests receipt cards with attachments and metadata
- **AppSettings**: Tests settings menu with different sections
- **Premium**: Tests upgrade UI with feature list and pricing
- **Onboarding**: Tests welcome screens with pagination

## Implementation Details

The snapshot testing setup uses:
- **SnapshotTesting** library by Point-Free (v1.17.0)
- **Self-contained UI mocks** to avoid module dependencies
- **Multiple device configurations** for comprehensive testing
- **Ruby-based configuration** using Xcodeproj gem
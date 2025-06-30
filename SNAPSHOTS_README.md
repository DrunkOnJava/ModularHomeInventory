# Home Inventory Snapshot Testing System

## Overview

The Home Inventory app uses a comprehensive snapshot testing system powered by [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to ensure UI consistency across all features and prevent visual regressions. With 191 snapshots covering every major view in the app, we maintain high confidence in our UI quality.

## Architecture

### Directory Structure
```
HomeInventoryModularTests/
├── IndividualTests/          # Basic module tests (42 snapshots)
│   ├── __Snapshots__/
│   │   ├── ItemsSnapshotTests/
│   │   ├── BarcodeScannerSnapshotTests/
│   │   ├── ReceiptsSnapshotTests/
│   │   ├── AppSettingsSnapshotTests/
│   │   ├── PremiumSnapshotTests/
│   │   └── OnboardingSnapshotTests/
│   └── [Test files...]
├── EnhancedTests/           # Comprehensive feature tests (132 snapshots)
│   ├── __Snapshots__/
│   │   ├── ItemsDetailedSnapshotTests/
│   │   ├── SearchSnapshotTests/
│   │   ├── DataManagementSnapshotTests/
│   │   ├── SecuritySnapshotTests/
│   │   ├── GmailIntegrationSnapshotTests/
│   │   └── SyncSnapshotTests/
│   └── [Test files...]
└── SharedUI/                # Shared component tests (16 snapshots)
    └── __Snapshots__/
```

### Test Categories

#### 1. Individual Tests (Basic Modules)
- **Items**: Main inventory list, item cards, add item flow
- **BarcodeScanner**: Scanner UI, recent scans, product lookup
- **Receipts**: Receipt cards, attachments, metadata display
- **AppSettings**: Settings menu, preferences, account options
- **Premium**: Upgrade UI, feature comparison, pricing
- **Onboarding**: Welcome screens, feature tour, setup flow

#### 2. Enhanced Tests (Comprehensive Features)
- **ItemsDetailedSnapshotTests**:
  - Storage Units management
  - Collections organization
  - Warranty tracking dashboard
  - Budget monitoring
  - Analytics and insights
  - Insurance coverage tracking
  
- **SearchSnapshotTests**:
  - Natural language search
  - Image-based search
  - Barcode search integration
  - Saved searches management
  
- **DataManagementSnapshotTests**:
  - CSV import workflow
  - CSV export options
  - Backup management
  - Family sharing setup
  
- **SecuritySnapshotTests**:
  - Lock screen interfaces
  - Biometric authentication
  - Two-factor authentication
  - Privacy settings
  
- **GmailIntegrationSnapshotTests**:
  - Gmail receipt import
  - Import preview and parsing
  - Import history tracking
  
- **SyncSnapshotTests**:
  - Conflict resolution UI
  - Sync status monitoring
  - Collaborative lists

## Running Tests

### Interactive Menu
```bash
./scripts/run-snapshot-tests.sh
```

### Individual Test Runners
```bash
# Basic module tests
./scripts/test-runners/test-items.sh
./scripts/test-runners/test-barcodescanner.sh
./scripts/test-runners/test-receipts.sh
./scripts/test-runners/test-appsettings.sh
./scripts/test-runners/test-premium.sh
./scripts/test-runners/test-onboarding.sh

# Enhanced feature tests
./scripts/test-runners/test-itemsdetailed.sh
./scripts/test-runners/test-search.sh
./scripts/test-runners/test-datamanagement.sh
./scripts/test-runners/test-security.sh
./scripts/test-runners/test-gmailintegration.sh
./scripts/test-runners/test-sync.sh
```

### Recording New Snapshots
```bash
# Record snapshots for a specific test
RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[module].sh

# Record all snapshots
for script in scripts/test-runners/test-*.sh; do
  RECORD_SNAPSHOTS=YES $script
done
```

### Running All Tests
```bash
# Verify all snapshots
for script in scripts/test-runners/test-*.sh; do
  $script
done
```

## Test Implementation

### Creating New Snapshot Tests

1. **Basic Structure**:
```swift
import XCTest
import SnapshotTesting
import SwiftUI

final class MyFeatureSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Uncomment to record new snapshots
        // isRecording = true
    }
    
    func testMyFeatureView() {
        let view = createMyFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        // Test on multiple devices
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
}
```

2. **Mock UI Creation**:
```swift
private func createMyFeatureView() -> some View {
    NavigationView {
        VStack {
            // Create self-contained mock UI
            // Avoid dependencies on actual modules
        }
        .navigationTitle("My Feature")
    }
}
```

3. **Test Variants**:
- Main view (light mode, multiple devices)
- Dark mode variant
- Empty state
- Error states
- Loading states

### Best Practices

1. **Self-Contained Tests**: Create mock UIs within test files to avoid module dependencies
2. **Consistent Naming**: Follow the pattern `test[Feature]View[Variant]`
3. **Multiple Devices**: Test on iPhone 13, iPhone 13 Pro Max, and iPad Pro 11"
4. **Dark Mode**: Always include dark mode tests for main views
5. **Empty States**: Test how views look with no data

## Configuration

### Ruby Scripts

The project uses Ruby scripts with the Xcodeproj gem for test configuration:

- `create_snapshot_tests.rb`: Generates new snapshot test files
- `create_enhanced_snapshots.rb`: Creates comprehensive feature tests
- `fix_enhanced_test_paths.rb`: Fixes file path references in Xcode

### Test Runners

Each test group has a dedicated runner script in `scripts/test-runners/`:
- Configures proper test environment
- Sets up result bundle paths
- Provides snapshot counts
- Handles recording mode

## Troubleshooting

### Common Issues

1. **Tests Failing After UI Changes**:
   - Review the failure to ensure changes are intentional
   - Update snapshots: `RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[module].sh`
   - Commit the new snapshot files

2. **Build Errors**:
   ```bash
   # Clean build folder
   xcodebuild clean
   
   # Reset simulators
   xcrun simctl shutdown all
   xcrun simctl erase all
   ```

3. **File Path Issues**:
   - Run `ruby scripts/fix_enhanced_test_paths.rb` if tests can't find files
   - Ensure test files are properly added to the test target

4. **Missing Snapshots**:
   - Set `isRecording = true` in test setup
   - Or use `RECORD_SNAPSHOTS=YES` environment variable

### Viewing Results

```bash
# Open test results in Xcode
open TestResults/[Module]/[Module].xcresult

# View snapshots directly
open HomeInventoryModularTests/[TestGroup]/__Snapshots__/
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Snapshot Tests
  run: |
    for script in scripts/test-runners/test-*.sh; do
      if ! $script; then
        echo "Snapshot tests failed"
        exit 1
      fi
    done
```

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run snapshot tests for changed modules
changed_files=$(git diff --cached --name-only)
if echo "$changed_files" | grep -q "Modules/Items"; then
  ./scripts/test-runners/test-items.sh || exit 1
fi
```

## Maintenance

### Adding New Features

1. Create test file in appropriate directory
2. Add test runner script
3. Generate initial snapshots
4. Update this documentation

### Updating Snapshots

1. Make UI changes
2. Run tests to see failures
3. Verify changes are correct
4. Update snapshots with `RECORD_SNAPSHOTS=YES`
5. Review and commit new snapshots

### Snapshot Review Process

1. **Pull Request**: Include snapshot changes
2. **Review**: Visually inspect changed snapshots
3. **Approval**: Ensure UI changes match requirements
4. **Merge**: Commit updated snapshots

## Statistics

- **Total Snapshots**: 191
- **Basic Module Tests**: 42 snapshots
- **Enhanced Feature Tests**: 132 snapshots
- **Shared UI Tests**: 16 snapshots
- **Test Files**: 12 main test classes
- **Coverage**: All major app features and UI components

## Resources

- [swift-snapshot-testing Documentation](https://github.com/pointfreeco/swift-snapshot-testing)
- [SwiftUI Testing Best Practices](https://developer.apple.com/documentation/xctest)
- [Xcode Test Plans](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)

## Contributing

When adding new UI features:
1. Write snapshot tests before implementation
2. Use existing test patterns as templates
3. Ensure all device sizes are tested
4. Include dark mode variants
5. Document any special testing requirements
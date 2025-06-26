# Periphery - Dead Code Detection Setup

## Overview

Periphery is installed and configured for detecting unused code in the HomeInventoryModular project.

## Installation

Periphery is already installed via Homebrew:
```bash
brew install peripheryapp/periphery/periphery
```

## Configuration

The project includes a `.periphery.yml` configuration file with:
- Target configuration for all app and test targets
- Retention settings for public APIs, @objc code, and protocol conformances
- Exclusions for system entry points, test code, and generated files

## Usage

### Makefile Commands

```bash
# Basic dead code detection
make dc         # or make dead-code

# Aggressive detection (finds more potential dead code)
make dca        # or make dead-code-aggressive

# Generate reports in multiple formats
make dcr        # or make dead-code-report

# Interactive cleaning (shows results in Xcode format)
make dcc        # or make dead-code-clean

# Check dead code in specific modules
make dead-code-modules
```

### Direct Periphery Commands

```bash
# Basic scan
periphery scan

# Skip build (use existing index)
periphery scan --skip-build

# Different output formats
periphery scan --format csv > dead_code.csv
periphery scan --format json > dead_code.json
periphery scan --format markdown > dead_code.md
periphery scan --format xcode  # For Xcode integration
```

### Automated Analysis Script

Run the comprehensive dead code analysis:
```bash
ruby scripts/dead_code_check.rb
```

This generates:
- HTML visual report at `reports/dead_code/index.html`
- Markdown summary at `reports/dead_code/summary.md`
- Console output with statistics and recommendations

## Common Issues and Solutions

### 1. Build Errors
If Periphery fails due to build errors:
```bash
# First ensure the project builds
make build

# Then run Periphery
make dc
```

### 2. Index Store Issues
If you see "index store path does not exist":
```bash
# Build the project first to create the index
make build

# Or let Periphery build it
periphery scan --clean-build
```

### 3. False Positives
Common false positives are excluded in `.periphery.yml`:
- App entry points (`AppDelegate`, `ContentView`)
- Test code
- Module public APIs
- Preview providers
- Widget code

## Best Practices

1. **Regular Scans**: Run `make dc` before major releases
2. **Module Checks**: Use `make dead-code-modules` to check individual modules
3. **Review Before Deletion**: Always review results before removing code
4. **CI Integration**: Consider adding to CI pipeline for automated checks

## Interpreting Results

### Severity Levels
- **High** (Red): Classes, structs, enums, protocols
- **Medium** (Yellow): Functions, properties
- **Low** (Cyan): Enum cases, type aliases

### Report Sections
1. **Statistics**: Total unused items by type and module
2. **By Module**: Which modules have the most dead code
3. **Detailed Results**: Specific files and line numbers

## Excluding Code

To exclude specific code from detection:

1. **In Configuration** (`.periphery.yml`):
```yaml
report_exclude:
  - "MyExcludedClass"
  - "SomePattern.*"
```

2. **In Code**:
```swift
// periphery:ignore
class IntentionallyUnused { }
```

3. **For Entire Files**:
```swift
// periphery:ignore:all
```

## Next Steps

1. Review the initial scan results
2. Identify false positives and update exclusions
3. Create a plan to remove actual dead code
4. Set up regular scanning schedule
# Development Tools Guide

This guide covers all the development tools configured for the ModularHomeInventory project.

## Quick Start

```bash
# Install all tools
make install-all-tools

# Run pre-commit checks
make pre-commit

# Format and lint code
make format lint
```

## Available Tools

### Code Quality

#### SwiftLint
- **Purpose**: Enforces Swift style and conventions
- **Config**: `.swiftlint.yml`
- **Commands**:
  ```bash
  make lint        # Check code style
  make lint-fix    # Auto-fix issues
  make l          # Shortcut for lint
  make lf         # Shortcut for lint-fix
  ```

#### SwiftFormat
- **Purpose**: Automatically formats Swift code
- **Config**: `.swiftformat`
- **Commands**:
  ```bash
  make format     # Format all code
  make f          # Shortcut
  ```

#### Periphery
- **Purpose**: Detects unused code
- **Config**: `.periphery.yml`
- **Commands**:
  ```bash
  make dead-code           # Find unused code
  make dead-code-report    # Generate reports
  ```

### Code Generation

#### Sourcery
- **Purpose**: Meta-programming and code generation
- **Config**: `.sourcery.yml`
- **Commands**:
  ```bash
  make generate-mocks     # Generate mock classes
  make gm                # Shortcut
  ```
- **Templates**: Located in `Templates/` directory

### Testing

#### XCTestHTMLReport
- **Purpose**: Beautiful HTML test reports
- **Auto-generated**: After running tests
- **Commands**:
  ```bash
  make test              # Run tests and generate report
  make test-snapshots    # Run snapshot tests
  ```

#### Snapshot Testing
- **Purpose**: UI regression testing
- **Framework**: SnapshotTesting by Point-Free
- **Commands**:
  ```bash
  make test-snapshots     # Run snapshot tests
  make record-snapshots   # Record new snapshots
  make clean-snapshots    # Remove old snapshots
  ```

### Build & Deployment

#### Fastlane
- **Purpose**: Automated builds and deployment
- **Config**: `fastlane/Fastfile`
- **Commands**:
  ```bash
  make testflight        # Build and upload to TestFlight
  make archive           # Create archive only
  make validate-app      # Validate before submission
  ```

#### XcodeGen
- **Purpose**: Generate Xcode project from YAML
- **Config**: `project.yml`
- **Commands**:
  ```bash
  make generate          # Regenerate project file
  ```

### Documentation

#### Jazzy
- **Purpose**: Generate beautiful API documentation
- **Commands**:
  ```bash
  make docs             # Generate documentation
  make docs-open        # Generate and open in browser
  make d               # Shortcut for docs
  make do              # Shortcut for docs-open
  ```

### PR Automation

#### Danger
- **Purpose**: Automated PR reviews
- **Config**: `Dangerfile.swift`
- **Commands**:
  ```bash
  make danger-dry      # Test locally
  make danger-pr       # Run on PR (CI)
  ```
- **Features**:
  - PR size warnings
  - Test coverage checks
  - SwiftLint integration
  - Security checks
  - PR description validation

### Hot Reload & Live Development

#### InjectionIII
- **Purpose**: Hot reload for iOS development
- **Installation**: Mac App Store
- **Commands**:
  ```bash
  make injection-help  # Setup instructions
  make build run      # Build with injection support
  ```
- **Features**:
  - Instant code updates without rebuilding
  - Works with SwiftUI and UIKit
  - Simulator only

### Security & Secrets

#### Arkana
- **Purpose**: Encrypted secrets management
- **Config**: `.arkana.yml`
- **Commands**:
  ```bash
  make secrets-setup      # Initial setup
  make secrets-generate   # Generate encrypted secrets
  make sg                # Shortcut
  ```
- **Features**:
  - Encrypts API keys and secrets
  - Generates type-safe Swift code
  - Environment-specific secrets

### Release Automation

#### Rocket
- **Purpose**: Automated release process
- **Config**: `.rocket.yml`
- **Commands**:
  ```bash
  make release-patch     # Patch release (1.0.x)
  make release-minor     # Minor release (1.x.0)
  make release-major     # Major release (x.0.0)
  make release-dry       # Dry run
  make rp               # Shortcut for patch
  ```
- **Features**:
  - Automated version bumping
  - Changelog generation
  - Git tag management
  - TestFlight upload

### Architecture Visualization

#### SwiftPlantUML
- **Purpose**: Generate UML diagrams from Swift code
- **Config**: `.swiftplantuml.yml`
- **Commands**:
  ```bash
  make diagrams          # Generate all diagrams
  make diagrams-class    # Class diagrams only
  make diagrams-sequence # Sequence diagrams only
  make diagrams-open     # Generate and open
  make dg               # Shortcut for diagrams
  ```
- **Features**:
  - Automatic diagram generation
  - Multiple diagram types
  - Module visualization

### UI Debugging

#### Reveal
- **Purpose**: Runtime UI inspection
- **Documentation**: `docs/REVEAL_INTEGRATION.md`
- **Commands**:
  ```bash
  make reveal-build     # Build with Reveal
  make reveal          # Build and run with Reveal
  ```
- **Features**:
  - 3D view hierarchy
  - Performance analysis
  - Layout debugging
  - Runtime property editing

## Pre-commit Hooks

The project includes a pre-commit hook that automatically:
1. Runs SwiftLint
2. Formats code with SwiftFormat
3. Checks for TODOs/FIXMEs
4. Validates XcodeGen configuration

## CI/CD Integration

### GitHub Actions Workflows
- `component-snapshots.yml`: Runs snapshot tests
- `testflight.yml`: Builds and uploads to TestFlight
- `danger.yml`: Runs Danger on PRs

## Tool Installation

### Homebrew Tools
```bash
brew install swiftlint swiftformat periphery sourcery xcodegen xcbeautify xchtmlreport swiftplantuml
```

### Ruby Gems
```bash
bundle install  # Installs Fastlane, Danger, Jazzy, Arkana, Rocket, etc.
```

### Mac App Store
- **InjectionIII** - Hot reload for iOS development
- **Reveal** - UI debugging (from [revealapp.com](https://revealapp.com))

## Best Practices

1. **Before Committing**: Run `make pre-commit`
2. **Before PRs**: Run `make pre-merge`
3. **Regular Maintenance**: 
   - Run `make dead-code` weekly
   - Update snapshots when UI changes
   - Keep tools updated with `brew upgrade` and `bundle update`

## Troubleshooting

### SwiftLint Issues
- Check `.swiftlint.yml` for rule configurations
- Use `// swiftlint:disable rule_name` for specific exceptions

### Build Issues
- Run `make clean` to clear derived data
- Run `make fix-build` for common fixes
- Regenerate project with `make generate`

### Test Failures
- View HTML report at `index.html` after tests
- Update snapshots with `make record-snapshots` if UI changed

## Custom Scripts

Additional scripts in `scripts/`:
- `auto-commit.sh`: Auto-commits on successful build
- `pre_merge_checks.sh`: Comprehensive pre-merge validation
- Various TestFlight and signing scripts

## Environment Setup

For new developers:
1. Install Xcode
2. Run `make install-all-tools`
3. Run `make generate`
4. Open `HomeInventoryModular.xcodeproj`

## Contributing

When adding new tools:
1. Update this guide
2. Add to `Makefile`
3. Add to `install-all-tools` target
4. Update CI workflows if needed
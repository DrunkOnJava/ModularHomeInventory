# Home Inventory Modular

A comprehensive home inventory management app built with SwiftUI and modular architecture.

## Project Structure

```
.
├── Source/                 # Application source code
│   ├── App/               # App entry points (AppDelegate, etc.)
│   ├── Views/             # Main application views
│   └── iPad/              # iPad-specific features
├── Modules/               # Modular components
│   ├── Core/              # Core models and services
│   ├── Items/             # Item management
│   ├── BarcodeScanner/    # Barcode scanning
│   ├── AppSettings/       # Settings management
│   ├── Receipts/          # Receipt management
│   ├── SharedUI/          # Shared UI components
│   ├── Sync/              # Sync functionality
│   ├── Premium/           # Premium features
│   ├── Onboarding/        # Onboarding flow
│   └── Widgets/           # Home screen widgets
├── Supporting Files/      # Assets and resources
├── Config/                # Configuration files
├── scripts/               # Build and utility scripts
├── fastlane/              # Fastlane automation
├── docs/                  # Documentation
├── Build Archives/        # IPA and dSYM files
└── Test Results/          # Test result bundles
```

## Quick Start

```bash
# Install development tools
make install-all-tools

# Build and run
make build run

# Run tests
make test

# Lint and format code
make lint format
```

## Development Tools

This project uses a comprehensive suite of professional iOS development tools:

### Code Quality
- **SwiftLint** - Swift style and conventions enforcement
- **SwiftFormat** - Automatic code formatting
- **Periphery** - Dead code detection

### Testing
- **XCTestHTMLReport** - Beautiful test reports
- **SnapshotTesting** - UI regression testing
- **Quick/Nimble** - BDD testing framework

### Build & Deployment
- **Fastlane** - Automated builds and deployment
- **XcodeGen** - Project generation from YAML
- **xcbeautify** - Beautiful build output

### Documentation & Automation
- **Jazzy** - API documentation generation
- **Sourcery** - Code generation for mocks
- **Danger** - Automated PR reviews

### Essential Commands

```bash
# Code quality
make lint          # Check code style
make format        # Format code
make analyze       # Static analysis
make dead-code     # Find unused code

# Testing
make test          # Run all tests
make test-snapshots # Run snapshot tests

# Documentation
make docs          # Generate documentation
make docs-open     # Open docs in browser

# Build & Deploy
make testflight    # Upload to TestFlight
make pre-merge     # Pre-merge checks
```

See [TOOLS_GUIDE.md](TOOLS_GUIDE.md) for detailed documentation.

## Documentation

See the `docs/` directory for detailed documentation:
- [Modular Architecture Guide](docs/MODULAR_REBUILD_GUIDE.md)
- [Build Workflow](docs/MANDATORY_BUILD_WORKFLOW.md)
- [TODO List](docs/TODO.md)

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9 (DO NOT upgrade to Swift 6)

## License

Copyright © 2024. All rights reserved.
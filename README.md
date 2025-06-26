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
# Build and run
make build run

# Run tests
make test

# Lint code
make lint
```

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
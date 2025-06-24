# Modular Home Inventory

A modern iOS app for managing your home inventory with a modular architecture.

## Features

- 📦 **Item Management**: Track all your belongings with photos, receipts, and warranties
- 📊 **Analytics**: Spending insights, retailer analytics, and portfolio tracking  
- 🔍 **Smart Search**: Natural language search, barcode scanning, and fuzzy matching
- 📄 **Document Support**: Attach PDFs, receipts, manuals, and warranties
- 🏪 **Store Analytics**: Track spending by retailer with performance metrics
- 🔄 **Offline Support**: Queue scans and sync when connected
- 🎯 **Modular Architecture**: Clean separation of concerns with Swift Package Manager

## Quick Start

```bash
# Install dependencies
make install-deps

# Build and run
make br

# Build only
make build  # Note: Auto-commits on success by default!
```

## Auto-Commit Feature

**Builds automatically commit and push to GitHub by default!**

To build without auto-commit:
```bash
make build AUTO_COMMIT=false
```

See [docs/AUTO_COMMIT.md](docs/AUTO_COMMIT.md) for details.

## Development

### Requirements
- Xcode 15+
- iOS 17+
- Swift 5.9 (Important: Do not upgrade to Swift 6)

### Architecture
The app uses a modular architecture with separate packages:
- **Core**: Shared models, protocols, and services
- **Items**: Item management and analytics
- **Scanner**: Barcode scanning and OCR
- **Settings**: App configuration
- **Receipts**: Receipt scanning and management
- **SharedUI**: Reusable UI components
- **Premium**: In-app purchases
- **Sync**: Cloud synchronization
- **Onboarding**: First-time user experience

### Commands

```bash
make help         # Show all commands
make build        # Build the app (auto-commits by default)
make run          # Run in simulator
make test         # Run tests
make clean        # Clean build artifacts
make xcode        # Open in Xcode
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `make build` to test (will auto-commit)
5. Create a pull request

## License

This project is proprietary software. All rights reserved.
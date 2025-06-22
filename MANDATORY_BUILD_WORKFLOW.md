# 🚨 MANDATORY BUILD WORKFLOW 🚨
## HomeInventory Modular App - Command Line Build & Run

> **⚠️ CRITICAL: This is the REQUIRED workflow for building and running the app from command line!**

## Prerequisites

1. **Xcode** - Must have Xcode installed
2. **xcbeautify** - Install with: `brew install xcbeautify`
3. **xcodegen** - Install with: `brew install xcodegen`

## Quick Start

```bash
cd /Users/griffin/Projects/HomeInventory/ModularApp
make all  # Clean, build, and run in iPhone 16 Pro Max
```

## Available Commands

### Primary Commands
- `make build` - Build the app for simulator
- `make run` - Launch app in iPhone 16 Pro Max (requires successful build)
- `make all` - Clean, build, and run (recommended)
- `make clean` - Clean all build artifacts

### Additional Commands
- `make xcode` - Open project in Xcode
- `make test` - Run all tests
- `make generate` - Regenerate Xcode project from project.yml
- `make install-deps` - Install required dependencies

### Shortcuts
- `make b` - Shortcut for build
- `make r` - Shortcut for run
- `make br` - Build and run
- `make c` - Shortcut for clean

## Build Script Details

The project includes two build automation files:

### 1. Makefile (Recommended)
Located at: `/Users/griffin/Projects/HomeInventory/ModularApp/Makefile`

```bash
# Example usage:
make clean  # Clean previous builds
make build  # Build for simulator
make run    # Launch in simulator
```

### 2. build-and-run.sh
Located at: `/Users/griffin/Projects/HomeInventory/ModularApp/build-and-run.sh`

```bash
# Direct script usage:
./build-and-run.sh
```

## Simulator Configuration

**Default Simulator**: iPhone 16 Pro Max
- **Simulator ID**: DD192264-DFAA-4582-B2FE-D6FC444C9DDF
- **Bundle ID**: com.homeinventory.modular

To change the simulator, edit the `SIMULATOR_ID` in the Makefile.

## Build Process Flow

1. **Clean** (optional) - Removes all previous build artifacts
2. **Build** - Compiles all 9 modules and main app
3. **Boot Simulator** - Starts iPhone 16 Pro Max if not running
4. **Install** - Installs the app on simulator
5. **Launch** - Opens the app automatically

## Module Structure

The app consists of 9 modules that are built in dependency order:
1. Core - Foundation models and protocols
2. SharedUI - Design system and components
3. Items - Inventory management
4. Scanner - Barcode/document scanning
5. Settings - App configuration
6. Receipts - Receipt management
7. Sync - Cloud synchronization
8. Premium - Subscription features
9. Onboarding - First-time user experience

## Troubleshooting

### Build Fails
```bash
make clean  # Clean everything
make generate  # Regenerate project
make build  # Try building again
```

### Simulator Issues
```bash
# Reset simulator
xcrun simctl erase DD192264-DFAA-4582-B2FE-D6FC444C9DDF

# Boot simulator manually
xcrun simctl boot DD192264-DFAA-4582-B2FE-D6FC444C9DDF
```

### Module Errors
1. Check Swift version is 5.9 (NOT 6.0!)
2. Ensure all Package.swift files exist
3. Verify module dependencies in project.yml

## Important Notes

⚠️ **ALWAYS use this workflow for command-line builds!**
- Do NOT use `swift build` directly (it defaults to macOS)
- Do NOT use `xcodebuild` without proper destination
- Do NOT upgrade to Swift 6.0

✅ **Best Practices**:
- Always run `make clean` before important builds
- Use `make all` for a fresh build and run
- Check console output for launch confirmation

## Success Indicators

When successful, you'll see:
```
✅ App launched!
```

The app will automatically open in the iPhone 16 Pro Max simulator with the main tab bar showing:
- Items
- Scanner  
- Receipts
- Settings

## CI/CD Integration

For automated builds, use:
```bash
make clean build test
```

For deployment builds:
```bash
make clean
make build
# Archive and distribute...
```

---

**Remember**: This is the MANDATORY workflow. No exceptions! 🚀
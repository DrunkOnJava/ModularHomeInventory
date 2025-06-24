# ⚠️ CRITICAL: SWIFT 5.9 REQUIREMENT ⚠️

## THIS PROJECT MUST USE SWIFT 5.9 ONLY

## 🚨 MANDATORY BUILD WORKFLOW 🚨
**You MUST use the approved build process:**
```bash
cd ModularApp
make all  # This is the ONLY way to build and run!
```
**DO NOT use `swift build` or manual `xcodebuild` commands!**
See [docs/MANDATORY_BUILD_WORKFLOW.md](docs/MANDATORY_BUILD_WORKFLOW.md)

### DO NOT USE:
- ❌ Swift 6 features
- ❌ `any` keyword for protocol types
- ❌ Strict concurrency checking
- ❌ Swift 6 language mode

### DO USE:
- ✅ Swift 5.9 syntax
- ✅ Protocol types without `any` keyword
- ✅ @MainActor where needed
- ✅ Traditional protocol conformance

### Package.swift Requirements:
```swift
// swift-tools-version: 5.9  // NOT 6.0!
```

### Build Settings:
- SWIFT_VERSION = 5.9
- Do not enable Swift 6 language mode
- Do not enable strict concurrency checking

### This requirement applies to:
- All modules
- All Swift files
- All Package.swift files
- All build configurations
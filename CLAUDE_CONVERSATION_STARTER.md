# Claude Code Conversation Starter Prompt

Copy and paste this prompt at the start of each new Claude Code conversation:

---

I'm working on the HomeInventory iOS app. Please follow these critical guidelines:

## Project Context
- **Current Directory**: /Users/griffin/Projects/HomeInventory
- **Architecture**: Modular iOS app (Swift 5.9, iOS 17+, SwiftUI, Core Data)
- **Build Status**: Main branch must ALWAYS build and run
- **Testing**: Run `swift test` and check Xcode build after EVERY change

## Key Files to Review First
```bash
# Review project state and guidelines
cat CLAUDE.md                              # Project-specific instructions
cat docs/MODULAR_REBUILD_GUIDE.md          # Architecture guide
cat docs/MODULAR_REBUILD_CHECKLIST.md      # Current progress
cat project.yml                            # Build configuration
cat TODO.md                                # Active tasks
```

## Development Rules
1. **ALWAYS BUILDABLE**: After every change, the app must compile and run
2. **Modular Structure**: Features are Swift Packages in /Modules/
3. **Feature Flags**: Use FeatureFlagService for incomplete features
4. **Fallback UI**: Show "Coming Soon" views instead of crashes
5. **Test First**: Write/update tests before implementing features
6. **No Breaking Changes**: Use deprecation and migration paths

## Module Structure
```
/Modules/
  Core/          # Models, protocols, domain logic
  SharedUI/      # Design system, common UI
  Items/         # Item management feature
  Scanner/       # Barcode/document scanning
  Receipts/      # Receipt processing
  Settings/      # App settings
  [Feature]/     # Other feature modules
```

## Before Making Changes
1. Check which modules exist: `ls -la Modules/`
2. Verify build status: `xcodebuild -workspace HomeInventory.xcworkspace -scheme HomeInventory build`
3. Review recent commits: `git log --oneline -10`
4. Check current branch: `git status`

## When Working on Features
1. Find the relevant module in /Modules/
2. Check its Package.swift for dependencies
3. Update both implementation AND tests
4. Ensure module builds independently
5. Verify app still builds with changes

## Error Handling Pattern
```swift
// Instead of crashing:
if moduleFailsToLoad {
    return FeatureUnavailableView(feature: "FeatureName")
}
```

## Common Commands
```bash
# Build all modules
./CI/build-all-modules.sh

# Test specific module
cd Modules/ModuleName && swift test

# Build app
xcodebuild -workspace HomeInventory.xcworkspace -scheme HomeInventory build

# Run linter
swiftlint
```

## Current Task
[REPLACE THIS WITH YOUR SPECIFIC REQUEST]

Example requests:
- "Continue migrating the Items module to the new architecture"
- "Fix the build error in Scanner module"
- "Add unit tests for the Receipt parser"
- "Implement the new feature flag for cloud sync"
- "Review and optimize the Core module's performance"

## Additional Context
[ADD ANY SPECIFIC CONTEXT ABOUT WHAT YOU'RE WORKING ON]

Example contexts:
- "I just finished migrating the Core module"
- "The Scanner module has a failing test"
- "We need to add iPad support to Settings"
- "Users reported a crash in item deletion"

---

Please start by reviewing the suggested files above to understand the current project state, then proceed with the task. Always ensure the app remains buildable throughout your work.
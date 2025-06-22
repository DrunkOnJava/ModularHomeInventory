# Next Conversation Starting Prompt for HomeInventory Modular App

## CRITICAL CONTEXT - READ FIRST

### Current State (as of June 22, 2024)
- **Location**: We are working in `/Users/griffin/Projects/HomeInventory/ModularApp/` 
- **Progress**: 352/1000 tasks complete (see docs/MODULAR_REBUILD_CHECKLIST.md)
- **Modules Completed**: Core, SharedUI, Items, Scanner, Settings, Receipts, Sync, Premium, Onboarding
- **Next Module**: Analytics (Tasks 653-656) - NOT YET STARTED

### ⚠️ CRITICAL RULES TO PREVENT ISSUES

1. **ALWAYS work in the ModularApp directory**
   - ✅ CORRECT: `/Users/griffin/Projects/HomeInventory/ModularApp/Modules/`
   - ❌ WRONG: `/Users/griffin/Projects/HomeInventory/Modules/`

2. **ALWAYS use Swift 5.9**
   - The project is locked to Swift 5.9 for compatibility
   - Do NOT use Swift 6 features (like bare `any` keyword)
   - See SWIFT_VERSION_REQUIREMENT.md

3. **ALWAYS test builds with make commands**
   - Use `make build` to verify compilation
   - Use `make all` to build and launch in simulator
   - See docs/MANDATORY_BUILD_WORKFLOW.md

4. **ALWAYS check actual progress**
   - Refer to docs/MODULAR_REBUILD_CHECKLIST.md for task numbers
   - Update progress accurately after completing tasks
   - We are at task 352, NOT 600+

5. **ALWAYS follow the modular architecture**
   - Each module has: Package.swift, Sources/Public/API, Sources/Views, Tests
   - Modules depend only on Core and SharedUI
   - No circular dependencies

### Where to Start Development

1. **Read these files first:**
   - `/Users/griffin/Projects/HomeInventory/ModularApp/FIXES_NEEDED.md` - Shows what was fixed
   - `/Users/griffin/Projects/HomeInventory/docs/MODULAR_REBUILD_CHECKLIST.md` - Current progress
   - `/Users/griffin/Projects/HomeInventory/docs/MANDATORY_BUILD_WORKFLOW.md` - Build process

2. **Next Development Tasks:**
   - Analytics Module (Tasks 653-656) is next
   - OR continue with any incomplete features in existing modules
   - OR fix any Swift 6 migration warnings (while staying on Swift 5.9)

3. **Before Creating Any Module:**
   - Verify you're in ModularApp/Modules/ directory
   - Check the checklist for exact task requirements
   - Create Package.swift with Swift 5.9 tools version
   - Add module to project.yml before building

### Example First Commands
```bash
cd /Users/griffin/Projects/HomeInventory/ModularApp
make build  # Verify everything still builds
pwd         # Confirm you're in the right directory
```

### Key Project Files
- `project.yml` - Module references (auto-generates .xcodeproj)
- `Makefile` - Build commands
- Each module's `Package.swift` - Module configuration

Remember: The goal is always-buildable, modular architecture. Every change should keep the app building successfully.
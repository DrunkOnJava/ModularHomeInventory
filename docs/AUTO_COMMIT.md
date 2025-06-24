# Auto-Commit Feature

This project automatically commits and pushes changes to GitHub after successful builds.

## Default Behavior

**Auto-commit is enabled by default!** Every successful `make build` will:
1. Stage all changes
2. Create a commit with a descriptive message
3. Push to GitHub

## Quick Commands

### Build with auto-commit (default):
```bash
make build
# or shorthand
make b
```

### Build WITHOUT auto-commit:
```bash
make build AUTO_COMMIT=false
```

### Disable permanently:
1. Create a local configuration:
   ```bash
   cp .makerc .makerc.local
   ```

2. Edit `.makerc.local` and set:
   ```bash
   AUTO_COMMIT=false
   ```

## How it Works

When enabled, successful builds will:
1. Stage all changes (`git add -A`)
2. Create a descriptive commit message
3. Push to the main branch on GitHub

## Commit Messages

The auto-commit script generates smart commit messages:

- **Single file**: `Update README.md`
- **Multiple files**: `Update 5 files (+120 -45)`
- **New file**: `Add NewFeature.swift`
- **Deleted file**: `Remove OldFile.swift`

All commits include:
```
🤖 Auto-committed after successful build

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Configuration

### Environment Variables
- `AUTO_COMMIT`: Set to `false` to disable (default: `true`)
- `SIMULATOR_ID`: Custom simulator UUID
- `SIMULATOR_NAME`: Custom simulator name

### Files
- `.makerc`: Default configuration (tracked in git)
- `.makerc.local`: Personal configuration (ignored by git)

## Manual Control

You can override the setting for any build:
```bash
# Force auto-commit even if disabled
make build AUTO_COMMIT=true

# Disable auto-commit even if enabled
make build AUTO_COMMIT=false
```

## Safety

- Only commits after **successful** builds
- Won't commit if there are no changes
- Uses standard git operations (can be undone)

## Disable

To disable auto-commit:
1. Create/edit `.makerc.local` and set `AUTO_COMMIT=false`
2. Or use `make build AUTO_COMMIT=false` for one-time disable
3. Or manually commit with `git add` and `git commit`
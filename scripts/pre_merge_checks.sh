#!/bin/bash

# Pre-merge checks for code quality and tests

set -e

echo "🔍 Running pre-merge checks..."

# 1. Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# 2. Run SwiftLint
echo "📋 Running SwiftLint..."
if ! make lint; then
    echo "❌ SwiftLint found issues. Run 'make lint-fix' to fix auto-correctable issues."
    exit 1
fi

# 3. Check formatting
echo "✨ Checking code formatting..."
if ! swiftformat --lint . --config .swiftformat >/dev/null 2>&1; then
    echo "❌ Code needs formatting. Run 'make format' to fix."
    exit 1
fi

# 4. Build the project
echo "🔨 Building project..."
if ! make build; then
    echo "❌ Build failed."
    exit 1
fi

# 5. Run tests
echo "🧪 Running unit tests..."
if ! make test; then
    echo "❌ Tests failed."
    exit 1
fi

# 6. Run snapshot tests
echo "📸 Running snapshot tests..."
if ! make test-snapshots; then
    echo "❌ Snapshot tests failed."
    echo "   If UI changes are intentional, run 'make record-snapshots' to update them."
    exit 1
fi

# 7. Check for large files
echo "📦 Checking for large files..."
LARGE_FILES=$(find . -type f -size +5M -not -path "./.git/*" -not -path "./build/*" -not -path "./.build/*" -not -name "*.xcodeproj")
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Found large files (>5MB):"
    echo "$LARGE_FILES"
    echo "Consider using Git LFS for these files."
fi

# 8. Success!
echo "✅ All pre-merge checks passed!"
echo ""
echo "Ready to merge! 🚀"
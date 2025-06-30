#!/bin/sh
# Xcode Cloud Pre-Build Script
# This runs before xcodebuild

set -e

echo "🚀 Starting pre-build setup..."

# Print environment info
echo "📍 Current directory: $(pwd)"
echo "📱 Xcode version: $(xcodebuild -version)"
echo "🖥️  macOS version: $(sw_vers -productVersion)"

# Install Ruby dependencies if Gemfile exists
if [ -f "Gemfile" ]; then
    echo "💎 Installing Ruby gems..."
    bundle install
fi

# Install Homebrew dependencies
echo "🍺 Installing build tools..."
brew install swiftlint || brew upgrade swiftlint || true
brew install swiftformat || brew upgrade swiftformat || true
brew install xcbeautify || brew upgrade xcbeautify || true

# Generate secrets with Arkana if configured
if [ -f ".arkana.yml" ] && [ -f ".env.arkana" ]; then
    echo "🔐 Generating encrypted secrets..."
    bundle exec arkana
elif [ -f ".arkana.yml" ]; then
    echo "⚠️  Arkana configured but .env.arkana not found"
    echo "ℹ️  Using example secrets for CI build"
    cp .env.arkana.example .env.arkana || true
    bundle exec arkana || true
fi

# Run SwiftLint
echo "🔍 Running SwiftLint..."
if [ -f ".swiftlint.yml" ]; then
    swiftlint lint --reporter json > swiftlint_report.json || true
    swiftlint lint --reporter emoji || true
else
    echo "⚠️  No .swiftlint.yml found"
fi

# Run SwiftFormat check
echo "✨ Checking code formatting..."
if [ -f ".swiftformat" ]; then
    swiftformat . --lint || true
else
    echo "⚠️  No .swiftformat found"
fi

# Generate Xcode project if using XcodeGen
if [ -f "project.yml" ]; then
    echo "⚙️  Generating Xcode project..."
    if ! command -v xcodegen &> /dev/null; then
        brew install xcodegen
    fi
    xcodegen generate
fi

# Resolve Swift Package dependencies
echo "📦 Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular

# Create required directories
echo "📁 Creating build directories..."
mkdir -p TestResults
mkdir -p BuildArtifacts
mkdir -p Generated

echo "✅ Pre-build setup complete!"
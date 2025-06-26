#!/bin/bash

echo "🔧 Swift 5.9 Setup Script"
echo "========================"
echo ""

# Check current Swift version
echo "📍 Current Swift version:"
swift --version
echo ""

# Check if Swift 5.9 toolchain exists
echo "🔍 Checking for Swift 5.9 toolchain..."
if [ -d "/Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain" ]; then
    echo "✅ Swift 5.9 toolchain found!"
else
    echo "❌ Swift 5.9 toolchain not found!"
    echo ""
    echo "📥 Please download and install Swift 5.9:"
    echo "   https://download.swift.org/swift-5.9-release/xcode/swift-5.9-RELEASE/swift-5.9-RELEASE-osx.pkg"
    echo ""
    echo "After installing, run this script again."
    exit 1
fi

echo ""
echo "🔧 Setting up Swift 5.9..."
echo ""

# Export toolchain for current session
export TOOLCHAINS=swift-5.9-RELEASE

# Add to shell profile
echo "📝 Adding to shell profile..."
if [[ $SHELL == *"zsh"* ]]; then
    echo 'export TOOLCHAINS=swift-5.9-RELEASE' >> ~/.zshrc
    echo "Added to ~/.zshrc"
else
    echo 'export TOOLCHAINS=swift-5.9-RELEASE' >> ~/.bash_profile
    echo "Added to ~/.bash_profile"
fi

echo ""
echo "✅ Swift 5.9 setup complete!"
echo ""
echo "📋 To use Swift 5.9:"
echo ""
echo "1. For this session:"
echo "   export TOOLCHAINS=swift-5.9-RELEASE"
echo ""
echo "2. Verify Swift 5.9 is active:"
echo "   xcrun --toolchain swift-5.9-RELEASE swift --version"
echo ""
echo "3. Build the project with Swift 5.9:"
echo "   cd /Users/griffin/Projects/ModularHomeInventory"
echo "   xcodebuild -toolchain swift-5.9-RELEASE -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular build"
echo ""
echo "4. Or use make with toolchain:"
echo "   TOOLCHAINS=swift-5.9-RELEASE make build"
echo ""

# Test Swift 5.9
echo "🧪 Testing Swift 5.9 toolchain:"
xcrun --toolchain swift-5.9-RELEASE swift --version
#!/bin/bash

# Build Validation Script
# Runs comprehensive checks before TestFlight submission

echo "🔍 Home Inventory - Build Validation"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
ERRORS=0
WARNINGS=0

# Function to check item and update counters
check() {
    local description=$1
    local command=$2
    local type=${3:-"error"} # error or warning
    
    echo -n "Checking $description... "
    
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅${NC}"
        return 0
    else
        if [ "$type" = "warning" ]; then
            echo -e "${YELLOW}⚠️${NC}"
            ((WARNINGS++))
        else
            echo -e "${RED}❌${NC}"
            ((ERRORS++))
        fi
        return 1
    fi
}

echo -e "${YELLOW}📱 App Configuration${NC}"
echo "--------------------"

# Check bundle identifier
check "Bundle ID" "grep -q 'com.homeinventory.app' HomeInventoryModular.xcodeproj/project.pbxproj"

# Check version number
check "Version (1.0.6)" "grep -q 'MARKETING_VERSION = 1.0.6' HomeInventoryModular.xcodeproj/project.pbxproj"

# Check build number
check "Build Number (7)" "grep -q 'CURRENT_PROJECT_VERSION = 7' HomeInventoryModular.xcodeproj/project.pbxproj"

# Check team ID
check "Team ID" "grep -q '2VXBQV4XC9' HomeInventoryModular.xcodeproj/project.pbxproj"

echo ""
echo -e "${YELLOW}🛠 Build Environment${NC}"
echo "-------------------"

# Check Swift version
check "Swift 5.9 installed" "test -d /Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain"

# Check Xcode
check "Xcode available" "xcodebuild -version"

# Check for Package.swift files
check "Package.swift format" "! grep -r 'swift-tools-version' Modules/*/Package.swift | grep -v '^[^:]*:// swift-tools-version:'"

echo ""
echo -e "${YELLOW}📄 Required Files${NC}"
echo "----------------"

# Check for required files
check "ExportOptions.plist" "test -f ExportOptions.plist"
check "Info.plist" "test -f Source/Supporting/Info.plist"
check "PrivacyInfo.xcprivacy" "test -f Source/Supporting/PrivacyInfo.xcprivacy"
check "Assets.xcassets" "test -d Source/Assets/Assets.xcassets"

echo ""
echo -e "${YELLOW}🔧 Code Quality${NC}"
echo "--------------"

# Check SwiftLint
if command -v swiftlint &> /dev/null; then
    LINT_OUTPUT=$(swiftlint --quiet 2>&1)
    LINT_ERRORS=$(echo "$LINT_OUTPUT" | grep -E "error|Error" | wc -l | tr -d ' ')
    LINT_WARNINGS=$(echo "$LINT_OUTPUT" | grep -E "warning|Warning" | wc -l | tr -d ' ')
    
    if [ "$LINT_ERRORS" -eq 0 ]; then
        echo -e "SwiftLint errors... ${GREEN}✅${NC}"
    else
        echo -e "SwiftLint errors... ${RED}❌ ($LINT_ERRORS errors)${NC}"
        ((ERRORS++))
    fi
    
    if [ "$LINT_WARNINGS" -lt 50 ]; then
        echo -e "SwiftLint warnings... ${GREEN}✅ ($LINT_WARNINGS warnings)${NC}"
    else
        echo -e "SwiftLint warnings... ${YELLOW}⚠️  ($LINT_WARNINGS warnings)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "SwiftLint... ${YELLOW}⚠️  (not installed)${NC}"
    ((WARNINGS++))
fi

echo ""
echo -e "${YELLOW}🔑 Signing & Capabilities${NC}"
echo "------------------------"

# Check for entitlements
check "Push Notifications" "grep -q 'aps-environment' Source/Supporting/*.entitlements" "warning"
check "App Groups" "grep -q 'com.apple.security.application-groups' Source/Supporting/*.entitlements" "warning"
check "CloudKit" "grep -q 'com.apple.developer.icloud-services' Source/Supporting/*.entitlements" "warning"

echo ""
echo -e "${YELLOW}📊 Project Structure${NC}"
echo "-------------------"

# Check module structure
check "Core module" "test -d Modules/Core"
check "Items module" "test -d Modules/Items"
check "Premium module" "test -d Modules/Premium"
check "SharedUI module" "test -d Modules/SharedUI"

echo ""
echo -e "${YELLOW}🌐 API Configuration${NC}"
echo "-------------------"

# Check for hardcoded API keys (security check)
echo -n "Checking for hardcoded secrets... "
if grep -r "AIza\|AKIA\|api_key\|apiKey" --include="*.swift" --include="*.m" Source/ Modules/ &> /dev/null; then
    echo -e "${RED}❌ (found potential secrets)${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅${NC}"
fi

echo ""
echo -e "${YELLOW}📱 App Store Assets${NC}"
echo "------------------"

# Check for app icon
check "App Icon (1024x)" "test -f Source/Assets/Assets.xcassets/AppIcon.appiconset/icon_1024.png" "warning"

# Check for launch screen
check "Launch Screen" "test -f Source/Supporting/LaunchScreen.storyboard || grep -q 'Launch Screen' Source/Assets/Assets.xcassets" "warning"

echo ""
echo -e "${YELLOW}📋 Documentation${NC}"
echo "---------------"

# Check for documentation
check "README.md" "test -f README.md" "warning"
check "CHANGELOG.md" "test -f CHANGELOG.md" "warning"
check "Release Notes" "test -f TESTFLIGHT_RELEASE_NOTES.md"

echo ""
echo "===================================="
echo -e "${YELLOW}📊 Validation Summary${NC}"
echo "===================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo "Your build is ready for TestFlight submission."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with $WARNINGS warnings${NC}"
    echo "You can proceed with submission, but consider addressing the warnings."
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS errors and $WARNINGS warnings${NC}"
    echo "Please fix the errors before submitting to TestFlight."
    exit 1
fi
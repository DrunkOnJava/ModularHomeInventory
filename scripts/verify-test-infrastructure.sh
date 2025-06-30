#!/bin/bash

# Verify Test Infrastructure

echo "🔍 Verifying Test Infrastructure Implementation"
echo "============================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check TestUtilities module
echo -e "\n📦 Checking TestUtilities Module:"
if [ -d "Modules/TestUtilities" ]; then
    echo -e "${GREEN}✅ TestUtilities module exists${NC}"
    
    # Check for key files
    if [ -f "Modules/TestUtilities/Package.swift" ]; then
        echo -e "${GREEN}✅ Package.swift found${NC}"
    fi
    
    # Count source files
    test_util_count=$(find Modules/TestUtilities/Sources -name "*.swift" | wc -l | tr -d ' ')
    echo -e "   Found ${test_util_count} Swift files"
else
    echo -e "${RED}❌ TestUtilities module not found${NC}"
fi

# Check test categories
echo -e "\n🧪 Checking Test Categories:"

declare -A test_categories=(
    ["PerformanceTests"]="Performance Testing"
    ["IntegrationTests"]="Integration Testing"
    ["NetworkTests"]="Network Resilience"
    ["SecurityTests"]="Security Testing"
    ["EdgeCaseTests"]="Edge Case Testing"
    ["UIGestureTests"]="UI Gesture Testing"
)

for dir in "${!test_categories[@]}"; do
    if [ -d "HomeInventoryModularTests/$dir" ]; then
        count=$(find "HomeInventoryModularTests/$dir" -name "*.swift" | wc -l | tr -d ' ')
        echo -e "${GREEN}✅ ${test_categories[$dir]}: $count test files${NC}"
    else
        echo -e "${RED}❌ ${test_categories[$dir]} directory not found${NC}"
    fi
done

# Check CI/CD files
echo -e "\n🚀 Checking CI/CD Configuration:"

ci_files=(
    ".github/workflows/comprehensive-tests.yml"
    ".github/workflows/pr-validation.yml"
    ".github/workflows/nightly-tests.yml"
)

for file in "${ci_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $(basename $file) exists${NC}"
    else
        echo -e "${RED}❌ $(basename $file) not found${NC}"
    fi
done

# Check Fastlane test lanes
echo -e "\n🏃 Checking Fastlane Test Lanes:"
if [ -f "fastlane/Fastfile" ]; then
    lanes=$(grep -E "lane :test_" fastlane/Fastfile | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Found $lanes test lanes in Fastfile${NC}"
    
    # List test lanes
    echo "   Test lanes:"
    grep -E "lane :test_" fastlane/Fastfile | sed 's/.*lane :\(test_[a-zA-Z_]*\).*/   - \1/'
else
    echo -e "${RED}❌ Fastfile not found${NC}"
fi

# Check for test scripts
echo -e "\n📜 Checking Test Scripts:"
if [ -d "scripts" ]; then
    script_count=$(find scripts -name "*.sh" -o -name "*.py" | grep -E "test|performance|security" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Found $script_count test-related scripts${NC}"
fi

# Summary
echo -e "\n📊 Test Infrastructure Summary:"
echo "================================"

# Count total test files
total_tests=$(find HomeInventoryModularTests -name "*.swift" | wc -l | tr -d ' ')
echo "Total test files: $total_tests"

# Count new test categories
new_categories=0
for dir in "${!test_categories[@]}"; do
    [ -d "HomeInventoryModularTests/$dir" ] && ((new_categories++))
done
echo "New test categories implemented: $new_categories/6"

# Final status
echo -e "\n🎯 Overall Status:"
if [ $new_categories -eq 6 ] && [ -d "Modules/TestUtilities" ] && [ -f ".github/workflows/comprehensive-tests.yml" ]; then
    echo -e "${GREEN}✅ Test infrastructure implementation complete!${NC}"
else
    echo -e "${YELLOW}⚠️  Some components may be missing${NC}"
fi

echo -e "\n✨ Run 'fastlane test_all' to execute the complete test suite"
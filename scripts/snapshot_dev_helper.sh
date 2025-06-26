#!/usr/bin/env bash

# Snapshot Development Helper
# Provides convenient commands for working with snapshots locally

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

function show_help {
    echo "Snapshot Development Helper"
    echo "=========================="
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  record <module>     Record new snapshots for a module"
    echo "  update <module>     Update existing snapshots for a module"
    echo "  test <module>       Run snapshot tests for a module"
    echo "  clean               Clean all snapshot artifacts"
    echo "  gallery             Open the snapshot gallery in browser"
    echo "  diff <module>       Show snapshot differences"
    echo "  list                List all modules with snapshot tests"
    echo ""
    echo "Examples:"
    echo "  $0 record SharedUI"
    echo "  $0 test Core"
    echo "  $0 clean"
}

function record_snapshots {
    local MODULE=$1
    if [ -z "$MODULE" ]; then
        echo -e "${RED}Error: Module name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📸 Recording snapshots for $MODULE...${NC}"
    
    # Enable recording mode
    cd "$PROJECT_ROOT/Modules/$MODULE"
    
    # Find all snapshot test files and enable recording
    find Tests -name "*SnapshotTests.swift" -exec sed -i '' 's/\/\/ isRecording = true/isRecording = true/' {} \;
    
    # Run tests
    swift test --filter ".*Snapshot.*"
    
    # Disable recording mode
    find Tests -name "*SnapshotTests.swift" -exec sed -i '' 's/isRecording = true/\/\/ isRecording = true/' {} \;
    
    echo -e "${GREEN}✓ Snapshots recorded for $MODULE${NC}"
}

function update_snapshots {
    local MODULE=$1
    if [ -z "$MODULE" ]; then
        echo -e "${RED}Error: Module name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔄 Updating snapshots for $MODULE...${NC}"
    
    # Remove existing snapshots
    find "$PROJECT_ROOT/Modules/$MODULE" -name "__Snapshots__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Record new ones
    record_snapshots "$MODULE"
}

function test_snapshots {
    local MODULE=$1
    if [ -z "$MODULE" ]; then
        echo -e "${RED}Error: Module name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🧪 Testing snapshots for $MODULE...${NC}"
    
    cd "$PROJECT_ROOT/Modules/$MODULE"
    
    if swift test --filter ".*Snapshot.*"; then
        echo -e "${GREEN}✓ All snapshot tests passed for $MODULE${NC}"
    else
        echo -e "${RED}✗ Snapshot tests failed for $MODULE${NC}"
        echo -e "${YELLOW}💡 Tip: Run '$0 diff $MODULE' to see differences${NC}"
        exit 1
    fi
}

function clean_snapshots {
    echo -e "${YELLOW}🧹 Cleaning all snapshot artifacts...${NC}"
    
    # Remove all __Snapshots__ directories
    find "$PROJECT_ROOT" -name "__Snapshots__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Clean output directory
    rm -rf "$PROJECT_ROOT/fastlane/component_screenshots"/*
    
    echo -e "${GREEN}✓ All snapshot artifacts cleaned${NC}"
}

function open_gallery {
    local GALLERY="$PROJECT_ROOT/fastlane/component_screenshots/index.html"
    
    if [ -f "$GALLERY" ]; then
        echo -e "${BLUE}🖼️  Opening snapshot gallery...${NC}"
        open "$GALLERY"
    else
        echo -e "${YELLOW}⚠️  Gallery not found. Run './scripts/generate_snapshots.sh' first${NC}"
    fi
}

function show_diff {
    local MODULE=$1
    if [ -z "$MODULE" ]; then
        echo -e "${RED}Error: Module name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔍 Showing snapshot differences for $MODULE...${NC}"
    
    # Find failure diff images
    find "$PROJECT_ROOT/Modules/$MODULE" -name "*_failure_diff_*.png" | while read -r diff; do
        echo -e "${YELLOW}Difference found: $(basename "$diff")${NC}"
        open "$diff"
    done
}

function list_modules {
    echo -e "${BLUE}📦 Modules with snapshot tests:${NC}"
    echo ""
    
    find "$PROJECT_ROOT/Modules" -name "*SnapshotTests.swift" -print0 | while IFS= read -r -d '' file; do
        MODULE=$(echo "$file" | sed -E 's|.*/Modules/([^/]+)/.*|\1|')
        COUNT=$(grep -c "func test" "$file" || echo "0")
        echo -e "  • ${GREEN}$MODULE${NC} ($COUNT tests)"
    done | sort -u
}

# Main command handling
case "${1:-help}" in
    record)
        record_snapshots "$2"
        ;;
    update)
        update_snapshots "$2"
        ;;
    test)
        test_snapshots "$2"
        ;;
    clean)
        clean_snapshots
        ;;
    gallery)
        open_gallery
        ;;
    diff)
        show_diff "$2"
        ;;
    list)
        list_modules
        ;;
    help|--help|-h|*)
        show_help
        ;;
esac
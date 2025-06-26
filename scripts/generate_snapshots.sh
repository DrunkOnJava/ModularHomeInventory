#!/usr/bin/env bash

# Component Snapshot Generation Script
# Discovers all SwiftUI views and generates pixel-perfect snapshots

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOTS_DIR="$PROJECT_ROOT/fastlane/component_screenshots"
SNAPSHOT_TESTS_DIR="$PROJECT_ROOT/ComponentSnapshotTests"
WORKSPACE="HomeInventoryModular.xcworkspace"
SNAPSHOT_SCHEME="ComponentSnapshots"
SIMULATOR="iPhone 15 Pro"
OS_VERSION="17.5"

echo -e "${BLUE}🚀 Component Snapshot Generation${NC}"
echo "================================"

# Step 1: Create necessary directories
echo -e "\n${YELLOW}📁 Creating directories...${NC}"
mkdir -p "$SNAPSHOTS_DIR"
mkdir -p "$SNAPSHOT_TESTS_DIR"

# Step 2: Discover all views
echo -e "\n${YELLOW}🔍 Discovering SwiftUI views...${NC}"
cd "$PROJECT_ROOT"
swift scripts/discover_views.swift > scripts/snapshot_test_generation.sh

# Make the generated script executable
chmod +x scripts/snapshot_test_generation.sh

# Step 3: Count discovered views
VIEW_COUNT=$(grep -c "Generate test for" scripts/snapshot_test_generation.sh || echo "0")
echo -e "${GREEN}✓ Found $VIEW_COUNT views${NC}"

# Step 4: Generate snapshot tests (optional - uncomment if you want to regenerate)
# echo -e "\n${YELLOW}📝 Generating snapshot tests...${NC}"
# ./scripts/snapshot_test_generation.sh

# Step 5: Clean old snapshots
echo -e "\n${YELLOW}🧹 Cleaning old snapshots...${NC}"
rm -rf "$SNAPSHOTS_DIR"/*
find "$PROJECT_ROOT" -name "__Snapshots__" -type d -exec rm -rf {} + 2>/dev/null || true

# Step 6: Create a test plan if needed
echo -e "\n${YELLOW}📋 Setting up test configuration...${NC}"
cat > "$PROJECT_ROOT/ComponentSnapshots.xctestplan" << 'EOF'
{
  "configurations": [
    {
      "id": "DEFAULT",
      "name": "Default Configuration",
      "options": {
        "environmentVariableEntries": [
          {
            "key": "SNAPSHOT_TESTING",
            "value": "1"
          }
        ]
      }
    }
  ],
  "defaultOptions": {
    "codeCoverage": false,
    "testTimeoutsEnabled": true,
    "maximumTestExecutionTimeAllowance": 600
  },
  "testTargets": [
    {
      "target": {
        "containerPath": "container:HomeInventoryModular.xcodeproj",
        "identifier": "ComponentSnapshotTests",
        "name": "ComponentSnapshotTests"
      }
    }
  ],
  "version": 1
}
EOF

# Step 7: Run snapshot tests for each module
echo -e "\n${YELLOW}🧪 Running snapshot tests...${NC}"

# Get list of modules with tests
MODULES=$(find Modules -name "*Tests" -type d -maxdepth 2 | grep -v ".build" | sort)

for MODULE_TEST_DIR in $MODULES; do
    MODULE_NAME=$(basename "$(dirname "$MODULE_TEST_DIR")")
    
    if [ -d "$MODULE_TEST_DIR" ]; then
        echo -e "\n${BLUE}Testing $MODULE_NAME...${NC}"
        
        # Check if module has snapshot tests
        if find "$MODULE_TEST_DIR" -name "*SnapshotTests.swift" -print -quit | grep -q .; then
            # Run tests for this module
            cd "$(dirname "$MODULE_TEST_DIR")"
            
            # Use swift test for SPM modules
            if swift test --filter ".*Snapshot.*" 2>&1 | tee test_output.log; then
                echo -e "${GREEN}✓ $MODULE_NAME snapshot tests passed${NC}"
            else
                echo -e "${RED}✗ $MODULE_NAME snapshot tests failed${NC}"
                # Continue with other modules even if one fails
            fi
            
            cd "$PROJECT_ROOT"
        else
            echo -e "${YELLOW}⚠ No snapshot tests found for $MODULE_NAME${NC}"
        fi
    fi
done

# Step 8: Collect generated snapshots
echo -e "\n${YELLOW}📸 Collecting snapshots...${NC}"

# Find all generated snapshot images
SNAPSHOT_COUNT=0
find "$PROJECT_ROOT" -path "*/__Snapshots__/*" -name "*.png" | while read -r snapshot; do
    # Extract meaningful name from path
    SNAPSHOT_NAME=$(echo "$snapshot" | sed 's/.*__Snapshots__\///' | sed 's/\//___/g')
    
    # Copy to collection directory
    cp "$snapshot" "$SNAPSHOTS_DIR/$SNAPSHOT_NAME"
    ((SNAPSHOT_COUNT++))
done

# Step 9: Generate HTML gallery (optional)
echo -e "\n${YELLOW}🖼️  Generating snapshot gallery...${NC}"
cat > "$SNAPSHOTS_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Component Snapshots</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }
        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        .snapshot {
            background: white;
            border-radius: 8px;
            padding: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .snapshot img {
            width: 100%;
            height: auto;
            border-radius: 4px;
        }
        .snapshot h3 {
            margin: 10px 0 5px;
            font-size: 14px;
            color: #333;
        }
        .filters {
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .filter-btn {
            padding: 8px 16px;
            border: 1px solid #ddd;
            border-radius: 20px;
            background: white;
            cursor: pointer;
            transition: all 0.2s;
        }
        .filter-btn:hover {
            background: #007AFF;
            color: white;
            border-color: #007AFF;
        }
        .filter-btn.active {
            background: #007AFF;
            color: white;
            border-color: #007AFF;
        }
    </style>
</head>
<body>
    <h1>Component Snapshots</h1>
    <p>Generated on: <span id="date"></span></p>
    
    <div class="filters">
        <button class="filter-btn active" onclick="filterSnapshots('all')">All</button>
        <button class="filter-btn" onclick="filterSnapshots('default')">Default</button>
        <button class="filter-btn" onclick="filterSnapshots('iPhone')">iPhone</button>
        <button class="filter-btn" onclick="filterSnapshots('iPad')">iPad</button>
        <button class="filter-btn" onclick="filterSnapshots('dark')">Dark Mode</button>
    </div>
    
    <div class="gallery" id="gallery"></div>
    
    <script>
        document.getElementById('date').textContent = new Date().toLocaleString();
        
        function loadSnapshots() {
            // This would be populated by the script
            const snapshots = [];
EOF

# Add each snapshot to the HTML
for snapshot in "$SNAPSHOTS_DIR"/*.png; do
    if [ -f "$snapshot" ]; then
        FILENAME=$(basename "$snapshot")
        echo "            snapshots.push('$FILENAME');" >> "$SNAPSHOTS_DIR/index.html"
    fi
done

cat >> "$SNAPSHOTS_DIR/index.html" << 'EOF'
            
            const gallery = document.getElementById('gallery');
            
            snapshots.forEach(filename => {
                const div = document.createElement('div');
                div.className = 'snapshot';
                div.dataset.filename = filename;
                
                const img = document.createElement('img');
                img.src = filename;
                img.loading = 'lazy';
                
                const title = document.createElement('h3');
                title.textContent = filename.replace('.png', '').replace(/___/g, ' / ');
                
                div.appendChild(img);
                div.appendChild(title);
                gallery.appendChild(div);
            });
        }
        
        function filterSnapshots(filter) {
            const buttons = document.querySelectorAll('.filter-btn');
            buttons.forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');
            
            const snapshots = document.querySelectorAll('.snapshot');
            snapshots.forEach(snapshot => {
                const filename = snapshot.dataset.filename;
                if (filter === 'all' || filename.includes(filter)) {
                    snapshot.style.display = 'block';
                } else {
                    snapshot.style.display = 'none';
                }
            });
        }
        
        loadSnapshots();
    </script>
</body>
</html>
EOF

# Step 10: Summary
echo -e "\n${GREEN}✅ Snapshot generation complete!${NC}"
echo "================================"
echo -e "📊 Results:"
echo -e "   • Views discovered: $VIEW_COUNT"
echo -e "   • Snapshots generated: $(ls -1 "$SNAPSHOTS_DIR"/*.png 2>/dev/null | wc -l)"
echo -e "   • Output directory: $SNAPSHOTS_DIR"
echo -e "   • View gallery: $SNAPSHOTS_DIR/index.html"
echo
echo -e "${BLUE}💡 Tips:${NC}"
echo "   • To record new snapshots: Set isRecording = true in test files"
echo "   • To update snapshots: Delete __Snapshots__ folders and re-run"
echo "   • View the gallery: open $SNAPSHOTS_DIR/index.html"
echo
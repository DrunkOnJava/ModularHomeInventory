#!/usr/bin/env python3

import os
import glob

# Find all snapshot images
snapshots = glob.glob("HomeInventoryModularTests/**/__Snapshots__/**/*.png", recursive=True)

print("📸 Home Inventory UI Snapshots")
print("=" * 50)
print(f"\nTotal snapshots found: {len(snapshots)}")
print("\n🖼️  Snapshot Images:\n")

# Group by test class
by_class = {}
for snap in sorted(snapshots):
    parts = snap.split('/')
    if len(parts) >= 4:
        test_class = parts[2] if '__Snapshots__' in parts else parts[3]
        if test_class not in by_class:
            by_class[test_class] = []
        by_class[test_class].append(snap)

# Display grouped
for test_class, files in sorted(by_class.items()):
    print(f"\n📁 {test_class}:")
    for file in sorted(files):
        filename = os.path.basename(file)
        size = os.path.getsize(file) // 1024  # KB
        print(f"   ✓ {filename} ({size}KB)")

print("\n" + "=" * 50)
print("✅ All snapshots are located in HomeInventoryModularTests/SharedUI/__Snapshots__/")
print("\nTo view these snapshots:")
print("1. Open Finder and navigate to the project directory")
print("2. Go to HomeInventoryModularTests/SharedUI/__Snapshots__/")
print("3. Each test class has its own folder with PNG images")
print("\nThese snapshots are used for UI regression testing to ensure")
print("UI components don't change unexpectedly between builds.")
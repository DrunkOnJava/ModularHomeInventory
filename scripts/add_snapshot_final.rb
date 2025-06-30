#!/usr/bin/env ruby

require 'xcodeproj'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "📦 Adding SnapshotTesting dependency..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find test target
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
unless test_target
  puts "❌ Test target not found!"
  exit 1
end

# Check if already has dependency
has_snapshot = test_target.package_product_dependencies.any? { |dep|
  dep.product_name == 'SnapshotTesting'
}

if has_snapshot
  puts "✅ SnapshotTesting dependency already present"
else
  # Find SnapshotTesting package reference
  snapshot_package = project.root_object.package_references.find do |ref|
    ref.is_a?(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference) &&
    ref.repositoryURL == 'https://github.com/pointfreeco/swift-snapshot-testing'
  end
  
  if snapshot_package
    puts "✅ Found swift-snapshot-testing package (UUID: #{snapshot_package.uuid})"
    
    # Create package product dependency
    product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_dep.package = snapshot_package
    product_dep.product_name = 'SnapshotTesting'
    
    # Add to test target
    test_target.package_product_dependencies << product_dep
    
    puts "✅ Added SnapshotTesting dependency to test target"
  else
    puts "❌ Could not find swift-snapshot-testing package reference"
  end
end

# Save
project.save

puts "\n✅ Done!"

# Now add a simple snapshot test
puts "\n📄 Adding simple snapshot test..."

snapshot_test = <<-SWIFT
import XCTest
import SnapshotTesting
import SwiftUI

final class SimpleSnapshotTest: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = true
    }
    
    func testSimpleView() {
        let view = Text("Hello, Snapshot Testing!")
            .font(.largeTitle)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        
        let hostingController = UIHostingController(rootView: view)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}
SWIFT

File.write('HomeInventoryModularTests/SimpleSnapshotTest.swift', snapshot_test)

# Add to project
test_group = project.main_group['HomeInventoryModularTests']
if test_group
  unless test_group.children.any? { |f| f.path == 'SimpleSnapshotTest.swift' }
    file_ref = test_group.new_reference('SimpleSnapshotTest.swift')
    test_target.add_file_references([file_ref])
    puts "✅ Added SimpleSnapshotTest.swift"
  end
end

# Save again
project.save

puts "\n🧪 Ready to test! Run:"
puts "xcodebuild test -project HomeInventoryModular.xcodeproj -scheme HomeInventoryModular -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:HomeInventoryModularTests/SimpleSnapshotTest RECORD_SNAPSHOTS=YES"
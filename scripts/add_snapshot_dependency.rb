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

# Find SnapshotTesting package reference
snapshot_package = nil
project.root_object.package_references.each do |ref|
  if ref.is_a?(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    # Check using different methods to find the URL
    if ref.remote_ref && ref.remote_ref.include?('swift-snapshot-testing')
      snapshot_package = ref
      break
    elsif ref.repositoryURL && ref.repositoryURL.include?('swift-snapshot-testing')
      snapshot_package = ref
      break
    elsif ref.requirement && ref.requirement['repositoryURL'] && ref.requirement['repositoryURL'].include?('swift-snapshot-testing')
      snapshot_package = ref
      break
    end
  end
end

if snapshot_package
  puts "✅ Found swift-snapshot-testing package"
  
  # Create package product dependency
  product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dep.package = snapshot_package
  product_dep.product_name = 'SnapshotTesting'
  
  # Add to test target
  test_target.package_product_dependencies << product_dep
  
  puts "✅ Added SnapshotTesting dependency to test target"
else
  puts "⚠️  Could not find swift-snapshot-testing package reference"
  puts "   You may need to add it manually in Xcode"
end

# Save
project.save

puts "\n✅ Done!"
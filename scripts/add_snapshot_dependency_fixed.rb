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
  snapshot_package = nil
  project.root_object.package_references.each do |ref|
    if ref.is_a?(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
      # Access attributes directly
      if ref.attributes && ref.attributes['repositoryURL']
        if ref.attributes['repositoryURL'].include?('swift-snapshot-testing')
          snapshot_package = ref
          break
        end
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
    puts "   Listing all package references:"
    project.root_object.package_references.each do |ref|
      if ref.attributes && ref.attributes['repositoryURL']
        puts "   - #{ref.attributes['repositoryURL']}"
      end
    end
  end
end

# Save
project.save

puts "\n✅ Done!"
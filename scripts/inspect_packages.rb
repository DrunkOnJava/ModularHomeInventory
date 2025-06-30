#!/usr/bin/env ruby

require 'xcodeproj'
require 'pp'

PROJECT_PATH = 'HomeInventoryModular.xcodeproj'

puts "📦 Inspecting package references..."

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

puts "\nPackage references:"
project.root_object.package_references.each_with_index do |ref, idx|
  puts "\n[#{idx}] Class: #{ref.class}"
  puts "UUID: #{ref.uuid}"
  
  # Print all instance variables
  ref.instance_variables.each do |var|
    value = ref.instance_variable_get(var)
    puts "#{var}: #{value.inspect[0..200]}"
  end
  
  # Try different ways to access URL
  if ref.respond_to?(:repositoryURL)
    puts "repositoryURL method: #{ref.repositoryURL}"
  end
  
  if ref.respond_to?(:requirement)
    puts "requirement: #{ref.requirement.inspect}"
  end
end

puts "\n\nTest target package product dependencies:"
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }
if test_target
  test_target.package_product_dependencies.each do |dep|
    puts "- Product: #{dep.product_name}"
    puts "  Package UUID: #{dep.package.uuid if dep.package}"
  end
else
  puts "Test target not found"
end
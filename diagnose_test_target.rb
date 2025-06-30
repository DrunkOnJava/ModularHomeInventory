#!/usr/bin/env ruby

require 'xcodeproj'

project = Xcodeproj::Project.open('HomeInventoryModular.xcodeproj')
test_target = project.targets.find { |t| t.name == 'HomeInventoryModularTests' }

puts "Test Target Analysis:"
puts "===================="
puts "Name: #{test_target.name}"
puts "Product type: #{test_target.product_type}"
puts "Product name: #{test_target.build_settings('Debug')['PRODUCT_NAME']}"
puts ""
puts "Source files:"
test_target.source_build_phase.files.each do |f|
  puts "  - #{f.file_ref.path if f.file_ref}"
end
puts ""
puts "Frameworks:"
test_target.frameworks_build_phase.files.each do |file|
  puts "  - #{file.display_name}"
end
puts ""
puts "Package dependencies:"
test_target.package_product_dependencies.each do |dep|
  puts "  - #{dep.product_name}"
end

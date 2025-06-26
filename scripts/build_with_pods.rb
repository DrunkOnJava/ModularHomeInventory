#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'
require 'json'
require 'open3'

puts "🔧 Alternative Build System for Swift 5.9"
puts "========================================"
puts ""

# Check Swift 5.9
swift59_path = "/Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain/usr/bin/swift"
if File.exist?(swift59_path)
  puts "✅ Swift 5.9 found at: #{swift59_path}"
  version = `#{swift59_path} --version`
  puts version
else
  puts "❌ Swift 5.9 not found!"
  exit 1
end

# Create a build script that bypasses SPM
puts ""
puts "📦 Creating build configuration..."

# Generate build settings
build_settings = {
  "SWIFT_VERSION" => "5.0",
  "TOOLCHAINS" => "swift-5.9-RELEASE",
  "SWIFT_EXEC" => swift59_path,
  "DEVELOPER_DIR" => "/Applications/Xcode.app/Contents/Developer",
  "SDKROOT" => "iphoneos",
  "CODE_SIGN_IDENTITY" => "Apple Development",
  "DEVELOPMENT_TEAM" => "2VXBQV4XC9",
  "PRODUCT_BUNDLE_IDENTIFIER" => "com.homeinventory.app"
}

# Write build configuration
File.write("swift59_build.xcconfig", build_settings.map { |k, v| "#{k} = #{v}" }.join("\n"))

puts "✅ Build configuration created"
puts ""

# Try building with gym
puts "🏗️ Building with gym (fastlane)..."

gym_config = {
  project: "HomeInventoryModular.xcodeproj",
  scheme: "HomeInventoryModular",
  clean: true,
  output_directory: "./build",
  output_name: "HomeInventory",
  configuration: "Release",
  export_method: "app-store",
  export_xcargs: "-allowProvisioningUpdates",
  xcconfig: "swift59_build.xcconfig",
  disable_package_automatic_updates: true,
  cloned_source_packages_path: "./build/SourcePackages",
  skip_package_dependencies_resolution: true,
  toolchain: "swift-5.9-RELEASE"
}

# Create gym command
gym_cmd = "bundle exec gym"
gym_config.each do |key, value|
  if value.is_a?(TrueClass)
    gym_cmd += " --#{key.to_s.gsub('_', '-')}"
  elsif value.is_a?(FalseClass)
    # Skip false values
  else
    gym_cmd += " --#{key.to_s.gsub('_', '-')} '#{value}'"
  end
end

puts "Running: #{gym_cmd}"
puts ""

# Execute gym
success = system(gym_cmd)

if success
  puts ""
  puts "✅ Build successful!"
  puts "📦 IPA location: ./build/HomeInventory.ipa"
  puts ""
  puts "📤 Uploading to TestFlight..."
  
  # Upload with pilot
  pilot_cmd = "bundle exec pilot upload -i ./build/HomeInventory.ipa -u griffinradcliffe@gmail.com --skip_waiting_for_build_processing"
  system(pilot_cmd)
else
  puts ""
  puts "❌ Build failed!"
  puts ""
  puts "Alternative: Use xcodebuild directly with Swift 5.9:"
  puts ""
  puts "export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer"
  puts "export TOOLCHAINS=swift-5.9-RELEASE"
  puts "/Library/Developer/Toolchains/swift-5.9-RELEASE.xctoolchain/usr/bin/xcodebuild \\"
  puts "  -project HomeInventoryModular.xcodeproj \\"
  puts "  -scheme HomeInventoryModular \\"
  puts "  -configuration Release \\"
  puts "  -destination 'generic/platform=iOS' \\"
  puts "  build"
end
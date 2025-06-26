#!/usr/bin/env ruby

require 'open3'
require 'fileutils'

puts "🚀 TestFlight Build with Swift 5.9"
puts "=================================="
puts ""

# Set environment for Swift 5.9
ENV['TOOLCHAINS'] = 'swift-5.9-RELEASE'
ENV['DEVELOPER_DIR'] = '/Applications/Xcode.app/Contents/Developer'

# Create a minimal xcodebuild command that bypasses SPM
build_cmd = [
  '/usr/bin/xcodebuild',
  '-project', 'HomeInventoryModular.xcodeproj',
  '-scheme', 'HomeInventoryModular',
  '-configuration', 'Release',
  '-destination', 'generic/platform=iOS',
  '-derivedDataPath', 'build/DerivedData',
  'CODE_SIGN_IDENTITY=Apple Development',
  'DEVELOPMENT_TEAM=2VXBQV4XC9',
  'SWIFT_VERSION=5.0',
  '-allowProvisioningUpdates',
  '-skipPackagePluginValidation',
  '-skipMacroValidation',
  'archive',
  '-archivePath', 'build/HomeInventory.xcarchive'
]

puts "Building archive..."
puts "Command: #{build_cmd.join(' ')}"
puts ""

# Run build
success = system(*build_cmd)

if success
  puts "✅ Archive created successfully!"
  puts ""
  
  # Export IPA
  export_plist = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>method</key>
      <string>app-store</string>
      <key>teamID</key>
      <string>2VXBQV4XC9</string>
      <key>uploadSymbols</key>
      <true/>
      <key>compileBitcode</key>
      <false/>
      <key>uploadBitcode</key>
      <false/>
      <key>signingStyle</key>
      <string>automatic</string>
      <key>generateAppStoreInformation</key>
      <true/>
    </dict>
    </plist>
  XML
  
  File.write('ExportOptions.plist', export_plist)
  
  puts "Exporting IPA..."
  export_cmd = [
    'xcodebuild',
    '-exportArchive',
    '-archivePath', 'build/HomeInventory.xcarchive',
    '-exportPath', 'build',
    '-exportOptionsPlist', 'ExportOptions.plist'
  ]
  
  if system(*export_cmd)
    puts "✅ IPA exported successfully!"
    puts "📦 IPA location: build/HomeInventoryModular.ipa"
    puts ""
    
    # Upload to TestFlight
    puts "📤 Uploading to TestFlight..."
    upload_cmd = [
      'xcrun', 'altool',
      '--upload-app',
      '-f', 'build/HomeInventoryModular.ipa',
      '-t', 'ios',
      '-u', 'griffinradcliffe@gmail.com',
      '-p', ENV['FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD'] || 'lyto-qjbu-uffy-hsgb'
    ]
    
    if system(*upload_cmd)
      puts "✅ Successfully uploaded to TestFlight!"
    else
      puts "❌ Upload failed. Try using Transporter app."
    end
  end
else
  puts "❌ Build failed!"
  puts ""
  puts "Try using fastlane instead:"
  puts "bundle exec fastlane testflight force:true"
end
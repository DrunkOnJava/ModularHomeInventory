#!/usr/bin/env ruby

require 'fileutils'
require 'open3'
require 'tmpdir'

IPA_PATH = 'build/HomeInventoryModular-1.0.6.ipa'
BUNDLE_ID = 'com.homeinventory.app'
TEAM_ID = '2VXBQV4XC9'

puts "🔧 Re-signing IPA for TestFlight"
puts "================================"
puts ""

unless File.exist?(IPA_PATH)
  puts "❌ IPA not found at #{IPA_PATH}"
  exit 1
end

# Create a temporary directory for work
Dir.mktmpdir do |tmpdir|
  puts "📦 Extracting IPA..."
  system("unzip -q '#{IPA_PATH}' -d '#{tmpdir}'")
  
  app_path = Dir.glob("#{tmpdir}/Payload/*.app").first
  if app_path.nil?
    puts "❌ No app found in IPA"
    exit 1
  end
  
  puts "📱 Found app: #{File.basename(app_path)}"
  
  # Check for provisioning profiles
  puts "🔍 Looking for provisioning profiles..."
  
  # List available provisioning profiles
  profiles_output = `security cms -D -i ~/Library/MobileDevice/Provisioning\\ Profiles/*.mobileprovision 2>/dev/null | grep -E "(Name|UUID|TeamIdentifier|application-identifier)" | grep -B3 -A1 "#{BUNDLE_ID}"`
  
  if profiles_output.empty?
    puts "❌ No provisioning profile found for #{BUNDLE_ID}"
    puts ""
    puts "To create one:"
    puts "1. Open Xcode"
    puts "2. Go to Preferences → Accounts"
    puts "3. Select your team"
    puts "4. Click 'Download Manual Profiles'"
    puts ""
    puts "Or create via Apple Developer portal:"
    puts "https://developer.apple.com/account/resources/profiles/list"
    exit 1
  end
  
  puts "✅ Found provisioning profiles"
  
  # Try to find an App Store distribution profile
  profile_path = Dir.glob(File.expand_path("~/Library/MobileDevice/Provisioning Profiles/*.mobileprovision")).find do |profile|
    content = `security cms -D -i "#{profile}" 2>/dev/null`
    content.include?(BUNDLE_ID) && content.include?("ProvisionsAllDevices") == false
  end
  
  if profile_path
    puts "📄 Using profile: #{File.basename(profile_path)}"
    
    # Copy provisioning profile
    FileUtils.cp(profile_path, "#{app_path}/embedded.mobileprovision")
    
    # Get signing identity
    identity = `security find-identity -v -p codesigning | grep "#{TEAM_ID}" | head -1 | awk '{print $2}'`.strip
    
    if identity.empty?
      puts "❌ No signing identity found for team #{TEAM_ID}"
      exit 1
    end
    
    puts "🔏 Signing with identity: #{identity}"
    
    # Create entitlements
    entitlements_path = "#{tmpdir}/entitlements.plist"
    File.write(entitlements_path, <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>application-identifier</key>
        <string>#{TEAM_ID}.#{BUNDLE_ID}</string>
        <key>com.apple.developer.team-identifier</key>
        <string>#{TEAM_ID}</string>
        <key>get-task-allow</key>
        <false/>
        <key>keychain-access-groups</key>
        <array>
          <string>#{TEAM_ID}.*</string>
        </array>
      </dict>
      </plist>
    XML
    
    # Re-sign the app
    puts "✍️  Re-signing app..."
    sign_cmd = "codesign -f -s '#{identity}' --entitlements '#{entitlements_path}' '#{app_path}'"
    
    if system(sign_cmd)
      # Re-create IPA
      output_ipa = "build/HomeInventoryModular-1.0.6-signed.ipa"
      puts "📦 Creating signed IPA..."
      
      Dir.chdir(tmpdir) do
        system("zip -qr '#{File.expand_path(output_ipa)}' Payload/")
      end
      
      if File.exist?(output_ipa)
        puts "✅ Successfully created signed IPA: #{output_ipa}"
        puts ""
        puts "📤 Now upload with:"
        puts "   xcrun altool --upload-app -f #{output_ipa} -t ios -u griffinradcliffe@gmail.com -p @keychain:AC_PASSWORD"
      end
    else
      puts "❌ Failed to re-sign app"
    end
  else
    puts "❌ No suitable provisioning profile found"
  end
end
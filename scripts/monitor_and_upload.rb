#!/usr/bin/env ruby

require 'fileutils'
require 'time'

# Configuration
ARCHIVE_PATH = "#{ENV['HOME']}/Library/Developer/Xcode/Archives"
USERNAME = 'griffinradcliffe@gmail.com'
PASSWORD = 'lyto-qjbu-uffy-hsgb'
TEAM_ID = '2VXBQV4XC9'

puts "🔍 Monitoring for new archives..."
puts "================================"
puts ""
puts "Instructions:"
puts "1. In Xcode, select 'Any iOS Device (arm64)' as destination"
puts "2. Go to Product → Archive"
puts "3. This script will automatically detect and upload the archive"
puts ""
puts "Waiting for archive creation..."

# Get current archives
existing_archives = Dir.glob("#{ARCHIVE_PATH}/**/*.xcarchive").map { |f| File.mtime(f) }
latest_existing = existing_archives.max || Time.at(0)

# Monitor for new archive
start_time = Time.now
found = false

while !found && (Time.now - start_time) < 600 # 10 minute timeout
  sleep 2
  
  # Check for new archives
  current_archives = Dir.glob("#{ARCHIVE_PATH}/**/*.xcarchive")
  new_archives = current_archives.select { |f| File.mtime(f) > latest_existing }
  
  if !new_archives.empty?
    archive = new_archives.first
    puts ""
    puts "✅ Found new archive: #{File.basename(archive)}"
    found = true
    
    # Export IPA from archive
    puts "📦 Exporting IPA from archive..."
    
    export_options = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>method</key>
        <string>app-store</string>
        <key>teamID</key>
        <string>#{TEAM_ID}</string>
        <key>uploadSymbols</key>
        <true/>
        <key>signingStyle</key>
        <string>automatic</string>
      </dict>
      </plist>
    XML
    
    export_plist = "/tmp/export_options.plist"
    File.write(export_plist, export_options)
    
    export_path = "/tmp/testflight_export"
    FileUtils.rm_rf(export_path)
    
    export_cmd = [
      "xcodebuild",
      "-exportArchive",
      "-archivePath", archive,
      "-exportPath", export_path,
      "-exportOptionsPlist", export_plist
    ]
    
    puts "Exporting..."
    if system(*export_cmd)
      ipa_path = Dir.glob("#{export_path}/*.ipa").first
      
      if ipa_path
        puts "✅ IPA exported: #{File.basename(ipa_path)}"
        puts ""
        puts "📤 Uploading to TestFlight..."
        
        upload_cmd = [
          "xcrun", "altool",
          "--upload-app",
          "-f", ipa_path,
          "-t", "ios",
          "-u", USERNAME,
          "-p", PASSWORD
        ]
        
        if system(*upload_cmd)
          puts ""
          puts "🎉 Successfully uploaded to TestFlight!"
          puts ""
          puts "📱 Next steps:"
          puts "1. Go to https://appstoreconnect.apple.com"
          puts "2. Wait for processing (5-10 minutes)"
          puts "3. Add release notes for v1.0.6"
          puts "4. Enable TestFlight testing"
          
          # Clean up
          FileUtils.rm_rf(export_path)
          File.delete(export_plist)
        else
          puts "❌ Upload failed"
        end
      else
        puts "❌ No IPA found in export"
      end
    else
      puts "❌ Export failed"
    end
  else
    print "."
    $stdout.flush
  end
end

if !found
  puts ""
  puts "⏰ Timeout waiting for archive"
  puts "Please ensure you're creating an archive in Xcode"
end
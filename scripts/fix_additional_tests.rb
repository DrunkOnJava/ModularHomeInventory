#!/usr/bin/env ruby

require 'fileutils'

# Fix the helper view conflicts in additional tests
test_files = {
  'NotificationsSnapshotTests' => 'Notifications',
  'SharingExportSnapshotTests' => 'SharingExport',
  'ErrorStatesSnapshotTests' => 'ErrorStates',
  'LoadingStatesSnapshotTests' => 'LoadingStates',
  'AccessibilitySnapshotTests' => 'Accessibility',
  'TabletLayoutSnapshotTests' => 'TabletLayout'
}

test_files.each do |test_name, prefix|
  file_path = "HomeInventoryModularTests/AdditionalTests/#{test_name}.swift"
  
  if File.exist?(file_path)
    content = File.read(file_path)
    
    # Replace helper view names with prefixed versions
    content.gsub!(/struct ErrorStateView: View/, "struct #{prefix}ErrorStateView: View")
    content.gsub!(/struct LoadingStateView: View/, "struct #{prefix}LoadingStateView: View")
    content.gsub!(/struct SkeletonView: View/, "struct #{prefix}SkeletonView: View")
    
    # Update references to use prefixed names
    content.gsub!(/ErrorStateView\(/, "#{prefix}ErrorStateView(")
    content.gsub!(/LoadingStateView\(/, "#{prefix}LoadingStateView(")
    content.gsub!(/SkeletonView\(/, "#{prefix}SkeletonView(")
    
    # Fix TabletLayoutSnapshotTests specific issues
    if test_name == 'TabletLayoutSnapshotTests'
      # Fix missing return statements
      content.gsub!(/(private func createMasterDetailView\(\) -> some View \{)(\s*NavigationView \{[^}]*\})\s*(\})/) do |match|
        "#{$1}\n        #{$2}\n    #{$3}"
      end
      
      content.gsub!(/(private func createMultiColumnView\(\) -> some View \{)(\s*GeometryReader[^}]*\})\s*(\})/) do |match|
        "#{$1}\n        #{$2}\n    #{$3}"
      end
      
      content.gsub!(/(private func createCompactAdaptiveView\(\) -> some View \{)(\s*VStack[^}]*\})\s*(\})/) do |match|
        "#{$1}\n        #{$2}\n    #{$3}"
      end
    end
    
    File.write(file_path, content)
    puts "✅ Fixed #{test_name}"
  else
    puts "❌ File not found: #{file_path}"
  end
end

puts "\n✅ Done fixing additional tests!"
puts "\nNow you can run the tests again:"
puts "  RECORD_SNAPSHOTS=YES ./scripts/test-runners/test-[group].sh"
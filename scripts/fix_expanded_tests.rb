#!/usr/bin/env ruby

require 'fileutils'

# Fix each expanded test file
expanded_tests_dir = 'HomeInventoryModularTests/ExpandedTests'
Dir.glob(File.join(expanded_tests_dir, '*SnapshotTests.swift')).each do |file_path|
  puts "Fixing #{File.basename(file_path)}..."
  
  content = File.read(file_path)
  
  # Fix the combined view generation issue - the Ruby script was adding extra braces
  content.gsub!(/^TAB\n    result = content\n  end\n  \n  result = <<-COMBINED/, 'TAB\n    content\n  end\n  \n  content + <<-COMBINED')
  
  # Fix the createCombinedView method
  test_name = File.basename(file_path, '.swift')
  views = case test_name
  when 'EmptyStatesSnapshotTests'
    ['NoItems', 'NoSearchResults', 'NoNotifications', 'NoBackups', 'NoCollections']
  when 'SuccessStatesSnapshotTests'
    ['ItemAdded', 'BackupComplete', 'ExportSuccess', 'SyncComplete', 'PaymentSuccess']
  when 'FormValidationSnapshotTests'
    ['AddItemForm', 'EditItemForm', 'LoginForm', 'SettingsForm', 'FeedbackForm']
  when 'ModalsAndSheetsSnapshotTests'
    ['ActionSheet', 'ConfirmationDialog', 'DetailModal', 'FilterSheet', 'SortOptions']
  when 'OnboardingFlowSnapshotTests'
    ['Welcome', 'Features', 'Permissions', 'AccountSetup', 'Completion']
  when 'SettingsVariationsSnapshotTests'
    ['GeneralSettings', 'PrivacySettings', 'NotificationPrefs', 'DataAndStorage', 'AboutScreen']
  when 'InteractionStatesSnapshotTests'
    ['SwipeActions', 'LongPress', 'DragAndDrop', 'PullToRefresh', 'ContextMenu']
  when 'DataVisualizationSnapshotTests'
    ['Charts', 'Graphs', 'Statistics', 'Timeline', 'Heatmap']
  else
    []
  end
  
  # Generate proper createCombinedView method
  combined_view = "    private func createCombinedView() -> some View {\n        TabView {\n"
  views.each_with_index do |view, index|
    icon = case view
    when 'NoItems' then 'tray'
    when 'NoSearchResults' then 'magnifyingglass'
    when 'NoNotifications' then 'bell.slash'
    when 'NoBackups' then 'icloud.slash'
    when 'NoCollections' then 'folder'
    when 'ItemAdded' then 'checkmark.circle.fill'
    when 'BackupComplete' then 'icloud.and.arrow.up'
    when 'ExportSuccess' then 'square.and.arrow.up'
    when 'SyncComplete' then 'arrow.triangle.2.circlepath'
    when 'PaymentSuccess' then 'creditcard.fill'
    when 'AddItemForm' then 'plus.square'
    when 'EditItemForm' then 'pencil'
    when 'LoginForm' then 'person.circle'
    when 'SettingsForm' then 'gearshape'
    when 'FeedbackForm' then 'bubble.left'
    when 'ActionSheet' then 'ellipsis.circle'
    when 'ConfirmationDialog' then 'questionmark.circle'
    when 'DetailModal' then 'info.circle'
    when 'FilterSheet' then 'line.horizontal.3.decrease.circle'
    when 'SortOptions' then 'arrow.up.arrow.down'
    when 'Welcome' then 'hand.wave'
    when 'Features' then 'star'
    when 'Permissions' then 'lock.shield'
    when 'AccountSetup' then 'person.crop.circle.badge.plus'
    when 'Completion' then 'checkmark.seal'
    when 'GeneralSettings' then 'gearshape'
    when 'PrivacySettings' then 'hand.raised'
    when 'NotificationPrefs' then 'bell'
    when 'DataAndStorage' then 'externaldrive'
    when 'AboutScreen' then 'info.circle'
    when 'SwipeActions' then 'hand.draw'
    when 'LongPress' then 'hand.tap'
    when 'DragAndDrop' then 'arrow.up.and.down.and.arrow.left.and.right'
    when 'PullToRefresh' then 'arrow.clockwise'
    when 'ContextMenu' then 'contextualmenu.and.cursorarrow'
    when 'Charts' then 'chart.bar'
    when 'Graphs' then 'chart.line.uptrend.xyaxis'
    when 'Statistics' then 'percent'
    when 'Timeline' then 'calendar'
    when 'Heatmap' then 'square.grid.3x3'
    else 'questionmark'
    end
    
    combined_view += "            create#{view}View()\n"
    combined_view += "                .tabItem {\n"
    combined_view += "                    Label(\"#{view}\", systemImage: \"#{icon}\")\n"
    combined_view += "                }\n"
    combined_view += "                .tag(#{index})\n"
    combined_view += "            \n" if index < views.length - 1
  end
  combined_view += "        }\n    }\n"
  
  # Replace the problematic createCombinedView section
  if content =~ /private func createCombinedView\(\) -> some View \{.*?\n    \}\n/m
    content.sub!(/private func createCombinedView\(\) -> some View \{.*?\n    \}\n/m, combined_view)
  else
    # Insert it before the closing brace of the class
    insert_pos = content.rindex(/\n\}\n\n\/\/ MARK: - Helper Views/)
    if insert_pos
      content.insert(insert_pos, "\n    \n#{combined_view}")
    end
  end
  
  # Fix duplicate extension and structs - make them unique per file
  prefix = test_name.gsub('SnapshotTests', '')
  
  # Remove duplicate cornerRadius extension and RoundedCorner struct
  content.gsub!(/extension View \{.*?func cornerRadius.*?\}\s*\}\s*struct RoundedCorner: Shape \{.*?\}\s*\}/m, '')
  
  # Add the extension and struct once at the end if not present
  unless content.include?("#{prefix}RoundedCorner")
    corner_extension = <<-SWIFT

extension View {
    func #{prefix}CornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(#{prefix}RoundedCorner(radius: radius, corners: corners))
    }
}

struct #{prefix}RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
SWIFT
    
    # Insert before final closing brace
    final_brace = content.rindex(/^}$/)
    if final_brace
      content.insert(final_brace, corner_extension)
    end
  end
  
  # Update cornerRadius calls to use the prefixed version
  content.gsub!(/\.cornerRadius\((\d+), corners: \[(.*?)\]\)/, '.#{prefix}CornerRadius(\1, corners: [\2])')
  
  # Fix FeatureRow usage in OnboardingFlowSnapshotTests
  if test_name == 'OnboardingFlowSnapshotTests'
    # The FeatureRow needs to use the correct helper struct
    content.gsub!(/FeatureRow\(icon:/, "#{prefix}FeatureRow(icon:")
  end
  
  # Remove any extraneous closing braces at the end
  content.gsub!(/\}\s*\}\s*\z/, "}\n")
  
  File.write(file_path, content)
end

puts "✅ Fixed all expanded test files!"
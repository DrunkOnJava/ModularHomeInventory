#!/usr/bin/env ruby

# Read the file
file_path = "HomeInventoryModularTests/AdditionalTests/TabletLayoutSnapshotTests.swift"
content = File.read(file_path)

# Find the problematic section starting from createCompactAdaptiveLoadingView
if match = content.match(/(private func createCompactAdaptiveLoadingView.*?)(\n\s*private func createCompactAdaptiveRefreshingView)/m)
  before_section = content[0...content.index(match[0])]
  after_section = content[(content.index(match[0]) + match[1].length)..-1]
  
  # Correct the createCompactAdaptiveLoadingView function
  fixed_loading_view = <<-SWIFT
private func createCompactAdaptiveLoadingView() -> some View {
        TabletLayoutLoadingStateView(
            message: "Loading CompactAdaptive...",
            progress: 0.6
        )
    }
    
SWIFT
  
  # Reconstruct the file
  content = before_section + fixed_loading_view + after_section
  
  File.write(file_path, content)
  puts "✅ Fixed TabletLayoutSnapshotTests structure"
else
  puts "❌ Could not find the problematic section"
end

# Now add the helper structs at the end of the file before the final closing brace
if content.match(/^}$/)
  # Remove the last closing brace
  lines = content.split("\n")
  last_brace_index = lines.rindex("}")
  
  # Insert the helper structs before the last brace
  helper_structs = <<-SWIFT

// MARK: - Helper Structs for createMultiColumnView

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Helper Structs for createCompactAdaptiveView

struct CompactItemRow: View {
    let index: Int
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(Text("\\(index + 1)"))
            VStack(alignment: .leading) {
                Text("Item \\(index + 1)")
                    .font(.headline)
                Text("Compact layout")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("$\\(50 * (index + 1))")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct ItemCard: View {
    let index: Int
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(Text("\\(index + 1)").font(.largeTitle))
            Text("Item \\(index + 1)")
                .font(.headline)
            Text("$\\(50 * (index + 1))")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
SWIFT
  
  lines.insert(last_brace_index, helper_structs)
  
  File.write(file_path, lines.join("\n"))
  puts "✅ Added helper structs"
end
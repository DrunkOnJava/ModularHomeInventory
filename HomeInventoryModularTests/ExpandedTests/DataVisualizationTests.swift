import XCTest
import SnapshotTesting
import SwiftUI

final class DataVisualizationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        isRecording = false
    }
    
    func testChartsView() {
        let view = ChartsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testStatisticsView() {
        let view = StatisticsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testTimelineView() {
        let view = TimelineView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13ProMax))
    }
    
    func testHeatmapView() {
        let view = HeatmapView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct ChartsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary cards
                    HStack(spacing: 16) {
                        StatCard(title: "Total Value", value: "$12,450", trend: "+15%", color: .green)
                        StatCard(title: "Items", value: "234", trend: "+8", color: .blue)
                    }
                    .padding(.horizontal)
                    
                    // Bar chart
                    VStack(alignment: .leading) {
                        Text("Value by Category")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            BarChartRow(category: "Electronics", value: 0.8, amount: "$4,200", color: .blue)
                            BarChartRow(category: "Furniture", value: 0.6, amount: "$3,100", color: .green)
                            BarChartRow(category: "Clothing", value: 0.4, amount: "$2,050", color: .orange)
                            BarChartRow(category: "Books", value: 0.3, amount: "$1,540", color: .purple)
                            BarChartRow(category: "Other", value: 0.3, amount: "$1,560", color: .gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Line chart placeholder
                    VStack(alignment: .leading) {
                        Text("Value Over Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                            
                            // Simulated line chart
                            Path { path in
                                path.move(to: CGPoint(x: 20, y: 150))
                                path.addLine(to: CGPoint(x: 80, y: 120))
                                path.addLine(to: CGPoint(x: 140, y: 80))
                                path.addLine(to: CGPoint(x: 200, y: 90))
                                path.addLine(to: CGPoint(x: 260, y: 40))
                                path.addLine(to: CGPoint(x: 320, y: 60))
                            }
                            .stroke(Color.blue, lineWidth: 3)
                            .padding()
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 4) {
                Image(systemName: trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(trend)
                    .font(.caption2)
            }
            .foregroundColor(trend.hasPrefix("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BarChartRow: View {
    let category: String
    let value: Double
    let amount: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(category)
                    .font(.subheadline)
                Spacer()
                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 20)
                }
            }
            .frame(height: 20)
        }
    }
}

struct StatisticsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Key metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(icon: "dollarsign.circle", title: "Total Value", value: "$12,450", color: .green)
                    MetricCard(icon: "shippingbox", title: "Total Items", value: "234", color: .blue)
                    MetricCard(icon: "star.fill", title: "Favorites", value: "18", color: .yellow)
                    MetricCard(icon: "clock", title: "Avg. Age", value: "2.3 yrs", color: .orange)
                }
                .padding(.horizontal)
                
                // Distribution chart
                VStack(alignment: .leading) {
                    Text("Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 4) {
                        DistributionBar(percentage: 0.35, color: .blue)
                        DistributionBar(percentage: 0.25, color: .green)
                        DistributionBar(percentage: 0.20, color: .orange)
                        DistributionBar(percentage: 0.12, color: .purple)
                        DistributionBar(percentage: 0.08, color: .gray)
                    }
                    .frame(height: 100)
                    .padding(.horizontal)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        LegendItem(color: .blue, label: "Electronics (35%)")
                        LegendItem(color: .green, label: "Furniture (25%)")
                        LegendItem(color: .orange, label: "Clothing (20%)")
                        LegendItem(color: .purple, label: "Books (12%)")
                        LegendItem(color: .gray, label: "Other (8%)")
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DistributionBar: View {
    let percentage: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: geometry.size.height * percentage)
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
        }
    }
}

struct TimelineView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<8) { index in
                        TimelineItem(
                            date: dateForIndex(index),
                            title: titleForIndex(index),
                            subtitle: subtitleForIndex(index),
                            icon: iconForIndex(index),
                            color: colorForIndex(index),
                            isLast: index == 7
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func dateForIndex(_ index: Int) -> String {
        ["Today", "Yesterday", "3 days ago", "1 week ago", "2 weeks ago", "1 month ago", "2 months ago", "3 months ago"][index]
    }
    
    func titleForIndex(_ index: Int) -> String {
        ["Added MacBook Pro", "Updated Insurance", "Exported Backup", "Added 5 items", "Created Collection", "Warranty Expired", "Monthly Review", "Started Inventory"][index]
    }
    
    func subtitleForIndex(_ index: Int) -> String {
        ["Electronics • $2,499", "Policy updated", "234 items backed up", "Total value +$450", "Home Office", "iPhone 12 warranty", "Generated report", "Welcome!"][index]
    }
    
    func iconForIndex(_ index: Int) -> String {
        ["plus.circle", "shield", "icloud.and.arrow.up", "shippingbox", "folder", "exclamationmark.triangle", "doc.text", "star"][index]
    }
    
    func colorForIndex(_ index: Int) -> Color {
        [.blue, .green, .purple, .blue, .orange, .red, .gray, .yellow][index]
    }
}

struct TimelineItem: View {
    let date: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line and dot
            VStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 3)
                            .frame(width: 20, height: 20)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 80)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.headline)
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 24)
            
            Spacer()
        }
    }
}

struct HeatmapView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Activity Heatmap")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Items added per day")
                .foregroundColor(.secondary)
            
            // Month grid
            VStack(spacing: 4) {
                // Days of week header
                HStack(spacing: 4) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .frame(width: 40, height: 20)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Calendar grid
                ForEach(0..<5) { week in
                    HStack(spacing: 4) {
                        ForEach(0..<7) { day in
                            HeatmapCell(intensity: Double((week * 7 + day) % 5) / 4.0)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Legend
            HStack(spacing: 16) {
                Text("Less")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                        HeatmapCell(intensity: intensity)
                            .frame(width: 15, height: 15)
                    }
                }
                
                Text("More")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            HStack(spacing: 40) {
                VStack {
                    Text("23")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total this month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("3.2")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Daily average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

struct HeatmapCell: View {
    let intensity: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(colorForIntensity(intensity))
            .frame(width: 40, height: 40)
    }
    
    func colorForIntensity(_ intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.systemGray5)
        } else if intensity < 0.25 {
            return Color.green.opacity(0.3)
        } else if intensity < 0.5 {
            return Color.green.opacity(0.5)
        } else if intensity < 0.75 {
            return Color.green.opacity(0.7)
        } else {
            return Color.green
        }
    }
}
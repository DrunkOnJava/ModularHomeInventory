import XCTest
import SnapshotTesting
import SwiftUI

final class InteractionStatesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set isRecording = true to generate new snapshots
        // isRecording = true
    }
    
    func testSwipeActionsView() {
        let view = SwipeActionsView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testLongPressMenuView() {
        let view = LongPressMenuView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
    
    func testDragAndDropView() {
        let view = DragAndDropView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
        assertSnapshot(of: hostingController, as: .image(on: .iPadPro11))
    }
    
    func testPullToRefreshView() {
        let view = PullToRefreshView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13))
    }
}

// MARK: - Helper Views

struct SwipeActionsView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<5) { index in
                    SwipeableRow(
                        title: "Item \(index + 1)",
                        subtitle: "$\(50 * (index + 1))",
                        leadingActions: [
                            SwipeAction(icon: "star.fill", color: .yellow),
                            SwipeAction(icon: "pin.fill", color: .blue)
                        ],
                        trailingActions: [
                            SwipeAction(icon: "trash.fill", color: .red)
                        ]
                    )
                }
            }
            .navigationTitle("Swipe Actions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SwipeableRow: View {
    let title: String
    let subtitle: String
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    
    var body: some View {
        HStack {
            // Leading actions
            HStack(spacing: 0) {
                ForEach(leadingActions.indices, id: \.self) { index in
                    leadingActions[index]
                }
            }
            .opacity(0.8)
            
            // Main content
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .offset(x: -60)
            
            // Trailing actions
            HStack(spacing: 0) {
                ForEach(trailingActions.indices, id: \.self) { index in
                    trailingActions[index]
                }
            }
        }
    }
}

struct SwipeAction: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(color)
    }
}

struct LongPressMenuView: View {
    var body: some View {
        ZStack {
            // Background list
            List {
                ForEach(0..<8) { index in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading) {
                            Text("Item \(index + 1)")
                                .font(.headline)
                            Text("Tap and hold for options")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .opacity(index == 2 ? 0.3 : 1.0)
                }
            }
            
            // Context menu overlay
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    VStack(alignment: .leading) {
                        Text("Item 3")
                            .font(.headline)
                        Text("Tap and hold for options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray3).opacity(0.5))
                .cornerRadius(12)
                .scaleEffect(0.95)
                
                VStack(spacing: 0) {
                    ContextMenuItem(icon: "square.and.arrow.up", title: "Share")
                    ContextMenuItem(icon: "star", title: "Favorite")
                    ContextMenuItem(icon: "tag", title: "Add Tags")
                    ContextMenuItem(icon: "trash", title: "Delete", isDestructive: true)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 20)
            }
            .padding()
        }
    }
}

struct ContextMenuItem: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
            Text(title)
            Spacer()
        }
        .padding()
        .foregroundColor(isDestructive ? .red : .primary)
        if title != "Delete" {
            Divider()
        }
    }
}

struct DragAndDropView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Drag & Drop")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Source items
            VStack(alignment: .leading) {
                Text("Drag items from here...")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<5) { index in
                            DraggableItem(index: index)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Drop zone
            VStack {
                Text("...to here")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.blue)
                        .frame(height: 200)
                    
                    VStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Drop items here")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

struct DraggableItem: View {
    let index: Int
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("\(index + 1)")
                        .font(.title2)
                        .fontWeight(.bold)
                )
            Text("Item \(index + 1)")
                .font(.caption)
        }
        .opacity(index == 1 ? 0.5 : 1.0)
        .scaleEffect(index == 1 ? 0.9 : 1.0)
    }
}

struct PullToRefreshView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Refresh indicator
            HStack {
                Spacer()
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Refreshing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            
            // List content
            List {
                ForEach(0..<10) { index in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Updated Item \(index + 1)")
                                .font(.headline)
                            Text("Just now")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if index < 3 {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            .offset(y: 20)
            .opacity(0.6)
        }
    }
}
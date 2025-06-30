#!/usr/bin/env swift

import Foundation
import SwiftUI
import SnapshotTesting

// Simple test to generate a snapshot
let view = Text("Hello Snapshot!")
    .font(.largeTitle)
    .padding()
    .background(Color.blue)
    .foregroundColor(.white)

let hostingController = UIHostingController(rootView: view)
hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 100)

// Force layout
hostingController.view.layoutIfNeeded()

// Create image
let renderer = UIGraphicsImageRenderer(size: hostingController.view.bounds.size)
let image = renderer.image { context in
    hostingController.view.layer.render(in: context.cgContext)
}

// Save image
let data = image.pngData()!
let url = URL(fileURLWithPath: "snapshot_test.png")
try! data.write(to: url)

print("Snapshot saved to: \(url.path)")
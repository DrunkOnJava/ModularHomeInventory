#!/usr/bin/env swift

import Foundation
import QuartzCore

// ANSI color codes
let BLUE = "\u{001B}[34m"
let GREEN = "\u{001B}[32m"
let RESET = "\u{001B}[0m"

print("\(BLUE)🎨 Generating SwiftUI Component Mock Snapshots\(RESET)")
print("=" * 50)

// Create snapshots directory
let currentPath = FileManager.default.currentDirectoryPath
let snapshotsPath = "\(currentPath)/snapshots"
try? FileManager.default.createDirectory(atPath: snapshotsPath, withIntermediateDirectories: true)

// Generate mock snapshot images using Core Graphics
func createMockSnapshot(name: String, width: Int, height: Int, content: (CGContext) -> Void) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else { return }
    
    // White background
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Draw content
    content(context)
    
    // Save image
    if let image = context.makeImage() {
        let url = URL(fileURLWithPath: "\(snapshotsPath)/\(name).png")
        if let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil) {
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
            print("\(GREEN)✅ Generated: \(name).png\(RESET)")
        }
    }
}

// 1. SearchBar Empty
createMockSnapshot(name: "SearchBar_Empty", width: 375, height: 60) { ctx in
    // Gray background
    ctx.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 10, y: 10, width: 355, height: 40))
    
    // Magnifying glass icon (circle + line)
    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: CGRect(x: 20, y: 20, width: 20, height: 20))
    ctx.move(to: CGPoint(x: 38, y: 38))
    ctx.addLine(to: CGPoint(x: 45, y: 45))
    ctx.strokePath()
    
    // Placeholder text
    ctx.setFillColor(CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
    let placeholderText = "Search items..." as NSString
    placeholderText.draw(at: CGPoint(x: 55, y: 22), withAttributes: [
        .font: NSFont.systemFont(ofSize: 16),
        .foregroundColor: NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    ])
}

// 2. SearchBar With Text
createMockSnapshot(name: "SearchBar_WithText", width: 375, height: 60) { ctx in
    // Gray background
    ctx.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 10, y: 10, width: 355, height: 40))
    
    // Magnifying glass icon
    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: CGRect(x: 20, y: 20, width: 20, height: 20))
    ctx.move(to: CGPoint(x: 38, y: 38))
    ctx.addLine(to: CGPoint(x: 45, y: 45))
    ctx.strokePath()
    
    // Text
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    let text = "MacBook Pro" as NSString
    text.draw(at: CGPoint(x: 55, y: 22), withAttributes: [
        .font: NSFont.systemFont(ofSize: 16),
        .foregroundColor: NSColor.black
    ])
    
    // X button (circle with X)
    ctx.setFillColor(CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 335, y: 20, width: 20, height: 20))
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(2)
    ctx.move(to: CGPoint(x: 340, y: 25))
    ctx.addLine(to: CGPoint(x: 350, y: 35))
    ctx.move(to: CGPoint(x: 350, y: 25))
    ctx.addLine(to: CGPoint(x: 340, y: 35))
    ctx.strokePath()
}

// 3. PrimaryButton Default
createMockSnapshot(name: "PrimaryButton_Default", width: 200, height: 60) { ctx in
    // Blue button background
    ctx.setFillColor(CGColor(red: 0, green: 0.478, blue: 1, alpha: 1))
    let buttonRect = CGRect(x: 10, y: 10, width: 180, height: 40)
    let path = CGPath(roundedRect: buttonRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
    
    // White text
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let buttonText = "Add Item" as NSString
    let textSize = buttonText.size(withAttributes: [.font: NSFont.boldSystemFont(ofSize: 16)])
    let textX = buttonRect.midX - textSize.width / 2
    let textY = buttonRect.midY - textSize.height / 2
    buttonText.draw(at: CGPoint(x: textX, y: textY), withAttributes: [
        .font: NSFont.boldSystemFont(ofSize: 16),
        .foregroundColor: NSColor.white
    ])
}

// 4. PrimaryButton Loading
createMockSnapshot(name: "PrimaryButton_Loading", width: 200, height: 60) { ctx in
    // Blue button background
    ctx.setFillColor(CGColor(red: 0, green: 0.478, blue: 1, alpha: 1))
    let buttonRect = CGRect(x: 10, y: 10, width: 180, height: 40)
    let path = CGPath(roundedRect: buttonRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
    
    // Spinner (circle)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: CGRect(x: 60, y: 20, width: 20, height: 20))
    
    // White text
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let buttonText = "Saving..." as NSString
    buttonText.draw(at: CGPoint(x: 90, y: 22), withAttributes: [
        .font: NSFont.boldSystemFont(ofSize: 16),
        .foregroundColor: NSColor.white
    ])
}

// 5. LoadingOverlay
createMockSnapshot(name: "LoadingOverlay", width: 300, height: 300) { ctx in
    // Semi-transparent overlay
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.4))
    ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
    
    // White card
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let cardRect = CGRect(x: 75, y: 100, width: 150, height: 100)
    let path = CGPath(roundedRect: cardRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
    
    // Spinner
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    ctx.setLineWidth(3)
    ctx.strokeEllipse(in: CGRect(x: 135, y: 125, width: 30, height: 30))
    
    // Text
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    let text = "Processing..." as NSString
    let textSize = text.size(withAttributes: [.font: NSFont.systemFont(ofSize: 14)])
    let textX = cardRect.midX - textSize.width / 2
    text.draw(at: CGPoint(x: textX, y: 165), withAttributes: [
        .font: NSFont.systemFont(ofSize: 14),
        .foregroundColor: NSColor.black
    ])
}

// 6. Settings Section
createMockSnapshot(name: "Settings_ScannerSection", width: 375, height: 250) { ctx in
    // Section header background
    ctx.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 375, height: 40))
    
    // Section title
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    let title = "Scanner Settings" as NSString
    title.draw(at: CGPoint(x: 20, y: 10), withAttributes: [
        .font: NSFont.boldSystemFont(ofSize: 18),
        .foregroundColor: NSColor.black
    ])
    
    // Settings rows
    let rows = [
        ("speaker.wave.2", "Sound Effects", true),
        ("iphone.radiowaves.left.and.right", "Haptic Feedback", true),
        ("square.and.arrow.down", "Auto-Save Scans", false)
    ]
    
    var y = 50
    for (icon, label, isOn) in rows {
        // Row background
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 10, y: y, width: 355, height: 60))
        
        // Icon placeholder
        ctx.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))
        ctx.fill(CGRect(x: 20, y: y + 20, width: 20, height: 20))
        
        // Label
        let labelText = label as NSString
        labelText.draw(at: CGPoint(x: 50, y: y + 20), withAttributes: [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.black
        ])
        
        // Toggle
        ctx.setFillColor(isOn ? CGColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1) : CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1))
        let toggleRect = CGRect(x: 315, y: y + 20, width: 40, height: 20)
        let togglePath = CGPath(roundedRect: toggleRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(togglePath)
        ctx.fillPath()
        
        // Toggle knob
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        let knobX = isOn ? 335 : 317
        ctx.fillEllipse(in: CGRect(x: knobX, y: y + 22, width: 16, height: 16))
        
        y += 65
    }
}

print("\n\(BLUE)📁 Snapshots saved to: \(snapshotsPath)\(RESET)")
print("=" * 50)

// List generated files
let files = try? FileManager.default.contentsOfDirectory(atPath: snapshotsPath)
    .filter { $0.hasSuffix(".png") }
    .sorted()

if let files = files {
    print("\n\(GREEN)Generated files:\(RESET)")
    for file in files {
        print("  • \(file)")
    }
}

// String extension
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
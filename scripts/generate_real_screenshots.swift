#!/usr/bin/swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Create a simple colored rectangle as a placeholder image
func createPlaceholderImage(width: Int, height: Int, color: (r: CGFloat, g: CGFloat, b: CGFloat), text: String) -> CGImage? {
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
    ) else { return nil }
    
    // Fill with color
    context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Add border
    context.setStrokeColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    context.setLineWidth(4.0)
    context.stroke(CGRect(x: 2, y: 2, width: width - 4, height: height - 4))
    
    // Add text
    let textRect = CGRect(x: 20, y: height/2 - 30, width: width - 40, height: 60)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 36, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle
    ]
    
    let nsString = NSString(string: text)
    context.saveGState()
    
    // Create text path
    let path = CGMutablePath()
    path.addRect(textRect)
    
    // Draw text background
    context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    context.fill(CGRect(x: textRect.minX - 10, y: textRect.minY - 5, width: textRect.width + 20, height: textRect.height + 10))
    
    context.restoreGState()
    
    // Note: Drawing actual text requires NSGraphicsContext which isn't available in pure Swift
    // For now, we'll create distinctive colored rectangles
    
    return context.makeImage()
}

// Save CGImage as PNG
func saveImageAsPNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "Screenshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
    }
    
    CGImageDestinationAddImage(destination, image, nil)
    
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "Screenshot", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write image"])
    }
}

// Screenshot configurations
struct ScreenshotConfig {
    let name: String
    let width: Int
    let height: Int
    let color: (r: CGFloat, g: CGFloat, b: CGFloat)
}

// Main generation
func generateScreenshots() throws {
    let screenshotDir = FileManager.default.currentDirectoryPath + "/Screenshots"
    
    // Component screenshots (smaller, card-like)
    let componentConfigs = [
        ScreenshotConfig(name: "ItemCard", width: 350, height: 150, color: (0.2, 0.6, 0.9)),
        ScreenshotConfig(name: "EmptyState", width: 400, height: 300, color: (0.7, 0.7, 0.8)),
        ScreenshotConfig(name: "ItemsList", width: 350, height: 400, color: (0.3, 0.7, 0.5)),
        ScreenshotConfig(name: "StatsCard", width: 350, height: 200, color: (0.9, 0.5, 0.3)),
        ScreenshotConfig(name: "SettingsSection", width: 375, height: 250, color: (0.5, 0.5, 0.8)),
        ScreenshotConfig(name: "DetailHeader", width: 375, height: 180, color: (0.8, 0.3, 0.4))
    ]
    
    print("📸 Generating Component Screenshots...")
    for config in componentConfigs {
        if let image = createPlaceholderImage(
            width: config.width,
            height: config.height,
            color: config.color,
            text: config.name
        ) {
            let url = URL(fileURLWithPath: "\(screenshotDir)/Components/\(config.name).png")
            try saveImageAsPNG(image, to: url)
            print("  ✅ Generated \(config.name).png (\(config.width)x\(config.height))")
        }
    }
    
    // App flow screenshots (iPhone size)
    let flowConfigs = [
        ScreenshotConfig(name: "01_ItemsList", width: 393, height: 852, color: (0.2, 0.4, 0.8)),
        ScreenshotConfig(name: "02_AddItem", width: 393, height: 852, color: (0.3, 0.7, 0.4)),
        ScreenshotConfig(name: "03_BarcodeScanner", width: 393, height: 852, color: (0.8, 0.2, 0.2)),
        ScreenshotConfig(name: "04_ItemDetail", width: 393, height: 852, color: (0.5, 0.3, 0.7)),
        ScreenshotConfig(name: "05_Receipts", width: 393, height: 852, color: (0.9, 0.6, 0.2)),
        ScreenshotConfig(name: "06_Analytics", width: 393, height: 852, color: (0.4, 0.8, 0.6)),
        ScreenshotConfig(name: "07_Settings", width: 393, height: 852, color: (0.6, 0.6, 0.6)),
        ScreenshotConfig(name: "08_Premium", width: 393, height: 852, color: (0.8, 0.5, 0.9))
    ]
    
    print("\n📱 Generating App Flow Screenshots...")
    for config in flowConfigs {
        if let image = createPlaceholderImage(
            width: config.width,
            height: config.height,
            color: config.color,
            text: config.name
        ) {
            let url = URL(fileURLWithPath: "\(screenshotDir)/AppFlow/\(config.name).png")
            try saveImageAsPNG(image, to: url)
            print("  ✅ Generated \(config.name).png (\(config.width)x\(config.height))")
        }
    }
    
    // App Store screenshots (various device sizes)
    let deviceConfigs = [
        (device: "iPhone_16_Pro_Max", width: 430, height: 932),
        (device: "iPhone_16_Pro", width: 393, height: 852),
        (device: "iPad_Pro_13", width: 1024, height: 1366)
    ]
    
    print("\n📲 Generating App Store Screenshots...")
    for deviceConfig in deviceConfigs {
        let deviceDir = "\(screenshotDir)/AppStore/\(deviceConfig.device)"
        
        for i in 1...5 {
            let color = (
                r: CGFloat(i) * 0.2,
                g: CGFloat(6 - i) * 0.2,
                b: 0.5
            )
            
            if let image = createPlaceholderImage(
                width: deviceConfig.width,
                height: deviceConfig.height,
                color: color,
                text: "Screen \(i)"
            ) {
                let url = URL(fileURLWithPath: "\(deviceDir)/screenshot_\(i).png")
                try saveImageAsPNG(image, to: url)
            }
        }
        print("  ✅ Generated \(deviceConfig.device) screenshots (\(deviceConfig.width)x\(deviceConfig.height))")
    }
    
    print("\n✅ All placeholder screenshots generated with actual image data!")
}

// Run the generator
do {
    try generateScreenshots()
} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}
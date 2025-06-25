#!/usr/bin/swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Create a simple colored rectangle with pattern
func createPlaceholderImage(width: Int, height: Int, color: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGImage? {
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
    
    // Fill with gradient-like pattern
    context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Add some visual interest with rectangles
    context.setFillColor(red: color.r * 0.8, green: color.g * 0.8, blue: color.b * 0.8, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: width, height: 60))
    
    // Add border
    context.setStrokeColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    context.setLineWidth(4.0)
    context.stroke(CGRect(x: 2, y: 2, width: width - 4, height: height - 4))
    
    // Add some pattern elements
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
    for i in 0..<5 {
        let y = 100 + i * 80
        if y < height - 50 {
            context.fill(CGRect(x: 20, y: y, width: width - 40, height: 60))
        }
    }
    
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
            color: config.color
        ) {
            let url = URL(fileURLWithPath: "\(screenshotDir)/Components/\(config.name).png")
            try saveImageAsPNG(image, to: url)
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            print("  ✅ Generated \(config.name).png (\(config.width)x\(config.height), \(fileSize) bytes)")
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
            color: config.color
        ) {
            let url = URL(fileURLWithPath: "\(screenshotDir)/AppFlow/\(config.name).png")
            try saveImageAsPNG(image, to: url)
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            print("  ✅ Generated \(config.name).png (\(config.width)x\(config.height), \(fileSize) bytes)")
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
        
        // Create device directory
        try FileManager.default.createDirectory(atPath: deviceDir, withIntermediateDirectories: true, attributes: nil)
        
        for i in 1...5 {
            let color = (
                r: CGFloat(i) * 0.2,
                g: CGFloat(6 - i) * 0.2,
                b: CGFloat(0.5)
            )
            
            if let image = createPlaceholderImage(
                width: deviceConfig.width,
                height: deviceConfig.height,
                color: color
            ) {
                let url = URL(fileURLWithPath: "\(deviceDir)/screenshot_\(i).png")
                try saveImageAsPNG(image, to: url)
            }
        }
        let sampleFile = URL(fileURLWithPath: "\(deviceDir)/screenshot_1.png")
        let fileSize = try FileManager.default.attributesOfItem(atPath: sampleFile.path)[.size] as? Int ?? 0
        print("  ✅ Generated \(deviceConfig.device) screenshots (\(deviceConfig.width)x\(deviceConfig.height), ~\(fileSize) bytes each)")
    }
    
    print("\n✅ All placeholder screenshots generated with actual image data!")
    print("📁 Check Screenshots/ directory for PNG files with real image content")
}

// Run the generator
do {
    try generateScreenshots()
} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}
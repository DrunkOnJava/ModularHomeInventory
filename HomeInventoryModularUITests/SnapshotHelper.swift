//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//

// -----------------------------------------------------
// IMPORTANT: When modifying this file, make sure to
//            increment the version number at the very
//            bottom of the file to notify users about
//            the new SnapshotHelper.swift
// -----------------------------------------------------

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

/// - Parameters:
///   - name: The name of the snapshot
///   - timeout: Amount of seconds to wait until the network loading indicator disappears. Pass `0` if you don't want to wait.
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    Snapshot.snapshot(name, timeWaitingForIdle: timeout)
}

enum SnapshotError: Error, CustomDebugStringConvertible {
    case cannotFindSimulatorHomeDirectory
    case cannotRunOnPhysicalDevice

    var debugDescription: String {
        switch self {
        case .cannotFindSimulatorHomeDirectory:
            return "Couldn't find simulator home location. Please, check SIMULATOR_HOST_HOME env variable."
        case .cannotRunOnPhysicalDevice:
            return "Can't use Snapshot on a physical device."
        }
    }
}

@objcMembers
open class Snapshot: NSObject {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var screenshotsDirectory: URL? {
        // First try the cache directory approach
        if let cacheDir = cacheDirectory {
            return cacheDir.appendingPathComponent("screenshots", isDirectory: true)
        }
        
        // Fallback: Try to find the fastlane screenshots directory
        // This assumes we're running from the project root
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let fastlaneScreenshotsPath = "\(currentDir)/fastlane/screenshots"
        
        if fileManager.fileExists(atPath: fastlaneScreenshotsPath) {
            NSLog("DEBUG: Using direct fastlane screenshots path: \(fastlaneScreenshotsPath)")
            return URL(fileURLWithPath: fastlaneScreenshotsPath)
        }
        
        // Final fallback: Use NSHomeDirectory
        let homeDir = URL(fileURLWithPath: NSHomeDirectory())
        let homeScreenshotsPath = homeDir
            .appendingPathComponent("Library/Caches/tools.fastlane/screenshots")
        
        NSLog("DEBUG: Using home directory screenshots path: \(homeScreenshotsPath.path)")
        return homeScreenshotsPath
    }

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        NSLog("DEBUG: setupSnapshot called")
        
        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            NSLog("DEBUG: Attempting to get cache directory...")
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            NSLog("DEBUG: Cache directory set to: \(cacheDir.path)")
            NSLog("DEBUG: Screenshots directory will be: \(cacheDir.appendingPathComponent("screenshots", isDirectory: true).path)")
            
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
            
            NSLog("DEBUG: setupSnapshot completed successfully")
        } catch let error {
            NSLog("ERROR in setupSnapshot: \(error.localizedDescription)")
            NSLog("ERROR: Failed to setup snapshot properly")
        }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
            NSLog("DEBUG: Set language to: \(deviceLanguage)")
        } catch {
            NSLog("Couldn't detect/set language from file, using default")
            // If we're running with FASTLANE_LANGUAGE, use that
            if let fastlaneLanguage = ProcessInfo().environment["FASTLANE_LANGUAGE"] {
                deviceLanguage = fastlaneLanguage
                app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
                NSLog("DEBUG: Using FASTLANE_LANGUAGE: \(deviceLanguage)")
            }
        }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            NSLog("Couldn't detect/set locale...")
        }

        if locale.isEmpty && !deviceLanguage.isEmpty {
            locale = Locale(identifier: deviceLanguage).identifier
        }

        if !locale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
        }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: String.Encoding.utf8)
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matches(in: launchArguments, options: [], range: NSRange(location: 0, length: launchArguments.count))
            let results = matches.map { result -> String in
                (launchArguments as NSString).substring(with: result.range)
            }
            app.launchArguments += results
        } catch {
            NSLog("Couldn't detect/set launch_arguments...")
        }
    }

    open class func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        // Debug: Write to a file to verify this function is being called
        let debugPath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("fastlane_snapshot_debug.txt")
        let debugMessage = "[\(Date())] snapshot() called with name: \(name)\n"
        if let data = debugMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: debugPath.path) {
                if let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: debugPath)
            }
        }
        
        guard let app = app else {
            NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
            return
        }

        let networkLoadingIndicator = app.currentUnusedActivityIndicator()
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: networkLoadingIndicator)
        if timeout > 0 {
            _ = XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
        }

        if waitForAnimations {
            sleep(1) // Waiting for the animation to be finished (kind of)
        }

        NSLog("snapshot: \(name)") // more information about this, check out https://docs.fastlane.tools/actions/snapshot/#how-does-it-work

        sleep(1) // Waiting for the animation to be finished (kind of)

        #if os(OSX)
            guard let app = self.app else {
                NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
                return
            }

            app.typeKey(XCUIKeyboardKeySecondaryFn, modifierFlags: [])
        #else

            guard self.app != nil else {
                NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
                return
            }

            let screenshot = XCUIScreen.main.screenshot()
            #if os(iOS) && !targetEnvironment(macCatalyst)
            let image = XCUIDevice.shared.orientation.isLandscape ?  fixLandscapeOrientation(image: screenshot.image) : screenshot.image
            #else
            let image = screenshot.image
            #endif

            // Use the debug path from earlier in the function
            
            // Debug logging
            NSLog("DEBUG: Checking environment variables...")
            NSLog("DEBUG: SIMULATOR_DEVICE_NAME = \(ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] ?? "NOT SET")")
            NSLog("DEBUG: FASTLANE_SNAPSHOT = \(ProcessInfo().environment["FASTLANE_SNAPSHOT"] ?? "NOT SET")")
            NSLog("DEBUG: screenshotsDirectory = \(String(describing: screenshotsDirectory))")
            NSLog("DEBUG: cacheDirectory = \(String(describing: cacheDirectory))")
            
            // Write debug info to file
            let debugInfo = """
            [\(Date())] Screenshot saving attempt:
            - Name: \(name)
            - SIMULATOR_DEVICE_NAME: \(ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] ?? "NOT SET")
            - FASTLANE_SNAPSHOT: \(ProcessInfo().environment["FASTLANE_SNAPSHOT"] ?? "NOT SET")
            - screenshotsDirectory: \(String(describing: screenshotsDirectory))
            
            """
            if let data = debugInfo.data(using: .utf8),
               let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            
            // Get simulator name, with fallback
            var simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] ?? "iPhone 16 Pro Max"
            
            guard let baseScreenshotsDir = screenshotsDirectory else { 
                NSLog("ERROR: Failed to get screenshots directory")
                NSLog("ERROR: screenshotsDirectory = \(String(describing: screenshotsDirectory))")
                let errorInfo = "ERROR: Failed to get screenshots directory\n"
                if let data = errorInfo.data(using: .utf8),
                   let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
                return 
            }
            
            // Get the language for the subdirectory
            let language = ProcessInfo().environment["FASTLANE_LANGUAGE"] ?? (deviceLanguage.isEmpty ? "en-US" : deviceLanguage)
            let screenshotsDir = baseScreenshotsDir.appendingPathComponent(language)
            
            // Create screenshots directory if it doesn't exist
            try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true, attributes: nil)
            
            NSLog("DEBUG: Will save screenshots to: \(screenshotsDir.path)")

            do {
                // The simulator name contains "Clone X of " inside the screenshot file when running parallelized UI Tests on concurrent devices
                let regex = try NSRegularExpression(pattern: "Clone [0-9]+ of ")
                let range = NSRange(location: 0, length: simulator.count)
                simulator = regex.stringByReplacingMatches(in: simulator, range: range, withTemplate: "")

                let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")
                NSLog("DEBUG: Attempting to save screenshot to: \(path.path)")
                
                #if swift(<5.0)
                    try UIImagePNGRepresentation(image)?.write(to: path)
                #else
                    if let pngData = image.pngData() {
                        try pngData.write(to: path)
                        NSLog("SUCCESS: Screenshot saved to: \(path.path)")
                        
                        // Write success to debug file
                        let successInfo = "SUCCESS: Screenshot '\(name)' saved to: \(path.path)\n"
                        if let data = successInfo.data(using: .utf8),
                           let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        }
                    } else {
                        NSLog("ERROR: Failed to convert image to PNG data")
                        
                        // Write error to debug file
                        let errorInfo = "ERROR: Failed to convert image to PNG data for '\(name)'\n"
                        if let data = errorInfo.data(using: .utf8),
                           let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            fileHandle.closeFile()
                        }
                    }
                #endif
            } catch let error {
                NSLog("ERROR: Problem writing screenshot: \(name)")
                NSLog("ERROR: \(error.localizedDescription)")
                
                // Write error to debug file
                let errorInfo = "ERROR: Problem writing screenshot '\(name)': \(error.localizedDescription)\n"
                if let data = errorInfo.data(using: .utf8),
                   let fileHandle = try? FileHandle(forWritingTo: debugPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
        #endif
    }

    class func fixLandscapeOrientation(image: UIImage) -> UIImage {
        #if os(watchOS)
            return image
        #else
            if #available(iOS 16.0, tvOS 16.0, *) {
                guard image.imageOrientation != .up else { return image }
                UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                return normalizedImage
            } else {
                return image
            }
        #endif
    }

    class func getCacheDirectory() throws -> URL {
        let cachePath = "Library/Caches/tools.fastlane"
        // on OSX config is stored in /Users/<username>/Library
        // and on iOS/tvOS/WatchOS it's in simulator's home dir
        #if os(OSX)
            let homeDir = URL(fileURLWithPath: NSHomeDirectory())
            return homeDir.appendingPathComponent(cachePath)
        #elseif targetEnvironment(simulator)
            NSLog("DEBUG: Getting cache directory for simulator...")
            NSLog("DEBUG: SIMULATOR_HOST_HOME = \(ProcessInfo().environment["SIMULATOR_HOST_HOME"] ?? "NOT SET")")
            
            // Try to get SIMULATOR_HOST_HOME first
            if let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] {
                let homeDir = URL(fileURLWithPath: simulatorHostHome)
                let cacheDir = homeDir.appendingPathComponent(cachePath)
                NSLog("DEBUG: Using SIMULATOR_HOST_HOME cache directory: \(cacheDir.path)")
                return cacheDir
            }
            
            // Fallback: Use NSHomeDirectory
            NSLog("WARNING: SIMULATOR_HOST_HOME not set, using fallback approach")
            let homeDir = URL(fileURLWithPath: NSHomeDirectory())
            let cacheDir = homeDir.appendingPathComponent(cachePath)
            
            // Create the cache directory if it doesn't exist
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
            
            NSLog("DEBUG: Using fallback cache directory: \(cacheDir.path)")
            return cacheDir
        #else
            throw SnapshotError.cannotRunOnPhysicalDevice
        #endif
    }
}

private extension XCUIApplication {
    func currentUnusedActivityIndicator() -> XCUIElement {
        let activityQueryNonAnimating = self.descendants(matching: .activityIndicator).matching(NSPredicate(format: "animating == false"))

        #if os(iOS) || os(tvOS)
            let unusedActivityIndicator = activityQueryNonAnimating.firstMatch
        #else
            let unusedActivityIndicator = activityQueryNonAnimating.element
        #endif

        return unusedActivityIndicator
    }
}

// Please don't remove the lines below
// They are used to detect outdated configuration files
// SnapshotHelperVersion [1.30]
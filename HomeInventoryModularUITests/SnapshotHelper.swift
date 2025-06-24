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
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {

        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
        } catch let error {
            NSLog(error.localizedDescription)
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
        } catch {
            NSLog("Couldn't detect/set language...")
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

            guard var simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"], let screenshotsDir = screenshotsDirectory else { return }

            do {
                // The simulator name contains "Clone X of " inside the screenshot file when running parallelized UI Tests on concurrent devices
                let regex = try NSRegularExpression(pattern: "Clone [0-9]+ of ")
                let range = NSRange(location: 0, length: simulator.count)
                simulator = regex.stringByReplacingMatches(in: simulator, range: range, withTemplate: "")

                let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")
                #if swift(<5.0)
                    try UIImagePNGRepresentation(image)?.write(to: path)
                #else
                    try image.pngData()?.write(to: path)
                #endif
            } catch let error {
                NSLog("Problem writing screenshot: \(name) to \(screenshotsDir)/\(simulator)-\(name).png")
                NSLog(error.localizedDescription)
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
            guard let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] else {
                throw SnapshotError.cannotFindSimulatorHomeDirectory
            }
            let homeDir = URL(fileURLWithPath: simulatorHostHome)
            return homeDir.appendingPathComponent(cachePath)
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
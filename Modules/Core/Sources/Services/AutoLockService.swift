//
//  AutoLockService.swift
//  Core
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Google Sign-In Configuration:
//  Client ID: 316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg.apps.googleusercontent.com
//  URL Scheme: com.googleusercontent.apps.316432172622-6huvbn752v0ep68jkfdftrh8fgpesikg
//  OAuth Scope: https://www.googleapis.com/auth/gmail.readonly
//  Config Files: GoogleSignIn-Info.plist (project root), GoogleServices.plist (Gmail module)
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Core
//  Dependencies: Foundation, SwiftUI, LocalAuthentication
//  Testing: CoreTests/AutoLockServiceTests.swift
//
//  Description: Service for managing app auto-lock with configurable timeout
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import LocalAuthentication

@available(iOS 15.0, *)
public final class AutoLockService: ObservableObject {
    public static let shared = AutoLockService()
    
    // MARK: - Published Properties
    
    @Published public var isLocked = false
    @Published public var autoLockEnabled = false
    @Published public var autoLockTimeout: AutoLockTimeout = .immediate
    @Published public var requireAuthentication = true
    @Published public var lockOnBackground = true
    @Published public var lockOnScreenshot = false
    @Published public var showLockScreen = false
    @Published public var lastActivityTime = Date()
    @Published public var failedAttempts = 0
    @Published public var isAuthenticating = false
    
    // MARK: - Types
    
    public enum AutoLockTimeout: Int, CaseIterable, Codable {
        case immediate = 0
        case thirtySeconds = 30
        case oneMinute = 60
        case twoMinutes = 120
        case fiveMinutes = 300
        case tenMinutes = 600
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case never = -1
        
        public var displayName: String {
            switch self {
            case .immediate: return "Immediately"
            case .thirtySeconds: return "30 Seconds"
            case .oneMinute: return "1 Minute"
            case .twoMinutes: return "2 Minutes"
            case .fiveMinutes: return "5 Minutes"
            case .tenMinutes: return "10 Minutes"
            case .fifteenMinutes: return "15 Minutes"
            case .thirtyMinutes: return "30 Minutes"
            case .never: return "Never"
            }
        }
        
        public var seconds: TimeInterval? {
            guard rawValue >= 0 else { return nil }
            return TimeInterval(rawValue)
        }
    }
    
    public enum LockReason {
        case manual
        case timeout
        case background
        case screenshot
        case failedAuthentication
        
        public var message: String {
            switch self {
            case .manual:
                return "App was manually locked"
            case .timeout:
                return "App locked due to inactivity"
            case .background:
                return "App locked when moved to background"
            case .screenshot:
                return "App locked due to screenshot"
            case .failedAuthentication:
                return "App locked due to failed authentication attempts"
            }
        }
    }
    
    public enum AuthenticationError: LocalizedError {
        case biometryNotAvailable
        case biometryNotEnrolled
        case authenticationFailed
        case userCancelled
        case systemCancelled
        case passcodeNotSet
        case tooManyAttempts
        
        public var errorDescription: String? {
            switch self {
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled"
            case .authenticationFailed:
                return "Authentication failed"
            case .userCancelled:
                return "Authentication was cancelled"
            case .systemCancelled:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .tooManyAttempts:
                return "Too many failed attempts"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = NotificationCenter.default
    private var activityTimer: Timer?
    private var backgroundTimer: Timer?
    private let context = LAContext()
    private var lockReason: LockReason?
    
    private let autoLockEnabledKey = "auto_lock_enabled"
    private let autoLockTimeoutKey = "auto_lock_timeout"
    private let requireAuthKey = "require_authentication"
    private let lockOnBackgroundKey = "lock_on_background"
    private let lockOnScreenshotKey = "lock_on_screenshot"
    private let maxFailedAttempts = 3
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        setupNotifications()
        
        if autoLockEnabled {
            startActivityMonitoring()
        }
    }
    
    // MARK: - Public Methods
    
    /// Enable auto-lock with specified timeout
    public func enableAutoLock(timeout: AutoLockTimeout) {
        autoLockEnabled = true
        autoLockTimeout = timeout
        userDefaults.set(true, forKey: autoLockEnabledKey)
        userDefaults.set(timeout.rawValue, forKey: autoLockTimeoutKey)
        
        startActivityMonitoring()
    }
    
    /// Disable auto-lock
    public func disableAutoLock() {
        autoLockEnabled = false
        userDefaults.set(false, forKey: autoLockEnabledKey)
        
        stopActivityMonitoring()
    }
    
    /// Update auto-lock timeout
    public func updateTimeout(_ timeout: AutoLockTimeout) {
        autoLockTimeout = timeout
        userDefaults.set(timeout.rawValue, forKey: autoLockTimeoutKey)
        
        if autoLockEnabled {
            restartActivityMonitoring()
        }
    }
    
    /// Lock the app
    public func lock(reason: LockReason = .manual) {
        isLocked = true
        lockReason = reason
        showLockScreen = true
        stopActivityMonitoring()
        
        // Post notification for UI updates
        notificationCenter.post(name: .appLocked, object: nil, userInfo: ["reason": reason])
    }
    
    /// Unlock the app with authentication
    public func unlock() async throws {
        guard isLocked else { return }
        
        isAuthenticating = true
        
        do {
            if requireAuthentication {
                try await authenticate()
            }
            
            isLocked = false
            showLockScreen = false
            failedAttempts = 0
            lastActivityTime = Date()
            isAuthenticating = false
            
            if autoLockEnabled {
                startActivityMonitoring()
            }
            
            // Post notification for UI updates
            notificationCenter.post(name: .appUnlocked, object: nil)
            
        } catch {
            isAuthenticating = false
            failedAttempts += 1
            
            if failedAttempts >= maxFailedAttempts {
                lock(reason: .failedAuthentication)
            }
            
            throw error
        }
    }
    
    /// Record user activity
    public func recordActivity() {
        lastActivityTime = Date()
    }
    
    /// Check if biometric authentication is available
    public func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Get biometric type
    public var biometricType: LABiometryType {
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    /// Update settings
    public func updateSettings(
        requireAuth: Bool? = nil,
        lockOnBackground: Bool? = nil,
        lockOnScreenshot: Bool? = nil
    ) {
        if let requireAuth = requireAuth {
            requireAuthentication = requireAuth
            userDefaults.set(requireAuth, forKey: requireAuthKey)
        }
        
        if let lockOnBackground = lockOnBackground {
            self.lockOnBackground = lockOnBackground
            userDefaults.set(lockOnBackground, forKey: lockOnBackgroundKey)
        }
        
        if let lockOnScreenshot = lockOnScreenshot {
            self.lockOnScreenshot = lockOnScreenshot
            userDefaults.set(lockOnScreenshot, forKey: lockOnScreenshotKey)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        autoLockEnabled = userDefaults.object(forKey: autoLockEnabledKey) as? Bool ?? false
        
        if let timeoutValue = userDefaults.object(forKey: autoLockTimeoutKey) as? Int,
           let timeout = AutoLockTimeout(rawValue: timeoutValue) {
            autoLockTimeout = timeout
        }
        
        requireAuthentication = userDefaults.object(forKey: requireAuthKey) as? Bool ?? true
        lockOnBackground = userDefaults.object(forKey: lockOnBackgroundKey) as? Bool ?? true
        lockOnScreenshot = userDefaults.object(forKey: lockOnScreenshotKey) as? Bool ?? false
    }
    
    private func setupNotifications() {
        // App lifecycle
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Screenshot detection
        if lockOnScreenshot {
            notificationCenter.addObserver(
                self,
                selector: #selector(screenshotTaken),
                name: UIApplication.userDidTakeScreenshotNotification,
                object: nil
            )
        }
    }
    
    private func startActivityMonitoring() {
        stopActivityMonitoring()
        
        guard let timeout = autoLockTimeout.seconds else { return }
        
        activityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkActivityTimeout()
        }
    }
    
    private func stopActivityMonitoring() {
        activityTimer?.invalidate()
        activityTimer = nil
    }
    
    private func restartActivityMonitoring() {
        stopActivityMonitoring()
        startActivityMonitoring()
    }
    
    private func checkActivityTimeout() {
        guard let timeout = autoLockTimeout.seconds else { return }
        
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivityTime)
        
        if timeSinceLastActivity >= timeout && !isLocked {
            lock(reason: .timeout)
        }
    }
    
    private func authenticate() async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Enter Passcode"
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                throw mapLAError(error)
            }
            throw AuthenticationError.biometryNotAvailable
        }
        
        do {
            let reason = lockReason?.message ?? "Authenticate to unlock the app"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if !success {
                throw AuthenticationError.authenticationFailed
            }
            
        } catch let error as NSError {
            throw mapLAError(error)
        }
    }
    
    private func mapLAError(_ error: NSError) -> AuthenticationError {
        let laError = LAError(_nsError: error)
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .systemCancel:
            return .systemCancelled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        default:
            return .authenticationFailed
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidEnterBackground() {
        if lockOnBackground && autoLockEnabled {
            lock(reason: .background)
        }
    }
    
    @objc private func appWillEnterForeground() {
        if isLocked && !showLockScreen {
            showLockScreen = true
        }
    }
    
    @objc private func screenshotTaken() {
        if lockOnScreenshot && autoLockEnabled {
            lock(reason: .screenshot)
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let appLocked = Notification.Name("com.homeinventory.appLocked")
    static let appUnlocked = Notification.Name("com.homeinventory.appUnlocked")
}

// MARK: - View Modifier

@available(iOS 15.0, *)
public struct AutoLockViewModifier: ViewModifier {
    @StateObject private var lockService = AutoLockService.shared
    
    public func body(content: Content) -> some View {
        ZStack {
            content
                .onTapGesture {
                    lockService.recordActivity()
                }
                .onAppear {
                    lockService.recordActivity()
                }
            
            if lockService.showLockScreen {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
    }
}

public extension View {
    @available(iOS 15.0, *)
    func withAutoLock() -> some View {
        modifier(AutoLockViewModifier())
    }
}
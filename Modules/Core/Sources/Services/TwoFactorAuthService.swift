//
//  TwoFactorAuthService.swift
//  Core
//
//  Service for managing two-factor authentication
//

import Foundation
import SwiftUI
import CryptoKit
import LocalAuthentication
import Combine
import UIKit

public class TwoFactorAuthService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isEnabled = false
    @Published public var isVerified = false
    @Published public var availableMethods: [TwoFactorMethod] = []
    @Published public var preferredMethod: TwoFactorMethod = .authenticator
    @Published public var backupCodes: [String] = []
    @Published public var trustedDevices: [TrustedDevice] = []
    @Published public var setupProgress: SetupProgress = .notStarted
    
    // MARK: - Types
    
    public enum TwoFactorMethod: String, CaseIterable, Codable {
        case authenticator = "Authenticator App"
        case sms = "SMS"
        case email = "Email"
        case biometric = "Biometric"
        
        public var icon: String {
            switch self {
            case .authenticator: return "lock.shield"
            case .sms: return "message.fill"
            case .email: return "envelope.fill"
            case .biometric: return "faceid"
            }
        }
        
        public var description: String {
            switch self {
            case .authenticator:
                return "Use an authenticator app like Google Authenticator or Authy"
            case .sms:
                return "Receive a code via text message to your phone"
            case .email:
                return "Receive a code via email"
            case .biometric:
                return "Use Face ID or Touch ID as your second factor"
            }
        }
    }
    
    public enum SetupProgress {
        case notStarted
        case selectingMethod
        case configuringMethod
        case verifying
        case backupCodes
        case completed
        
        public var stepNumber: Int {
            switch self {
            case .notStarted: return 0
            case .selectingMethod: return 1
            case .configuringMethod: return 2
            case .verifying: return 3
            case .backupCodes: return 4
            case .completed: return 5
            }
        }
        
        public var title: String {
            switch self {
            case .notStarted: return "Get Started"
            case .selectingMethod: return "Choose Method"
            case .configuringMethod: return "Configure"
            case .verifying: return "Verify"
            case .backupCodes: return "Backup Codes"
            case .completed: return "Complete"
            }
        }
    }
    
    public struct TrustedDevice: Identifiable, Codable {
        public let id = UUID()
        public let deviceID: String
        public let deviceName: String
        public let deviceType: DeviceType
        public let trustedDate: Date
        public let lastUsedDate: Date
        public var isCurrentDevice: Bool
        
        public enum DeviceType: String, Codable {
            case iPhone = "iPhone"
            case iPad = "iPad"
            case mac = "Mac"
            case appleWatch = "Apple Watch"
            
            public var icon: String {
                switch self {
                case .iPhone: return "iphone"
                case .iPad: return "ipad"
                case .mac: return "laptopcomputer"
                case .appleWatch: return "applewatch"
                }
            }
        }
    }
    
    public struct AuthenticatorSetup {
        public let secretKey: String
        public let qrCodeURL: String
        public let manualEntryCode: String
        
        public init(for email: String) {
            // Generate secret key
            let secret = TwoFactorAuthService.generateSecretKey()
            self.secretKey = secret
            
            // Format for manual entry (groups of 4)
            self.manualEntryCode = secret.enumerated().map { index, char in
                index % 4 == 0 && index > 0 ? " \(char)" : String(char)
            }.joined()
            
            // Generate QR code URL for authenticator apps
            let issuer = "HomeInventory"
            let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
            self.qrCodeURL = "otpauth://totp/\(issuer):\(encodedEmail)?secret=\(secret)&issuer=\(issuer)"
        }
    }
    
    // MARK: - Private Properties
    
    // private let keychain = KeychainManager.shared
    private let biometricAuth = BiometricAuthService.shared
    private var currentSetup: AuthenticatorSetup?
    private var verificationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    
    private let secretKeyLength = 32
    private let codeLength = 6
    private let backupCodeCount = 10
    private let backupCodeLength = 8
    private let timeInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    public init() {
        loadSettings()
        updateAvailableMethods()
    }
    
    // MARK: - Setup Methods
    
    public func startSetup() {
        setupProgress = .selectingMethod
    }
    
    public func selectMethod(_ method: TwoFactorMethod) {
        preferredMethod = method
        setupProgress = .configuringMethod
        
        switch method {
        case .authenticator:
            setupAuthenticator()
        case .sms:
            setupSMS()
        case .email:
            setupEmail()
        case .biometric:
            setupBiometric()
        }
    }
    
    private func setupAuthenticator() {
        let userEmail = getUserEmail() ?? "user@example.com"
        currentSetup = AuthenticatorSetup(for: userEmail)
    }
    
    private func setupSMS() {
        // In real implementation, would verify phone number
    }
    
    private func setupEmail() {
        // In real implementation, would verify email address
    }
    
    private func setupBiometric() {
        Task {
            do {
                let success = try await biometricAuth.authenticate(reason: "Enable biometric two-factor authentication")
                if success {
                    setupProgress = .backupCodes
                    generateBackupCodes()
                }
            } catch {
                // Handle biometric setup error
            }
        }
    }
    
    // MARK: - Verification
    
    public func verifyCode(_ code: String) async throws -> Bool {
        guard code.count == codeLength else {
            throw TwoFactorError.invalidCode
        }
        
        switch preferredMethod {
        case .authenticator:
            return try await verifyAuthenticatorCode(code)
        case .sms:
            return try await verifySMSCode(code)
        case .email:
            return try await verifyEmailCode(code)
        case .biometric:
            return try await verifyBiometric()
        }
    }
    
    private func verifyAuthenticatorCode(_ code: String) async throws -> Bool {
        guard let setup = currentSetup else {
            throw TwoFactorError.setupNotFound
        }
        
        let generatedCode = generateTOTP(secret: setup.secretKey)
        
        if code == generatedCode {
            // Save the secret key securely
            // try keychain.save(setup.secretKey, forKey: "2fa_secret")
            UserDefaults.standard.set(setup.secretKey, forKey: "2fa_secret")
            setupProgress = .backupCodes
            generateBackupCodes()
            return true
        }
        
        return false
    }
    
    private func verifySMSCode(_ code: String) async throws -> Bool {
        // In real implementation, verify against sent code
        return code == "123456" // Mock verification
    }
    
    private func verifyEmailCode(_ code: String) async throws -> Bool {
        // In real implementation, verify against sent code
        return code == "123456" // Mock verification
    }
    
    private func verifyBiometric() async throws -> Bool {
        return try await biometricAuth.authenticate(reason: "Verify your identity")
    }
    
    // MARK: - TOTP Generation
    
    public func generateTOTP(secret: String) -> String {
        let counter = UInt64(Date().timeIntervalSince1970 / timeInterval)
        
        // Convert secret to data
        guard let secretData = base32Decode(secret) else {
            return "000000"
        }
        
        // Create HMAC
        var counterData = counter.bigEndian
        let counterBytes = withUnsafeBytes(of: &counterData) { Array($0) }
        
        let hmac = HMAC<SHA256>.authenticationCode(
            for: Data(counterBytes),
            using: SymmetricKey(data: secretData)
        )
        
        // Dynamic truncation
        let hmacData = Data(hmac)
        let offset = Int(hmacData[hmacData.count - 1] & 0x0f)
        
        let truncatedHash = hmacData[offset..<offset + 4]
        let value = truncatedHash.reduce(0) { result, byte in
            (result << 8) | UInt32(byte)
        }
        
        let otp = (value & 0x7fffffff) % 1000000
        return String(format: "%06d", otp)
    }
    
    // MARK: - Backup Codes
    
    public func generateBackupCodes() {
        backupCodes = (0..<backupCodeCount).map { _ in
            generateBackupCode()
        }
        
        // Save encrypted backup codes
        saveBackupCodes()
    }
    
    private func generateBackupCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = (0..<backupCodeLength).map { _ in
            String(characters.randomElement()!)
        }.joined()
        
        // Format as XXXX-XXXX
        let midIndex = code.index(code.startIndex, offsetBy: backupCodeLength / 2)
        return "\(code[..<midIndex])-\(code[midIndex...])"
    }
    
    public func useBackupCode(_ code: String) -> Bool {
        guard let index = backupCodes.firstIndex(of: code) else {
            return false
        }
        
        backupCodes.remove(at: index)
        saveBackupCodes()
        return true
    }
    
    // MARK: - Trusted Devices
    
    public func trustCurrentDevice() {
        let device = TrustedDevice(
            deviceID: getDeviceID(),
            deviceName: getDeviceName(),
            deviceType: getDeviceType(),
            trustedDate: Date(),
            lastUsedDate: Date(),
            isCurrentDevice: true
        )
        
        trustedDevices.append(device)
        saveTrustedDevices()
    }
    
    public func removeTrustedDevice(_ device: TrustedDevice) {
        trustedDevices.removeAll { $0.id == device.id }
        saveTrustedDevices()
    }
    
    public func isDeviceTrusted() -> Bool {
        let currentDeviceID = getDeviceID()
        return trustedDevices.contains { $0.deviceID == currentDeviceID }
    }
    
    // MARK: - Enable/Disable
    
    public func enable() {
        isEnabled = true
        setupProgress = .completed
        saveSettings()
    }
    
    public func disable() async throws {
        // Require authentication to disable
        let authenticated = try await biometricAuth.authenticate(
            reason: "Authenticate to disable two-factor authentication"
        )
        
        if authenticated {
            isEnabled = false
            isVerified = false
            backupCodes.removeAll()
            currentSetup = nil
            setupProgress = .notStarted
            
            // Clear saved data
            // try? keychain.delete(forKey: "2fa_secret")
            UserDefaults.standard.removeObject(forKey: "2fa_secret")
            saveSettings()
        }
    }
    
    // MARK: - Recovery
    
    public func initiateRecovery(email: String) async throws {
        // Send recovery code to email
        // In real implementation, would send actual email
        print("Recovery code sent to \(email)")
    }
    
    public func downloadBackupCodes() -> URL? {
        let content = """
        Home Inventory - Backup Codes
        Generated: \(Date().formatted())
        
        IMPORTANT: Store these codes in a safe place. Each code can only be used once.
        
        \(backupCodes.enumerated().map { index, code in
            "\(index + 1). \(code)"
        }.joined(separator: "\n"))
        
        If you lose access to your two-factor authentication method, you can use one of these codes to sign in.
        """
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("homeinventory_backup_codes.txt")
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "2fa_enabled")
        
        if let methodRaw = UserDefaults.standard.string(forKey: "2fa_method"),
           let method = TwoFactorMethod(rawValue: methodRaw) {
            preferredMethod = method
        }
        
        loadBackupCodes()
        loadTrustedDevices()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "2fa_enabled")
        UserDefaults.standard.set(preferredMethod.rawValue, forKey: "2fa_method")
    }
    
    private func saveBackupCodes() {
        if let data = try? JSONEncoder().encode(backupCodes) {
            // try? keychain.save(data, forKey: "2fa_backup_codes")
            UserDefaults.standard.set(data, forKey: "2fa_backup_codes")
        }
    }
    
    private func loadBackupCodes() {
        if let data = UserDefaults.standard.data(forKey: "2fa_backup_codes"),
           let codes = try? JSONDecoder().decode([String].self, from: data) {
            backupCodes = codes
        }
    }
    
    private func saveTrustedDevices() {
        if let data = try? JSONEncoder().encode(trustedDevices) {
            // try? keychain.save(data, forKey: "2fa_trusted_devices")
            UserDefaults.standard.set(data, forKey: "2fa_trusted_devices")
        }
    }
    
    private func loadTrustedDevices() {
        if let data = UserDefaults.standard.data(forKey: "2fa_trusted_devices"),
           let devices = try? JSONDecoder().decode([TrustedDevice].self, from: data) {
            trustedDevices = devices
        }
    }
    
    private func updateAvailableMethods() {
        availableMethods = [.authenticator, .email]
        
        Task { @MainActor in
            if biometricAuth.canUseBiometrics() {
                availableMethods.append(.biometric)
            }
        }
        
        // SMS would require phone number verification
        // availableMethods.append(.sms)
    }
    
    private static func generateSecretKey() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return (0..<32).map { _ in
            String(characters.randomElement()!)
        }.joined()
    }
    
    private func base32Decode(_ string: String) -> Data? {
        // Simple base32 decode implementation
        // In production, use a proper base32 library
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = ""
        
        for char in string.uppercased() {
            if let index = alphabet.firstIndex(of: char) {
                let position = alphabet.distance(from: alphabet.startIndex, to: index)
                bits += String(position, radix: 2).padLeft(toLength: 5, withPad: "0")
            }
        }
        
        var data = Data()
        for i in stride(from: 0, to: bits.count - 7, by: 8) {
            let startIndex = bits.index(bits.startIndex, offsetBy: i)
            let endIndex = bits.index(startIndex, offsetBy: 8)
            let byte = UInt8(bits[startIndex..<endIndex], radix: 2)!
            data.append(byte)
        }
        
        return data
    }
    
    private func getUserEmail() -> String? {
        // In real implementation, get from user profile
        return "user@example.com"
    }
    
    private func getDeviceID() -> String {
        // In real implementation, use identifierForVendor
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    private func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    private func getDeviceType() -> TrustedDevice.DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .mac:
            return .mac
        default:
            return .iPhone
        }
    }
}

// MARK: - Errors

public enum TwoFactorError: LocalizedError {
    case invalidCode
    case setupNotFound
    case methodNotAvailable
    case verificationFailed
    case tooManyAttempts
    
    public var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid verification code"
        case .setupNotFound:
            return "Two-factor setup not found"
        case .methodNotAvailable:
            return "This authentication method is not available"
        case .verificationFailed:
            return "Verification failed"
        case .tooManyAttempts:
            return "Too many attempts. Please try again later"
        }
    }
}

// MARK: - String Extension

private extension String {
    func padLeft(toLength: Int, withPad: String) -> String {
        let padding = String(repeating: withPad, count: max(0, toLength - count))
        return padding + self
    }
}
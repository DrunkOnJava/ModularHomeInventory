import Foundation
import Combine

/// UserDefaults-based implementation of settings storage
/// Swift 5.9 - No Swift 6 features
public final class UserDefaultsSettingsStorage: SettingsStorageProtocol, ObservableObject {
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Key-Value Storage
    
    public func string(forKey key: SettingsKey) -> String? {
        userDefaults.string(forKey: key.key)
    }
    
    public func set(_ value: String?, forKey key: SettingsKey) {
        if let value = value {
            userDefaults.set(value, forKey: key.key)
        } else {
            userDefaults.removeObject(forKey: key.key)
        }
        objectWillChange.send()
    }
    
    public func bool(forKey key: SettingsKey) -> Bool? {
        guard userDefaults.object(forKey: key.key) != nil else { return nil }
        return userDefaults.bool(forKey: key.key)
    }
    
    public func set(_ value: Bool, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.key)
        objectWillChange.send()
    }
    
    public func integer(forKey key: SettingsKey) -> Int? {
        guard userDefaults.object(forKey: key.key) != nil else { return nil }
        return userDefaults.integer(forKey: key.key)
    }
    
    public func set(_ value: Int, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.key)
        objectWillChange.send()
    }
    
    public func double(forKey key: SettingsKey) -> Double? {
        guard userDefaults.object(forKey: key.key) != nil else { return nil }
        return userDefaults.double(forKey: key.key)
    }
    
    public func set(_ value: Double, forKey key: SettingsKey) {
        userDefaults.set(value, forKey: key.key)
        objectWillChange.send()
    }
}
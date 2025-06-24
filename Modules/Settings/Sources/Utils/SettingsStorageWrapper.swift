import SwiftUI
import Core

/// Observable wrapper for SettingsStorageProtocol to work with SwiftUI
@MainActor
public class SettingsStorageWrapper: ObservableObject {
    private let storage: any SettingsStorageProtocol
    @Published private var updateTrigger = false
    
    public init(storage: any SettingsStorageProtocol) {
        self.storage = storage
    }
    
    // MARK: - String Operations
    
    public func string(forKey key: SettingsKey) -> String? {
        storage.string(forKey: key)
    }
    
    public func set(_ value: String?, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Bool Operations
    
    public func bool(forKey key: SettingsKey) -> Bool? {
        storage.bool(forKey: key)
    }
    
    public func set(_ value: Bool, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Integer Operations
    
    public func integer(forKey key: SettingsKey) -> Int? {
        storage.integer(forKey: key)
    }
    
    public func set(_ value: Int, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
    
    // MARK: - Double Operations
    
    public func double(forKey key: SettingsKey) -> Double? {
        storage.double(forKey: key)
    }
    
    public func set(_ value: Double, forKey key: SettingsKey) {
        storage.set(value, forKey: key)
        updateTrigger.toggle()
    }
}
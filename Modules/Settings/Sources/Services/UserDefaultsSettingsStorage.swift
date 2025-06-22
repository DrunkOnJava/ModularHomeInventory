import Foundation
import Core

/// UserDefaults-based implementation of settings storage
/// Swift 5.9 - No Swift 6 features
public final class UserDefaultsSettingsStorage: SettingsStorageProtocol {
    private let userDefaults: UserDefaults
    private let settingsKey = "app.settings"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            // Return default settings if none exist
            return AppSettings()
        }
        return settings
    }
    
    public func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: settingsKey)
    }
}
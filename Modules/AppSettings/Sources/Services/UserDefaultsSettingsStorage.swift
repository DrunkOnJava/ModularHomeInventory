import Foundation
import Core

/// Settings-specific extension of UserDefaultsSettingsStorage
/// Swift 5.9 - No Swift 6 features
extension Core.UserDefaultsSettingsStorage {
    private static let settingsKey = "app.settings"
    
    public func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: Self.settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            // Return default settings if none exist
            return AppSettings()
        }
        return settings
    }
    
    public func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
        objectWillChange.send()
    }
}
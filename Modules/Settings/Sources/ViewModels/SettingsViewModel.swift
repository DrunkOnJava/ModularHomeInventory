import Foundation
import Combine
import Core

/// View model for managing settings state
/// Swift 5.9 - No Swift 6 features
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    
    private let settingsStorage: SettingsStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsStorage: SettingsStorageProtocol) {
        self.settingsStorage = settingsStorage
        self.settings = settingsStorage.loadSettings()
        
        // Auto-save settings when they change
        $settings
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] updatedSettings in
                self?.settingsStorage.saveSettings(updatedSettings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func resetToDefaults() {
        settings = AppSettings()
        settingsStorage.saveSettings(settings)
    }
    
    func exportData() {
        // TODO: Implement data export
        print("Export data requested")
    }
    
    func clearCache() {
        // TODO: Implement cache clearing
        print("Clear cache requested")
    }
}
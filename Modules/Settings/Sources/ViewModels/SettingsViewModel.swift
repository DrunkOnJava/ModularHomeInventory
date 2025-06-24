import Foundation
import Combine
import Core

/// View model for managing settings state
/// Swift 5.9 - No Swift 6 features
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var hasConflicts = false
    @Published var conflictCount = 0
    
    let settingsStorage: SettingsStorageProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Repository references for conflict resolution
    var itemRepository: (any ItemRepository)?
    var receiptRepository: (any ReceiptRepository)?
    var locationRepository: (any LocationRepository)?
    
    init(
        settingsStorage: SettingsStorageProtocol,
        itemRepository: (any ItemRepository)? = nil,
        receiptRepository: (any ReceiptRepository)? = nil,
        locationRepository: (any LocationRepository)? = nil
    ) {
        self.settingsStorage = settingsStorage
        self.settings = settingsStorage.loadSettings()
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.locationRepository = locationRepository
        
        // Auto-save settings when they change
        $settings
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] updatedSettings in
                self?.settingsStorage.saveSettings(updatedSettings)
            }
            .store(in: &cancellables)
        
        // Check for conflicts periodically (in a real app)
        checkForConflicts()
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
    
    func saveSettings() {
        settingsStorage.saveSettings(settings)
    }
    
    func checkForConflicts() {
        // In a real app, this would check with the sync service
        // For demo purposes, we'll simulate some conflicts
        Task {
            // Simulate checking for conflicts
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // For demo: randomly show conflicts
            let hasConflicts = Bool.random()
            self.hasConflicts = hasConflicts
            self.conflictCount = hasConflicts ? Int.random(in: 1...5) : 0
        }
    }
}
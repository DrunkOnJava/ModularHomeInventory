import SwiftUI
import Core

/// Main implementation of the Settings module
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class SettingsModule: SettingsModuleAPI {
    private let dependencies: SettingsModuleDependencies
    
    public init(dependencies: SettingsModuleDependencies) {
        self.dependencies = dependencies
    }
    
    public func makeSettingsView() -> AnyView {
        print("SettingsModule: Creating EnhancedSettingsView")
        print("SettingsModule: dependencies.settingsStorage = \(dependencies.settingsStorage)")
        let viewModel = SettingsViewModel(
            settingsStorage: dependencies.settingsStorage,
            itemRepository: dependencies.itemRepository,
            receiptRepository: dependencies.receiptRepository,
            locationRepository: dependencies.locationRepository
        )
        print("SettingsModule: Created viewModel = \(viewModel)")
        let view = EnhancedSettingsView(viewModel: viewModel)
        print("SettingsModule: Created EnhancedSettingsView")
        return AnyView(view)
    }
    
    public func makeAboutView() -> AnyView {
        AnyView(AboutView())
    }
}
import Foundation
import Core

/// Main implementation of the Widgets module
/// Swift 5.9 - No Swift 6 features
public final class WidgetsModule: WidgetsModuleAPI {
    private let dependencies: WidgetsModuleDependencies
    
    public init(dependencies: WidgetsModuleDependencies) {
        self.dependencies = dependencies
    }
}
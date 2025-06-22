import SwiftUI
import Core

/// Public API for the Scanner module
/// Swift 5.9 - No Swift 6 features
@MainActor
public protocol ScannerModuleAPI: AnyObject {
    /// Creates the main scanner view
    func makeScannerView() -> AnyView
    
    /// Creates a barcode scanner view with completion handler
    func makeBarcodeScannerView(completion: @escaping (String) -> Void) -> AnyView
    
    /// Creates a batch scanner view for scanning multiple items
    func makeBatchScannerView(completion: @escaping ([Item]) -> Void) -> AnyView
    
    /// Creates a document scanner view
    func makeDocumentScannerView(completion: @escaping (UIImage) -> Void) -> AnyView
}

/// Scanner result types
public enum ScanResult {
    case barcode(String)
    case document(UIImage)
    case error(Error)
}

/// Dependencies required by the Scanner module
public struct ScannerModuleDependencies {
    public let itemRepository: any ItemRepository
    public let itemTemplateRepository: any ItemTemplateRepository
    
    public init(
        itemRepository: any ItemRepository,
        itemTemplateRepository: any ItemTemplateRepository
    ) {
        self.itemRepository = itemRepository
        self.itemTemplateRepository = itemTemplateRepository
    }
}
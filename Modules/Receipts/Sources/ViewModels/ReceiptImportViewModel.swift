import Foundation
import Core

/// View model for receipt import
/// Swift 5.9 - No Swift 6 features
@MainActor
final class ReceiptImportViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let emailService: EmailServiceProtocol
    private let ocrService: OCRServiceProtocol
    private let completion: (Receipt) -> Void
    
    init(
        emailService: EmailServiceProtocol,
        ocrService: OCRServiceProtocol,
        completion: @escaping (Receipt) -> Void
    ) {
        self.emailService = emailService
        self.ocrService = ocrService
        self.completion = completion
    }
    
    func importFromEmail() async {
        // TODO: Implement email import
    }
    
    func importFromCamera() async {
        // TODO: Implement camera/OCR import
    }
    
    func saveReceipt(_ receipt: Receipt) {
        completion(receipt)
    }
}
import Foundation
import Core

/// Public API for the Widgets module
/// Swift 5.9 - No Swift 6 features
public protocol WidgetsModuleAPI {
    // Widget module functionality will be added here
}

/// Dependencies required by the Widgets module
public struct WidgetsModuleDependencies {
    public let itemRepository: any ItemRepository
    public let receiptRepository: any ReceiptRepository
    public let warrantyRepository: any WarrantyRepository
    public let budgetRepository: (any BudgetRepository)?
    
    public init(
        itemRepository: any ItemRepository,
        receiptRepository: any ReceiptRepository,
        warrantyRepository: any WarrantyRepository,
        budgetRepository: (any BudgetRepository)? = nil
    ) {
        self.itemRepository = itemRepository
        self.receiptRepository = receiptRepository
        self.warrantyRepository = warrantyRepository
        self.budgetRepository = budgetRepository
    }
}
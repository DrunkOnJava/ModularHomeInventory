import Foundation
import Combine

/// Service that monitors various conditions and triggers notifications
/// Swift 5.9 - No Swift 6 features
@MainActor
public final class NotificationTriggerService: ObservableObject {
    
    // Singleton instance
    public static let shared = NotificationTriggerService()
    
    // Dependencies
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Monitoring flags
    @Published public var isMonitoringActive = false
    
    private init() {
        setupNotificationHandlers()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring all notification triggers
    public func startMonitoring(
        itemRepository: any ItemRepository,
        warrantyRepository: any WarrantyRepository,
        budgetRepository: (any BudgetRepository)?
    ) {
        guard !isMonitoringActive else { return }
        isMonitoringActive = true
        
        // Monitor warranty expirations
        monitorWarrantyExpirations(warrantyRepository: warrantyRepository, itemRepository: itemRepository)
        
        // Monitor budget alerts
        if let budgetRepository = budgetRepository {
            monitorBudgetAlerts(budgetRepository: budgetRepository, itemRepository: itemRepository)
        }
        
        // Monitor low stock items
        monitorLowStockItems(itemRepository: itemRepository)
    }
    
    /// Stop all monitoring
    public func stopMonitoring() {
        isMonitoringActive = false
        cancellables.removeAll()
    }
    
    // MARK: - Warranty Monitoring
    
    private func monitorWarrantyExpirations(warrantyRepository: any WarrantyRepository, itemRepository: any ItemRepository) {
        // Check warranties every day
        Timer.publish(every: 86400, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkWarrantyExpirations(warrantyRepository: warrantyRepository, itemRepository: itemRepository)
                }
            }
            .store(in: &cancellables)
        
        // Also check immediately
        Task {
            await checkWarrantyExpirations(warrantyRepository: warrantyRepository, itemRepository: itemRepository)
        }
    }
    
    private func checkWarrantyExpirations(warrantyRepository: any WarrantyRepository, itemRepository: any ItemRepository) async {
        do {
            let warranties = try await warrantyRepository.fetchAll()
            let now = Date()
            
            for warranty in warranties {
                guard warranty.status == .active else { continue }
                
                let daysUntilExpiration = Calendar.current.dateComponents([.day], from: now, to: warranty.endDate).day ?? 0
                
                // Check notification thresholds
                if shouldNotifyForWarranty(daysUntilExpiration: daysUntilExpiration, warranty: warranty) {
                    // Fetch the item details
                    if let item = try await itemRepository.fetch(id: warranty.itemId) {
                        await scheduleWarrantyNotification(warranty: warranty, item: item, daysUntilExpiration: daysUntilExpiration)
                    }
                }
            }
        } catch {
            print("Error checking warranty expirations: \(error)")
        }
    }
    
    private func shouldNotifyForWarranty(daysUntilExpiration: Int, warranty: Warranty) -> Bool {
        // Notify at 30, 14, 7, and 1 day before expiration
        let notificationDays = [30, 14, 7, 1]
        return notificationDays.contains(daysUntilExpiration)
    }
    
    private func scheduleWarrantyNotification(warranty: Warranty, item: Item, daysUntilExpiration: Int) async {
        let title = "Warranty Expiring Soon"
        let body: String
        
        switch daysUntilExpiration {
        case 1:
            body = "\(item.name) warranty expires tomorrow!"
        case 7:
            body = "\(item.name) warranty expires in 1 week"
        case 14:
            body = "\(item.name) warranty expires in 2 weeks"
        case 30:
            body = "\(item.name) warranty expires in 1 month"
        default:
            body = "\(item.name) warranty expires in \(daysUntilExpiration) days"
        }
        
        let request = NotificationRequest(
            id: "warranty_\(warranty.id)_\(daysUntilExpiration)",
            type: .warrantyExpiration,
            title: title,
            body: body,
            scheduledDate: nil,
            timeInterval: 1, // Immediate
            userInfo: [
                "warrantyId": warranty.id.uuidString,
                "itemId": item.id.uuidString,
                "daysUntilExpiration": daysUntilExpiration
            ]
        )
        
        do {
            try await notificationManager.scheduleNotification(request)
        } catch {
            print("Failed to schedule warranty notification: \(error)")
        }
    }
    
    // MARK: - Budget Monitoring
    
    private func monitorBudgetAlerts(budgetRepository: any BudgetRepository, itemRepository: any ItemRepository) {
        // Monitor budget changes
        budgetRepository.budgetsPublisher
            .sink { [weak self] budgets in
                Task {
                    await self?.checkBudgetAlerts(budgets: budgets, budgetRepository: budgetRepository, itemRepository: itemRepository)
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBudgetAlerts(budgets: [Budget], budgetRepository: any BudgetRepository, itemRepository: any ItemRepository) async {
        for budget in budgets where budget.isActive {
            do {
                let status = try await budgetRepository.getBudgetStatus(budget.id)
                let percentUsed = (status.spent / budget.amount) * 100
                
                // Alert at 80%, 90%, and 100% usage
                if percentUsed >= 80 && percentUsed < 90 {
                    await scheduleBudgetNotification(budget: budget, percentUsed: 80, status: status)
                } else if percentUsed >= 90 && percentUsed < 100 {
                    await scheduleBudgetNotification(budget: budget, percentUsed: 90, status: status)
                } else if percentUsed >= 100 {
                    await scheduleBudgetNotification(budget: budget, percentUsed: 100, status: status)
                }
            } catch {
                print("Error checking budget status: \(error)")
            }
        }
    }
    
    private func scheduleBudgetNotification(budget: Budget, percentUsed: Int, status: BudgetStatus) async {
        let title: String
        let body: String
        
        switch percentUsed {
        case 80:
            title = "Budget Alert: 80% Used"
            body = "You've used 80% of your \(budget.name) budget"
        case 90:
            title = "Budget Warning: 90% Used"
            body = "Only 10% remaining in your \(budget.name) budget"
        case 100:
            title = "Budget Exceeded!"
            body = "You've exceeded your \(budget.name) budget"
        default:
            title = "Budget Alert"
            body = "\(budget.name): \(percentUsed)% used"
        }
        
        let request = NotificationRequest(
            id: "budget_\(budget.id)_\(percentUsed)",
            type: .budgetAlert,
            title: title,
            body: body,
            timeInterval: 1, // Immediate
            userInfo: [
                "budgetId": budget.id.uuidString,
                "percentUsed": percentUsed,
                "spent": status.spent,
                "remaining": status.remaining
            ]
        )
        
        do {
            try await notificationManager.scheduleNotification(request)
        } catch {
            print("Failed to schedule budget notification: \(error)")
        }
    }
    
    // MARK: - Low Stock Monitoring
    
    private func monitorLowStockItems(itemRepository: any ItemRepository) {
        // Check stock levels every 12 hours
        Timer.publish(every: 43200, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkLowStockItems(itemRepository: itemRepository)
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkLowStockItems(itemRepository: any ItemRepository) async {
        do {
            let items = try await itemRepository.fetchAll()
            
            for item in items {
                // Check if quantity is below minimum stock level
                if let quantity = item.quantity,
                   let minStock = item.minimumStockLevel,
                   quantity <= minStock && quantity > 0 {
                    await scheduleLowStockNotification(item: item, currentQuantity: quantity, minQuantity: minStock)
                }
            }
        } catch {
            print("Error checking low stock items: \(error)")
        }
    }
    
    private func scheduleLowStockNotification(item: Item, currentQuantity: Int, minQuantity: Int) async {
        let title = "Low Stock Alert"
        let body = "\(item.name) is running low. Only \(currentQuantity) remaining (min: \(minQuantity))"
        
        let request = NotificationRequest(
            id: "lowstock_\(item.id)",
            type: .lowStock,
            title: title,
            body: body,
            timeInterval: 1, // Immediate
            userInfo: [
                "itemId": item.id.uuidString,
                "currentQuantity": currentQuantity,
                "minimumQuantity": minQuantity
            ]
        )
        
        do {
            try await notificationManager.scheduleNotification(request)
        } catch {
            print("Failed to schedule low stock notification: \(error)")
        }
    }
    
    // MARK: - Price Alert Monitoring
    
    public func checkPriceAlert(for item: Item, newPrice: Decimal, oldPrice: Decimal) async {
        // Only notify if price dropped by at least 10%
        let priceDropPercentage = ((oldPrice - newPrice) / oldPrice) * 100
        
        guard priceDropPercentage >= 10 else { return }
        
        let title = "Price Drop Alert!"
        let body = "\(item.name) price dropped by \(Int(priceDropPercentage))% - Now $\(newPrice)"
        
        let request = NotificationRequest(
            id: "price_\(item.id)_\(Date().timeIntervalSince1970)",
            type: .priceAlert,
            title: title,
            body: body,
            timeInterval: 1,
            userInfo: [
                "itemId": item.id.uuidString,
                "oldPrice": oldPrice,
                "newPrice": newPrice,
                "dropPercentage": priceDropPercentage
            ]
        )
        
        do {
            try await notificationManager.scheduleNotification(request)
        } catch {
            print("Failed to schedule price alert: \(error)")
        }
    }
    
    // MARK: - Receipt Processed
    
    public func notifyReceiptProcessed(receipt: Receipt, itemCount: Int) async {
        let title = "Receipt Processed"
        let body = "\(receipt.storeName) - \(itemCount) items added"
        
        let request = NotificationRequest(
            id: "receipt_\(receipt.id)",
            type: .receiptProcessed,
            title: title,
            body: body,
            timeInterval: 1,
            userInfo: [
                "receiptId": receipt.id.uuidString,
                "storeName": receipt.storeName,
                "itemCount": itemCount
            ]
        )
        
        do {
            try await notificationManager.scheduleNotification(request)
        } catch {
            print("Failed to schedule receipt notification: \(error)")
        }
    }
    
    // MARK: - Notification Handlers
    
    private func setupNotificationHandlers() {
        // Handle notification taps
        NotificationCenter.default.publisher(for: .notificationTapped)
            .sink { [weak self] notification in
                self?.handleNotificationTap(notification)
            }
            .store(in: &cancellables)
        
        // Handle notification actions
        NotificationCenter.default.publisher(for: .notificationActionTapped)
            .sink { [weak self] notification in
                self?.handleNotificationAction(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeString = userInfo["type"] as? String,
              let type = NotificationManager.NotificationType(rawValue: typeString) else {
            return
        }
        
        // Post navigation events based on notification type
        switch type {
        case .warrantyExpiration:
            if let itemId = userInfo["itemId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToItem,
                    object: nil,
                    userInfo: ["itemId": itemId]
                )
            }
        case .budgetAlert:
            NotificationCenter.default.post(name: .navigateToBudget, object: nil)
        case .priceAlert, .lowStock:
            if let itemId = userInfo["itemId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToItem,
                    object: nil,
                    userInfo: ["itemId": itemId]
                )
            }
        case .receiptProcessed:
            if let receiptId = userInfo["receiptId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToReceipt,
                    object: nil,
                    userInfo: ["receiptId": receiptId]
                )
            }
        default:
            break
        }
    }
    
    private func handleNotificationAction(_ notification: Notification) {
        guard let info = notification.userInfo,
              let action = info["action"] as? String,
              let userInfo = info["userInfo"] as? [AnyHashable: Any] else {
            return
        }
        
        // Handle specific actions
        switch action {
        case "VIEW_WARRANTY", "VIEW_ITEM":
            if let itemId = userInfo["itemId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToItem,
                    object: nil,
                    userInfo: ["itemId": itemId]
                )
            }
        case "VIEW_BUDGET", "ADJUST_BUDGET":
            NotificationCenter.default.post(name: .navigateToBudget, object: nil)
        default:
            break
        }
    }
}

// MARK: - Navigation Notification Names

public extension Notification.Name {
    static let navigateToItem = Notification.Name("navigateToItem")
    static let navigateToBudget = Notification.Name("navigateToBudget")
    static let navigateToReceipt = Notification.Name("navigateToReceipt")
}
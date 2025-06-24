import SwiftUI
import Core
import SharedUI

/// View for managing warranty expiration notifications
/// Swift 5.9 - No Swift 6 features
struct WarrantyNotificationsView: View {
    @StateObject private var viewModel: WarrantyNotificationsViewModel
    @State private var showingAddCustomDays = false
    @State private var customDays = ""
    @State private var showingPermissionDenied = false
    
    init(
        warrantyRepository: any WarrantyRepository,
        itemRepository: any ItemRepository
    ) {
        self._viewModel = StateObject(wrappedValue: WarrantyNotificationsViewModel(
            warrantyRepository: warrantyRepository,
            itemRepository: itemRepository
        ))
    }
    
    var body: some View {
        List {
            // Notification Settings
            Section {
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { newValue in
                        if newValue {
                            Task {
                                await viewModel.enableNotifications()
                            }
                        }
                    }
                
                if viewModel.notificationsEnabled {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Notify me before warranty expires:")
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        ForEach(viewModel.notificationDays, id: \.self) { days in
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 20)
                                
                                Text("\(days) day\(days == 1 ? "" : "s") before")
                                    .textStyle(.bodyMedium)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.removeNotificationDay(days)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                            }
                            .appPadding(.vertical, AppSpacing.xs)
                        }
                        
                        Button(action: { showingAddCustomDays = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Custom Reminder")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.primary)
                        }
                        .appPadding(.top, AppSpacing.xs)
                    }
                }
            } header: {
                Text("Notification Settings")
            } footer: {
                if viewModel.notificationsEnabled {
                    Text("You'll receive notifications at 10:00 AM on the specified days before each warranty expires.")
                }
            }
            
            // Upcoming Expirations
            if !viewModel.upcomingExpirations.isEmpty {
                Section("Upcoming Expirations") {
                    ForEach(viewModel.upcomingExpirations) { warranty in
                        WarrantyExpirationRow(
                            warranty: warranty,
                            item: viewModel.items[warranty.itemId]
                        )
                    }
                }
            }
            
            // Expired Warranties
            if !viewModel.expiredWarranties.isEmpty {
                Section("Recently Expired") {
                    ForEach(viewModel.expiredWarranties) { warranty in
                        WarrantyExpirationRow(
                            warranty: warranty,
                            item: viewModel.items[warranty.itemId],
                            isExpired: true
                        )
                    }
                }
            }
        }
        .navigationTitle("Warranty Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Reminder", isPresented: $showingAddCustomDays) {
            TextField("Days before expiration", text: $customDays)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) {
                customDays = ""
            }
            
            Button("Add") {
                if let days = Int(customDays), days > 0 {
                    viewModel.addNotificationDay(days)
                }
                customDays = ""
            }
        } message: {
            Text("Enter the number of days before warranty expiration to receive a notification.")
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive warranty expiration alerts.")
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: viewModel.permissionDenied) { denied in
            if denied {
                showingPermissionDenied = true
                viewModel.permissionDenied = false
            }
        }
    }
}

// MARK: - Supporting Views

struct WarrantyExpirationRow: View {
    let warranty: Warranty
    let item: Item?
    var isExpired: Bool = false
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: warranty.endDate).day ?? 0
    }
    
    private var urgencyColor: Color {
        if isExpired {
            return Color.red
        } else if daysRemaining <= 7 {
            return Color.orange
        } else if daysRemaining <= 30 {
            return Color.yellow
        } else {
            return AppColors.primary
        }
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(urgencyColor)
                .frame(width: 40)
            
            // Details
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item?.name ?? "Unknown Item")
                    .textStyle(.bodyLarge)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(warranty.provider)
                    .textStyle(.bodySmall)
                    .foregroundStyle(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    
                    if isExpired {
                        Text("Expired \(abs(daysRemaining)) day\(abs(daysRemaining) == 1 ? "" : "s") ago")
                            .textStyle(.labelSmall)
                            .foregroundStyle(Color.red)
                    } else {
                        Text("Expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                            .textStyle(.labelSmall)
                            .foregroundStyle(urgencyColor)
                    }
                }
            }
            
            Spacer()
            
            // Expiration date
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(warranty.endDate, style: .date)
                    .textStyle(.labelMedium)
                    .foregroundStyle(AppColors.textPrimary)
                
                if !isExpired {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .appPadding(.vertical, AppSpacing.xs)
    }
}

// MARK: - View Model

@MainActor
final class WarrantyNotificationsViewModel: ObservableObject {
    @Published var notificationsEnabled = false
    @Published var notificationDays: [Int] = []
    @Published var upcomingExpirations: [Warranty] = []
    @Published var expiredWarranties: [Warranty] = []
    @Published var items: [UUID: Item] = [:]
    @Published var permissionDenied = false
    
    private let warrantyRepository: any WarrantyRepository
    private let itemRepository: any ItemRepository
    private let notificationService = WarrantyNotificationService.shared
    
    init(
        warrantyRepository: any WarrantyRepository,
        itemRepository: any ItemRepository
    ) {
        self.warrantyRepository = warrantyRepository
        self.itemRepository = itemRepository
        
        // Load settings from notification service
        notificationsEnabled = notificationService.isEnabled
        notificationDays = notificationService.notificationDays.sorted()
        
        // Observe changes
        setupBindings()
    }
    
    private func setupBindings() {
        // Sync with notification service
        $notificationsEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.notificationService.isEnabled = enabled
            }
            .store(in: &cancellables)
        
        $notificationDays
            .dropFirst()
            .sink { [weak self] days in
                self?.notificationService.notificationDays = days.sorted()
                Task {
                    await self?.rescheduleAllNotifications()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() async {
        do {
            // Load all warranties
            let allWarranties = try await warrantyRepository.fetchAll()
            
            // Sort into upcoming and expired
            let now = Date()
            let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now)!
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            
            upcomingExpirations = allWarranties
                .filter { $0.endDate > now && $0.endDate <= thirtyDaysFromNow }
                .sorted { $0.endDate < $1.endDate }
            
            expiredWarranties = allWarranties
                .filter { $0.endDate <= now && $0.endDate >= thirtyDaysAgo }
                .sorted { $0.endDate > $1.endDate }
            
            // Load items for the warranties
            let itemIds = Set(upcomingExpirations.map { $0.itemId } + expiredWarranties.map { $0.itemId })
            let allItems = try await itemRepository.fetchAll()
            
            items = Dictionary(uniqueKeysWithValues: allItems.compactMap { item in
                itemIds.contains(item.id) ? (item.id, item) : nil
            })
            
        } catch {
            print("Error loading warranty data: \(error)")
        }
    }
    
    func enableNotifications() async {
        let hasPermission = await notificationService.checkNotificationPermission()
        if !hasPermission {
            notificationsEnabled = false
            permissionDenied = true
        } else {
            await rescheduleAllNotifications()
        }
    }
    
    func addNotificationDay(_ days: Int) {
        if !notificationDays.contains(days) {
            notificationDays.append(days)
            notificationDays.sort()
        }
    }
    
    func removeNotificationDay(_ days: Int) {
        notificationDays.removeAll { $0 == days }
    }
    
    private func rescheduleAllNotifications() async {
        do {
            let warranties = try await warrantyRepository.fetchAll()
            await notificationService.updateAllNotifications(warranties)
        } catch {
            print("Error rescheduling notifications: \(error)")
        }
    }
}

import Combine
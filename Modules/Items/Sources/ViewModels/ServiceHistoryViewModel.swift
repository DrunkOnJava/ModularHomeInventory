//
//  ServiceHistoryViewModel.swift
//  Items Module
//
//  Apple Configuration:
//  Bundle Identifier: com.homeinventory.app
//  Display Name: Home Inventory
//  Version: 1.0.5
//  Build: 5
//  Deployment Target: iOS 17.0
//  Supported Devices: iPhone & iPad
//  Team ID: 2VXBQV4XC9
//
//  Makefile Configuration:
//  Default Simulator: iPhone 16 Pro Max (DD192264-DFAA-4582-B2FE-D6FC444C9DDF)
//  iPad Simulator: iPad Pro 13-inch (M4) (CE6D038C-840B-4BDB-AA63-D61FA0755C4A)
//  App Bundle ID: com.homeinventory.app
//  Build Path: build/Build/Products/Debug-iphonesimulator/
//
//  Key Commands:
//  Build and run: make build run
//  Fast build (skip module prebuild): make build-fast run
//  iPad build and run: make build-ipad run-ipad
//  Clean build: make clean build run
//  Run tests: make test
//
//  Project Structure:
//  Main Target: HomeInventoryModular
//  Test Targets: HomeInventoryModularTests, HomeInventoryModularUITests
//  Swift Version: 5.9 (DO NOT upgrade to Swift 6)
//  Minimum iOS Version: 17.0
//
//  Architecture: Modular SPM packages with local package dependencies
//  Repository: https://github.com/DrunkOnJava/ModularHomeInventory.git
//  Module: Items
//  Dependencies: SwiftUI, Core, Combine
//  Testing: ItemsTests/ServiceHistoryViewModelTests.swift
//
//  Description: View model for managing service and repair history records
//
//  Created by Griffin Long on June 25, 2025
//  Copyright © 2025 Home Inventory. All rights reserved.
//

import Foundation
import SwiftUI
import Core
import Combine

@MainActor
final class ServiceHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var serviceRecords: [ServiceRecord] = []
    @Published var repairRecords: [RepairRecord] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Properties
    let item: Item
    let serviceRepository: ServiceRecordRepository
    let repairRepository: RepairRecordRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var allRecords: [ServiceRecord] {
        serviceRecords
    }
    
    var filteredRecords: [ServiceRecord] {
        allRecords.sorted { $0.date > $1.date }
    }
    
    var groupedRecords: [Int: [ServiceRecord]] {
        Dictionary(grouping: filteredRecords) { record in
            Calendar.current.component(.year, from: record.date)
        }
    }
    
    var totalServiceCost: Decimal {
        serviceRecords.reduce(0) { sum, record in
            sum + (record.cost ?? 0)
        }
    }
    
    var totalRepairCost: Decimal {
        repairRecords.reduce(0) { sum, record in
            sum + record.cost.outOfPocket
        }
    }
    
    var nextServiceDate: Date? {
        serviceRecords
            .compactMap { $0.nextServiceDate }
            .filter { $0 > Date() }
            .min()
    }
    
    var upcomingServices: [ServiceRecord] {
        serviceRecords
            .filter { record in
                guard let nextDate = record.nextServiceDate else { return false }
                return nextDate > Date() && nextDate < Date().addingTimeInterval(90 * 24 * 60 * 60)
            }
            .sorted { ($0.nextServiceDate ?? Date()) < ($1.nextServiceDate ?? Date()) }
    }
    
    var activeRepairs: [RepairRecord] {
        repairRecords.filter { $0.isActive }
    }
    
    // MARK: - Initialization
    init(
        item: Item,
        serviceRepository: ServiceRecordRepository,
        repairRepository: RepairRecordRepository
    ) {
        self.item = item
        self.serviceRepository = serviceRepository
        self.repairRepository = repairRepository
        
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Subscribe to service records updates
        serviceRepository.serviceRecordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                self.serviceRecords = records.filter { $0.itemId == self.item.id }
            }
            .store(in: &cancellables)
        
        // Subscribe to repair records updates
        repairRepository.repairRecordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                self.repairRecords = records.filter { $0.itemId == self.item.id }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadRecords() async {
        isLoading = true
        error = nil
        
        do {
            // Load service and repair records in parallel
            async let serviceTask = serviceRepository.fetchRecords(for: item.id)
            async let repairTask = repairRepository.fetchRecords(for: item.id)
            
            let (services, repairs) = try await (serviceTask, repairTask)
            
            serviceRecords = services
            repairRecords = repairs
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    // MARK: - Actions
    func addServiceRecord(_ record: ServiceRecord) async {
        do {
            try await serviceRepository.save(record)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    func updateServiceRecord(_ record: ServiceRecord) async {
        do {
            var updatedRecord = record
            updatedRecord.updatedAt = Date()
            try await serviceRepository.save(updatedRecord)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    func deleteServiceRecord(_ record: ServiceRecord) async {
        do {
            try await serviceRepository.delete(record)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    func addRepairRecord(_ record: RepairRecord) async {
        do {
            try await repairRepository.save(record)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    func updateRepairRecord(_ record: RepairRecord) async {
        do {
            var updatedRecord = record
            updatedRecord.updatedAt = Date()
            try await repairRepository.save(updatedRecord)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    func deleteRepairRecord(_ record: RepairRecord) async {
        do {
            try await repairRepository.delete(record)
            await loadRecords()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Statistics
    func servicesByType() -> [(ServiceType, Int)] {
        let grouped = Dictionary(grouping: serviceRecords) { $0.type }
        return ServiceType.allCases.compactMap { type in
            let count = grouped[type]?.count ?? 0
            return count > 0 ? (type, count) : nil
        }
    }
    
    func costByYear() -> [(Int, Decimal)] {
        let grouped = Dictionary(grouping: serviceRecords) { record in
            Calendar.current.component(.year, from: record.date)
        }
        
        return grouped.map { year, records in
            let totalCost = records.reduce(0) { sum, record in
                sum + (record.cost ?? 0)
            }
            return (year, totalCost)
        }.sorted { $0.0 < $1.0 }
    }
    
    func averageRepairTime() -> Double? {
        let completedRepairs = repairRecords.filter { $0.isCompleted }
        guard !completedRepairs.isEmpty else { return nil }
        
        let totalDays = completedRepairs.compactMap { $0.durationDays }.reduce(0, +)
        return Double(totalDays) / Double(completedRepairs.count)
    }
}
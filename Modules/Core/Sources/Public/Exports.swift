// Export public types from Core module

// Models
@_exported import struct Core.Item
@_exported import struct Core.Location
@_exported import struct Core.Receipt
@_exported import struct Core.Warranty
@_exported import struct Core.Budget
@_exported import struct Core.Collection
@_exported import struct Core.Tag
@_exported import struct Core.StorageUnit
@_exported import struct Core.ServiceRecord
@_exported import struct Core.InsurancePolicy
@_exported import struct Core.InsuranceClaim
@_exported import struct Core.Photo

// Enums
@_exported import enum Core.ItemCategory
@_exported import enum Core.ItemCondition
@_exported import enum Core.WarrantyType
@_exported import enum Core.BudgetPeriod
@_exported import enum Core.ServiceType
@_exported import enum Core.InsuranceType
@_exported import enum Core.ClaimStatus

// Protocols
@_exported import protocol Core.ItemRepository
@_exported import protocol Core.LocationRepository
@_exported import protocol Core.ReceiptRepository
@_exported import protocol Core.WarrantyRepository
@_exported import protocol Core.BudgetRepository
@_exported import protocol Core.CollectionRepository
@_exported import protocol Core.TagRepository
@_exported import protocol Core.StorageUnitRepository
@_exported import protocol Core.ServiceRecordRepository
@_exported import protocol Core.InsurancePolicyRepository
@_exported import protocol Core.PhotoRepository
@_exported import protocol Core.DocumentRepository

// Mock Repositories
@_exported import class Core.MockServiceRecordRepository
@_exported import class Core.MockInsurancePolicyRepository

// Services
@_exported import class Core.MockDataService
@_exported import class Core.ComprehensiveMockDataFactory

// Other useful types
@_exported import struct Core.RepositoryError
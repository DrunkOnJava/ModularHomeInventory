//
//  CollaborativeListService.swift
//  Core
//
//  Service for managing collaborative lists with real-time sync
//

import Foundation
import CloudKit
import Combine

@available(iOS 15.0, *)
public class CollaborativeListService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var lists: [CollaborativeList] = []
    @Published public var activeList: CollaborativeList?
    @Published public var collaborators: [Collaborator] = []
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var activities: [ListActivity] = []
    
    // MARK: - Types
    
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(String)
        
        public var isSyncing: Bool {
            if case .syncing = self { return true }
            return false
        }
    }
    
    public struct CollaborativeList: Identifiable, Codable, Equatable {
        public let id: UUID
        public var name: String
        public var description: String?
        public var type: ListType
        public var items: [ListItem]
        public var collaborators: [String] // User IDs
        public var createdBy: String
        public var createdDate: Date
        public var lastModified: Date
        public var settings: ListSettings
        public var isArchived: Bool
        public var completedItemsCount: Int
        
        public enum ListType: String, Codable, CaseIterable {
            case shopping = "Shopping List"
            case wishlist = "Wish List"
            case project = "Project Items"
            case moving = "Moving Checklist"
            case maintenance = "Maintenance List"
            case custom = "Custom List"
            
            public var icon: String {
                switch self {
                case .shopping: return "cart.fill"
                case .wishlist: return "star.fill"
                case .project: return "hammer.fill"
                case .moving: return "shippingbox.fill"
                case .maintenance: return "wrench.and.screwdriver.fill"
                case .custom: return "list.bullet"
                }
            }
            
            public var color: String {
                switch self {
                case .shopping: return "blue"
                case .wishlist: return "yellow"
                case .project: return "orange"
                case .moving: return "green"
                case .maintenance: return "red"
                case .custom: return "purple"
                }
            }
        }
        
        public init(name: String, type: ListType, createdBy: String) {
            self.id = UUID()
            self.name = name
            self.type = type
            self.items = []
            self.collaborators = [createdBy]
            self.createdBy = createdBy
            self.createdDate = Date()
            self.lastModified = Date()
            self.settings = ListSettings()
            self.isArchived = false
            self.completedItemsCount = 0
        }
    }
    
    public struct ListItem: Identifiable, Codable, Equatable {
        public let id: UUID
        public var title: String
        public var notes: String?
        public var quantity: Int
        public var isCompleted: Bool
        public var completedBy: String?
        public var completedDate: Date?
        public var assignedTo: String?
        public var priority: Priority
        public var linkedItemID: UUID? // Link to inventory item
        public var customFields: [String: String]
        public var addedBy: String
        public var addedDate: Date
        public var lastModifiedBy: String?
        public var lastModifiedDate: Date?
        
        public enum Priority: Int, Codable, CaseIterable {
            case low = 0
            case medium = 1
            case high = 2
            case urgent = 3
            
            public var displayName: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .urgent: return "Urgent"
                }
            }
            
            public var color: String {
                switch self {
                case .low: return "gray"
                case .medium: return "blue"
                case .high: return "orange"
                case .urgent: return "red"
                }
            }
        }
        
        public init(title: String, addedBy: String) {
            self.id = UUID()
            self.title = title
            self.quantity = 1
            self.isCompleted = false
            self.priority = .medium
            self.customFields = [:]
            self.addedBy = addedBy
            self.addedDate = Date()
        }
    }
    
    public struct ListSettings: Codable, Equatable {
        public var allowGuests: Bool
        public var requireApproval: Bool
        public var notifyOnChanges: Bool
        public var autoArchiveCompleted: Bool
        public var showCompletedItems: Bool
        public var sortOrder: SortOrder
        public var groupBy: GroupBy
        
        public enum SortOrder: String, Codable, CaseIterable {
            case manual = "Manual"
            case alphabetical = "Alphabetical"
            case priority = "Priority"
            case dateAdded = "Date Added"
            case assigned = "Assigned To"
        }
        
        public enum GroupBy: String, Codable, CaseIterable {
            case none = "None"
            case priority = "Priority"
            case assigned = "Assigned To"
            case completed = "Completed Status"
        }
        
        public init() {
            self.allowGuests = false
            self.requireApproval = false
            self.notifyOnChanges = true
            self.autoArchiveCompleted = false
            self.showCompletedItems = true
            self.sortOrder = .manual
            self.groupBy = .none
        }
    }
    
    public struct Collaborator: Identifiable, Codable, Equatable {
        public let id: String // User ID
        public var name: String
        public var email: String?
        public var avatarData: Data?
        public var role: CollaboratorRole
        public var joinedDate: Date
        public var lastActiveDate: Date
        public var itemsAdded: Int
        public var itemsCompleted: Int
        
        public enum CollaboratorRole: String, Codable, CaseIterable {
            case owner = "Owner"
            case editor = "Editor"
            case viewer = "Viewer"
            
            public var canEdit: Bool {
                self != .viewer
            }
            
            public var canDelete: Bool {
                self == .owner
            }
            
            public var canInvite: Bool {
                self == .owner
            }
        }
    }
    
    public struct ListActivity: Identifiable, Codable, Equatable {
        public let id = UUID()
        public let listID: UUID
        public let userID: String
        public let userName: String
        public let action: ActivityAction
        public let itemTitle: String?
        public let timestamp: Date
        public let details: String?
        
        public enum ActivityAction: String, Codable {
            case created = "created the list"
            case addedItem = "added"
            case completedItem = "completed"
            case uncompletedItem = "uncompleted"
            case editedItem = "edited"
            case deletedItem = "deleted"
            case assignedItem = "assigned"
            case invitedUser = "invited"
            case joinedList = "joined the list"
            case leftList = "left the list"
            case archivedList = "archived the list"
        }
    }
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private var subscriptions: [CKSubscription] = []
    private var cancellables = Set<AnyCancellable>()
    private let activityLimit = 50
    
    // MARK: - Initialization
    
    public init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        setupCloudKit()
        loadLists()
    }
    
    // MARK: - Setup
    
    private func setupCloudKit() {
        // Set up real-time sync subscriptions
        createSubscriptions()
        
        // Listen for remote notifications
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                self?.loadLists()
            }
            .store(in: &cancellables)
    }
    
    private func createSubscriptions() {
        // Subscribe to list changes
        let listSubscription = CKQuerySubscription(
            recordType: "CollaborativeList",
            predicate: NSPredicate(value: true),
            subscriptionID: "collaborative-list-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.alertLocalizationKey = "LIST_UPDATED"
        listSubscription.notificationInfo = notificationInfo
        
        sharedDatabase.save(listSubscription) { subscription, error in
            if let error = error {
                print("Failed to create subscription: \(error)")
            }
        }
    }
    
    // MARK: - List Management
    
    public func createList(name: String, type: CollaborativeList.ListType, description: String? = nil) async throws -> CollaborativeList {
        let list = CollaborativeList(
            name: name,
            type: type,
            createdBy: getCurrentUserID()
        )
        
        // Save to CloudKit
        let record = createRecord(from: list)
        
        return try await withCheckedThrowingContinuation { continuation in
            sharedDatabase.save(record) { savedRecord, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    DispatchQueue.main.async {
                        self.lists.append(list)
                        self.logActivity(.created, listID: list.id, itemTitle: nil)
                    }
                    continuation.resume(returning: list)
                }
            }
        }
    }
    
    public func updateList(_ list: CollaborativeList) async throws {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else {
            throw CollaborativeListError.listNotFound
        }
        
        var updatedList = list
        updatedList.lastModified = Date()
        
        let record = createRecord(from: updatedList)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sharedDatabase.save(record) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    DispatchQueue.main.async {
                        self.lists[index] = updatedList
                        if self.activeList?.id == list.id {
                            self.activeList = updatedList
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    public func deleteList(_ list: CollaborativeList) async throws {
        let recordID = CKRecord.ID(recordName: list.id.uuidString)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sharedDatabase.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    DispatchQueue.main.async {
                        self.lists.removeAll { $0.id == list.id }
                        if self.activeList?.id == list.id {
                            self.activeList = nil
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Item Management
    
    public func addItem(to list: CollaborativeList, title: String, notes: String? = nil, priority: ListItem.Priority = .medium) async throws {
        var item = ListItem(title: title, addedBy: getCurrentUserID())
        item.notes = notes
        item.priority = priority
        
        var updatedList = list
        updatedList.items.append(item)
        updatedList.lastModified = Date()
        
        try await updateList(updatedList)
        logActivity(.addedItem, listID: list.id, itemTitle: title)
    }
    
    public func updateItem(_ item: ListItem, in list: CollaborativeList) async throws {
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }),
              let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == item.id }) else {
            throw CollaborativeListError.itemNotFound
        }
        
        var updatedItem = item
        updatedItem.lastModifiedBy = getCurrentUserID()
        updatedItem.lastModifiedDate = Date()
        
        var updatedList = lists[listIndex]
        updatedList.items[itemIndex] = updatedItem
        updatedList.lastModified = Date()
        
        try await updateList(updatedList)
        logActivity(.editedItem, listID: list.id, itemTitle: item.title)
    }
    
    public func toggleItemCompletion(_ item: ListItem, in list: CollaborativeList) async throws {
        var updatedItem = item
        updatedItem.isCompleted.toggle()
        
        if updatedItem.isCompleted {
            updatedItem.completedBy = getCurrentUserID()
            updatedItem.completedDate = Date()
        } else {
            updatedItem.completedBy = nil
            updatedItem.completedDate = nil
        }
        
        try await updateItem(updatedItem, in: list)
        
        let action: ListActivity.ActivityAction = updatedItem.isCompleted ? .completedItem : .uncompletedItem
        logActivity(action, listID: list.id, itemTitle: item.title)
    }
    
    public func deleteItem(_ item: ListItem, from list: CollaborativeList) async throws {
        guard let listIndex = lists.firstIndex(where: { $0.id == list.id }) else {
            throw CollaborativeListError.listNotFound
        }
        
        var updatedList = lists[listIndex]
        updatedList.items.removeAll { $0.id == item.id }
        updatedList.lastModified = Date()
        
        try await updateList(updatedList)
        logActivity(.deletedItem, listID: list.id, itemTitle: item.title)
    }
    
    // MARK: - Collaboration
    
    public func inviteCollaborator(to list: CollaborativeList, email: String, role: Collaborator.CollaboratorRole) async throws {
        // In real implementation, would send invitation via CloudKit sharing
        // For now, simulate the process
        
        let collaborator = Collaborator(
            id: UUID().uuidString,
            name: email.components(separatedBy: "@").first ?? "User",
            email: email,
            role: role,
            joinedDate: Date(),
            lastActiveDate: Date(),
            itemsAdded: 0,
            itemsCompleted: 0
        )
        
        DispatchQueue.main.async {
            self.collaborators.append(collaborator)
        }
        
        logActivity(.invitedUser, listID: list.id, itemTitle: email)
    }
    
    public func removeCollaborator(_ collaborator: Collaborator, from list: CollaborativeList) async throws {
        guard collaborator.role != .owner else {
            throw CollaborativeListError.cannotRemoveOwner
        }
        
        var updatedList = list
        updatedList.collaborators.removeAll { $0 == collaborator.id }
        
        try await updateList(updatedList)
        
        DispatchQueue.main.async {
            self.collaborators.removeAll { $0.id == collaborator.id }
        }
    }
    
    // MARK: - Sync
    
    public func syncLists() {
        syncStatus = .syncing
        
        let query = CKQuery(recordType: "CollaborativeList", predicate: NSPredicate(value: true))
        
        sharedDatabase.fetch(withQuery: query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    self?.processRecords(matchResults.compactMap { _, result in
                        try? result.get()
                    })
                    self?.syncStatus = .idle
                case .failure(let error):
                    self?.syncStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadLists() {
        syncLists()
        loadActivities()
    }
    
    private func loadActivities() {
        // Load recent activities
        let query = CKQuery(
            recordType: "ListActivity",
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = activityLimit
        
        var activities: [ListActivity] = []
        
        queryOperation.recordMatchedBlock = { _, result in
            if let record = try? result.get(),
               let activity = self.createActivity(from: record) {
                activities.append(activity)
            }
        }
        
        queryOperation.queryResultBlock = { _ in
            DispatchQueue.main.async {
                self.activities = activities
            }
        }
        
        sharedDatabase.add(queryOperation)
    }
    
    private func createRecord(from list: CollaborativeList) -> CKRecord {
        let record = CKRecord(recordType: "CollaborativeList", recordID: CKRecord.ID(recordName: list.id.uuidString))
        
        record["name"] = list.name
        record["description"] = list.description
        record["type"] = list.type.rawValue
        record["createdBy"] = list.createdBy
        record["createdDate"] = list.createdDate
        record["lastModified"] = list.lastModified
        record["isArchived"] = list.isArchived
        record["collaborators"] = list.collaborators
        
        // Encode items and settings as JSON
        if let itemsData = try? JSONEncoder().encode(list.items) {
            record["items"] = String(data: itemsData, encoding: .utf8)
        }
        
        if let settingsData = try? JSONEncoder().encode(list.settings) {
            record["settings"] = String(data: settingsData, encoding: .utf8)
        }
        
        return record
    }
    
    private func createList(from record: CKRecord) -> CollaborativeList? {
        guard let name = record["name"] as? String,
              let typeString = record["type"] as? String,
              let type = CollaborativeList.ListType(rawValue: typeString),
              let createdBy = record["createdBy"] as? String else {
            return nil
        }
        
        var list = CollaborativeList(name: name, type: type, createdBy: createdBy)
        
        list.description = record["description"] as? String
        list.createdDate = record["createdDate"] as? Date ?? Date()
        list.lastModified = record["lastModified"] as? Date ?? Date()
        list.isArchived = record["isArchived"] as? Bool ?? false
        list.collaborators = record["collaborators"] as? [String] ?? [createdBy]
        
        // Decode items and settings from JSON
        if let itemsString = record["items"] as? String,
           let itemsData = itemsString.data(using: .utf8),
           let items = try? JSONDecoder().decode([ListItem].self, from: itemsData) {
            list.items = items
        }
        
        if let settingsString = record["settings"] as? String,
           let settingsData = settingsString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(ListSettings.self, from: settingsData) {
            list.settings = settings
        }
        
        return list
    }
    
    private func createActivity(from record: CKRecord) -> ListActivity? {
        guard let listIDString = record["listID"] as? String,
              let listID = UUID(uuidString: listIDString),
              let userID = record["userID"] as? String,
              let userName = record["userName"] as? String,
              let actionString = record["action"] as? String,
              let action = ListActivity.ActivityAction(rawValue: actionString),
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }
        
        return ListActivity(
            listID: listID,
            userID: userID,
            userName: userName,
            action: action,
            itemTitle: record["itemTitle"] as? String,
            timestamp: timestamp,
            details: record["details"] as? String
        )
    }
    
    private func processRecords(_ records: [CKRecord]) {
        let lists = records.compactMap { createList(from: $0) }
        self.lists = lists
    }
    
    private func logActivity(_ action: ListActivity.ActivityAction, listID: UUID, itemTitle: String?) {
        let activity = ListActivity(
            listID: listID,
            userID: getCurrentUserID(),
            userName: getCurrentUserName(),
            action: action,
            itemTitle: itemTitle,
            timestamp: Date(),
            details: nil
        )
        
        // Save to CloudKit
        let record = CKRecord(recordType: "ListActivity")
        record["listID"] = listID.uuidString
        record["userID"] = activity.userID
        record["userName"] = activity.userName
        record["action"] = activity.action.rawValue
        record["itemTitle"] = activity.itemTitle
        record["timestamp"] = activity.timestamp
        
        sharedDatabase.save(record) { _, error in
            if error == nil {
                DispatchQueue.main.async {
                    self.activities.insert(activity, at: 0)
                    if self.activities.count > self.activityLimit {
                        self.activities.removeLast()
                    }
                }
            }
        }
    }
    
    private func getCurrentUserID() -> String {
        // In real implementation, would get from CloudKit
        return "current-user-id"
    }
    
    private func getCurrentUserName() -> String {
        // In real implementation, would get from user profile
        return "Current User"
    }
}

// MARK: - Errors

public enum CollaborativeListError: LocalizedError {
    case listNotFound
    case itemNotFound
    case permissionDenied
    case cannotRemoveOwner
    case syncFailed
    
    public var errorDescription: String? {
        switch self {
        case .listNotFound:
            return "The list could not be found"
        case .itemNotFound:
            return "The item could not be found"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .cannotRemoveOwner:
            return "The list owner cannot be removed"
        case .syncFailed:
            return "Failed to sync with cloud"
        }
    }
}
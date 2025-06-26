//
//  FamilySharingService.swift
//  Core
//
//  Service for managing family sharing of inventory items
//

import Foundation
import CloudKit
import Combine

@available(iOS 15.0, *)
public class FamilySharingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var isSharing = false
    @Published public var familyMembers: [FamilyMember] = []
    @Published public var sharedItems: [Item] = []
    @Published public var pendingInvitations: [Invitation] = []
    @Published public var shareStatus: ShareStatus = .notShared
    @Published public var syncStatus: SyncStatus = .idle
    
    // MARK: - Types
    
    public enum ShareStatus {
        case notShared
        case owner(shareID: String)
        case participant(shareID: String)
        case pending
        
        public var isShared: Bool {
            switch self {
            case .owner, .participant:
                return true
            default:
                return false
            }
        }
    }
    
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case error(String)
    }
    
    public struct FamilyMember: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String?
        public let role: MemberRole
        public let joinedDate: Date
        public var lastActiveDate: Date
        public var avatarData: Data?
        
        public enum MemberRole: String, Codable, CaseIterable {
            case owner = "Owner"
            case admin = "Admin"
            case member = "Member"
            case viewer = "Viewer"
            
            public var permissions: Set<Permission> {
                switch self {
                case .owner:
                    return Set(Permission.allCases)
                case .admin:
                    return [.read, .write, .delete, .invite]
                case .member:
                    return [.read, .write]
                case .viewer:
                    return [.read]
                }
            }
        }
    }
    
    public enum Permission: String, CaseIterable, Codable {
        case read = "Read"
        case write = "Write"
        case delete = "Delete"
        case invite = "Invite"
        case manage = "Manage"
    }
    
    public struct Invitation: Identifiable, Codable {
        public let id = UUID()
        public let recipientEmail: String
        public let recipientName: String?
        public let senderName: String
        public let role: FamilyMember.MemberRole
        public let sentDate: Date
        public let expirationDate: Date
        public var status: InvitationStatus
        
        public enum InvitationStatus: String, Codable {
            case pending = "Pending"
            case accepted = "Accepted"
            case declined = "Declined"
            case expired = "Expired"
        }
    }
    
    public struct ShareSettings: Codable {
        public var familyName: String
        public var autoAcceptFromContacts: Bool
        public var requireApprovalForChanges: Bool
        public var allowGuestViewers: Bool
        public var itemVisibility: ItemVisibility
        
        public enum ItemVisibility: String, Codable, CaseIterable {
            case all = "All Items"
            case categorized = "By Category"
            case tagged = "By Tags"
            case custom = "Custom"
        }
        
        public init() {
            self.familyName = "My Family"
            self.autoAcceptFromContacts = true
            self.requireApprovalForChanges = false
            self.allowGuestViewers = false
            self.itemVisibility = .all
        }
    }
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private var shareSubscription: CKDatabaseSubscription?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        setupCloudKit()
        loadFamilyData()
    }
    
    // MARK: - Setup
    
    private func setupCloudKit() {
        // Check CloudKit availability
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.setupSubscriptions()
                case .noAccount:
                    self?.syncStatus = .error("iCloud account not available")
                default:
                    self?.syncStatus = .error("CloudKit not available")
                }
            }
        }
    }
    
    private func setupSubscriptions() {
        // Subscribe to shared database changes
        let subscription = CKDatabaseSubscription(subscriptionID: "family-share-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        sharedDatabase.save(subscription) { _, error in
            if let error = error {
                print("Failed to create subscription: \(error)")
            }
        }
    }
    
    // MARK: - Family Management
    
    public func createFamilyShare(name: String, completion: @escaping (Result<String, Error>) -> Void) {
        let shareRecord = CKRecord(recordType: "FamilyShare")
        shareRecord["name"] = name
        shareRecord["createdDate"] = Date()
        shareRecord["ownerID"] = getCurrentUserID()
        
        let share = CKShare(rootRecord: shareRecord)
        share[CKShare.SystemFieldKey.title] = "\(name) Inventory"
        share[CKShare.SystemFieldKey.shareType] = "com.homeinventory.family"
        share.publicPermission = .none
        
        let operation = CKModifyRecordsOperation(
            recordsToSave: [shareRecord, share],
            recordIDsToDelete: nil
        )
        
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.shareStatus = .owner(shareID: share.recordID.recordName)
                    self.isSharing = true
                    completion(.success(share.recordID.recordName))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        privateDatabase.add(operation)
    }
    
    public func joinFamilyShare(shareMetadata: CKShare.Metadata, completion: @escaping (Result<Void, Error>) -> Void) {
        let operation = CKAcceptSharesOperation(shareMetadatas: [shareMetadata])
        
        operation.acceptSharesResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.shareStatus = .participant(shareID: shareMetadata.share.recordID.recordName)
                    self.isSharing = true
                    self.loadFamilyData()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        container.add(operation)
    }
    
    public func inviteMember(email: String, name: String?, role: FamilyMember.MemberRole, completion: @escaping (Result<Void, Error>) -> Void) {
        guard case .owner(let shareID) = shareStatus else {
            completion(.failure(FamilySharingError.notOwner))
            return
        }
        
        // Create invitation
        let invitation = Invitation(
            recipientEmail: email,
            recipientName: name,
            senderName: getCurrentUserName(),
            role: role,
            sentDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
            status: .pending
        )
        
        // Get the share record
        let shareRecordID = CKRecord.ID(recordName: shareID)
        
        privateDatabase.fetch(withRecordID: shareRecordID) { [weak self] record, error in
            guard let share = record as? CKShare else {
                completion(.failure(error ?? FamilySharingError.shareNotFound))
                return
            }
            
            // In a real implementation, you would use CKShare's URL to invite users
            // For now, we'll just save the share with the appropriate permissions
            share[CKShare.SystemFieldKey.title] = "Family Inventory"
            share[CKShare.SystemFieldKey.shareType] = "com.homeinventory.family"
            share.publicPermission = .none // Private share
            
            // Save the share
            self?.privateDatabase.save(share) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self?.pendingInvitations.append(invitation)
                        // Send email invitation
                        self?.sendInvitationEmail(invitation)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    public func removeMember(_ member: FamilyMember, completion: @escaping (Result<Void, Error>) -> Void) {
        guard case .owner(let shareID) = shareStatus else {
            completion(.failure(FamilySharingError.notOwner))
            return
        }
        
        let shareRecordID = CKRecord.ID(recordName: shareID)
        
        privateDatabase.fetch(withRecordID: shareRecordID) { [weak self] record, error in
            guard let share = record as? CKShare else {
                completion(.failure(error ?? FamilySharingError.shareNotFound))
                return
            }
            
            // Find and remove participant
            if let participant = share.participants.first(where: { $0.userIdentity.userRecordID?.recordName == member.id }) {
                share.removeParticipant(participant)
                
                self?.privateDatabase.save(share) { _, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.familyMembers.removeAll { $0.id == member.id }
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Item Sharing
    
    public func shareItem(_ item: Item, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isSharing else {
            completion(.failure(FamilySharingError.notSharing))
            return
        }
        
        let sharedItem = createSharedItemRecord(from: item)
        
        sharedDatabase.save(sharedItem) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.sharedItems.append(item)
                    completion(.success(()))
                }
            }
        }
    }
    
    public func unshareItem(_ item: Item, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: item.id.uuidString)
        
        sharedDatabase.delete(withRecordID: recordID) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.sharedItems.removeAll { $0.id == item.id }
                    completion(.success(()))
                }
            }
        }
    }
    
    public func syncSharedItems() {
        syncStatus = .syncing
        
        let query = CKQuery(recordType: "SharedItem", predicate: NSPredicate(value: true))
        
        sharedDatabase.fetch(withQuery: query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (results, _)):
                    self?.processSharedItems(results.compactMap { _, result in
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
    
    private func loadFamilyData() {
        // Load family members
        loadFamilyMembers()
        
        // Load shared items
        syncSharedItems()
        
        // Load pending invitations
        loadPendingInvitations()
    }
    
    private func loadFamilyMembers() {
        guard case .owner(let shareID) = shareStatus else { return }
        
        let shareRecordID = CKRecord.ID(recordName: shareID)
        
        privateDatabase.fetch(withRecordID: shareRecordID) { [weak self] record, error in
            guard let share = record as? CKShare else { return }
            
            DispatchQueue.main.async {
                self?.familyMembers = share.participants.compactMap { participant in
                    guard let userID = participant.userIdentity.userRecordID?.recordName else { return nil }
                    
                    return FamilyMember(
                        id: userID,
                        name: participant.userIdentity.nameComponents?.formatted() ?? "Unknown",
                        email: participant.userIdentity.lookupInfo?.emailAddress,
                        role: self?.roleFromPermission(participant.permission) ?? .viewer,
                        joinedDate: Date(),
                        lastActiveDate: Date()
                    )
                }
            }
        }
    }
    
    private func loadPendingInvitations() {
        // In real implementation, would fetch from CloudKit
        // For now, using local storage
    }
    
    private func createSharedItemRecord(from item: Item) -> CKRecord {
        let record = CKRecord(recordType: "SharedItem", recordID: CKRecord.ID(recordName: item.id.uuidString))
        
        record["name"] = item.name
        record["category"] = item.category.rawValue
        record["brand"] = item.brand
        record["model"] = item.model
        record["serialNumber"] = item.serialNumber
        record["purchasePrice"] = item.purchasePrice as? NSNumber
        record["purchaseDate"] = item.purchaseDate
        record["notes"] = item.notes
        record["sharedBy"] = getCurrentUserID()
        record["sharedDate"] = Date()
        
        return record
    }
    
    private func processSharedItems(_ records: [CKRecord]) {
        sharedItems = records.compactMap { record in
            guard let name = record["name"] as? String,
                  let categoryString = record["category"] as? String,
                  let category = ItemCategory(rawValue: categoryString) else {
                return nil
            }
            
            var item = Item(name: name, category: category)
            item.brand = record["brand"] as? String
            item.model = record["model"] as? String
            item.serialNumber = record["serialNumber"] as? String
            if let priceNumber = record["purchasePrice"] as? NSNumber {
                item.purchasePrice = Decimal(string: priceNumber.stringValue)
            }
            item.purchaseDate = record["purchaseDate"] as? Date
            item.notes = record["notes"] as? String
            
            return item
        }
    }
    
    private func roleFromPermission(_ permission: CKShare.ParticipantPermission) -> FamilyMember.MemberRole {
        switch permission {
        case .readOnly:
            return .viewer
        case .readWrite:
            return .member
        @unknown default:
            return .viewer
        }
    }
    
    private func getCurrentUserID() -> String {
        // In real implementation, would get from CloudKit
        return "current-user-id"
    }
    
    private func getCurrentUserName() -> String {
        // In real implementation, would get from CloudKit or user profile
        return "Current User"
    }
    
    private func sendInvitationEmail(_ invitation: Invitation) {
        // In real implementation, would send email via backend
        print("Sending invitation to \(invitation.recipientEmail)")
    }
}

// MARK: - Errors

public enum FamilySharingError: LocalizedError {
    case notOwner
    case notSharing
    case shareNotFound
    case permissionDenied
    case invalidInvitation
    
    public var errorDescription: String? {
        switch self {
        case .notOwner:
            return "Only the owner can perform this action"
        case .notSharing:
            return "Family sharing is not enabled"
        case .shareNotFound:
            return "Family share not found"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .invalidInvitation:
            return "Invalid or expired invitation"
        }
    }
}
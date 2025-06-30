//
//  BackupViewSnapshotTests.swift
//  HomeInventoryModularTests
//
//  Snapshot tests for Backup-related views
//

import XCTest
import SnapshotTesting
import SwiftUI
@testable import Core
@testable import SharedUI

final class BackupViewSnapshotTests: XCTestCase {
    
    // MARK: - Mock Data
    
    private var mockBackups: [Backup] {
        [
            Backup(
                id: UUID(),
                name: "Automatic Backup",
                date: Date(),
                size: 15_234_567, // ~15MB
                itemCount: 142,
                type: .automatic,
                location: .icloud,
                isEncrypted: true,
                version: "1.0.5"
            ),
            Backup(
                id: UUID(),
                name: "Manual Backup - Before Update",
                date: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
                size: 14_876_543, // ~14MB
                itemCount: 138,
                type: .manual,
                location: .local,
                isEncrypted: true,
                version: "1.0.4"
            ),
            Backup(
                id: UUID(),
                name: "Monthly Backup",
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 1 month ago
                size: 12_345_678, // ~12MB
                itemCount: 125,
                type: .scheduled,
                location: .icloud,
                isEncrypted: true,
                version: "1.0.3"
            )
        ]
    }
    
    // MARK: - Tests
    
    func testBackupManagerView_Default() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                BackupManagerView(
                    backups: mockBackups,
                    selectedBackup: .constant(nil)
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBackupManagerView_Empty() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                BackupManagerView(
                    backups: [],
                    selectedBackup: .constant(nil)
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBackupDetailsView() {
        withSnapshotTesting(record: .all) {
            let view = BackupDetailsView(backup: mockBackups[0])
                .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testCreateBackupView() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                CreateBackupView(
                    onComplete: { _ in }
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testCreateBackupView_InProgress() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                CreateBackupView(
                    onComplete: { _ in },
                    isCreating: true,
                    progress: 0.45
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testRestoreBackupView() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                RestoreBackupView(
                    backup: mockBackups[1],
                    onRestore: { _ in }
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testRestoreBackupView_Restoring() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                RestoreBackupView(
                    backup: mockBackups[1],
                    onRestore: { _ in },
                    isRestoring: true,
                    progress: 0.75
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testAutoBackupSettingsView() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                AutoBackupSettingsView(
                    settings: AutoBackupSettings(
                        enabled: true,
                        frequency: .daily,
                        time: DateComponents(hour: 2, minute: 0),
                        wifiOnly: true,
                        deleteOldBackups: true,
                        keepBackupCount: 5
                    )
                )
            }
            .frame(width: 390, height: 844)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
    
    func testBackupManagerView_iPad() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                BackupManagerView(
                    backups: mockBackups,
                    selectedBackup: .constant(mockBackups[0])
                )
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .frame(width: 1024, height: 1366)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPadPro12_9))
        }
    }
    
    func testBackupManagerView_DarkMode() {
        withSnapshotTesting(record: .all) {
            let view = NavigationView {
                BackupManagerView(
                    backups: mockBackups,
                    selectedBackup: .constant(nil)
                )
            }
            .frame(width: 390, height: 844)
            .preferredColorScheme(.dark)
            
            let hostingController = UIHostingController(rootView: view)
            assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
        }
    }
}
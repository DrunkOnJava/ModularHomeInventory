import XCTest
import SnapshotTesting
import SwiftUI
@testable import Receipts
@testable import Core
@testable import SharedUI

final class ReceiptsViewSnapshotTests: SnapshotTestCase {
    
    func testReceiptsListView_Empty() {
        let view = NavigationStack {
            ReceiptsListView()
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testReceiptDetailView() {
        let receipt = Receipt.sample
        let view = NavigationStack {
            ReceiptDetailView(receipt: receipt)
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
    
    func testReceiptRow() {
        let receipt = Receipt.sample
        let row = ReceiptRowView(receipt: receipt)
            .frame(width: 350)
            .padding()
        
        assertSnapshot(matching: row, as: .image)
    }
    
    func testReceiptsListView_DarkMode() {
        let view = NavigationStack {
            ReceiptsListView()
        }
        
        assertSnapshot(
            matching: view,
            as: .image(on: .iPhone16ProMax, traits: .init(userInterfaceStyle: .dark))
        )
    }
    
    func testAddReceiptView() {
        let view = NavigationStack {
            AddReceiptView(isPresented: .constant(true))
        }
        
        assertSnapshot(matching: view, as: .image(on: .iPhone16ProMax))
    }
}

// Helper extension
extension Receipt {
    static var sample: Receipt {
        Receipt(
            id: UUID(),
            itemId: UUID(),
            storeName: "Apple Store",
            purchaseDate: Date(),
            totalAmount: 1199.00,
            taxAmount: 95.92,
            currency: "USD",
            receiptNumber: "R123456789",
            paymentMethod: "Credit Card",
            notes: "Extended warranty purchased",
            imageData: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Mock receipt row view
struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.storeName)
                    .font(.headline)
                Text(receipt.purchaseDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(receipt.totalAmount, specifier: "%.2f")")
                    .font(.headline)
                Text(receipt.paymentMethod ?? "Cash")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
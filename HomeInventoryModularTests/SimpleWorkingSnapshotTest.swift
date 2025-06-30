//
//  SimpleWorkingSnapshotTest.swift
//  HomeInventoryModularTests
//

import XCTest
import SnapshotTesting
import SwiftUI

class SimpleWorkingSnapshotTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testSimpleText() {
        withSnapshotTesting(record: .all) {
            let view = Text("Hello, Snapshots!")
                .font(.largeTitle)
                .padding()
            
            let vc = UIHostingController(rootView: view)
            assertSnapshot(matching: vc, as: .image(on: .iPhone13))
        }
    }
    
    func testColoredView() {
        withSnapshotTesting(record: .all) {
            let view = VStack {
                Text("Snapshot Test")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(width: 300, height: 100)
            .background(Color.blue)
            .cornerRadius(10)
            
            let vc = UIHostingController(rootView: view)
            assertSnapshot(matching: vc, as: .image(on: .iPhone13))
        }
    }
}
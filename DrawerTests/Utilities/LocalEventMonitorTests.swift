//
//  LocalEventMonitorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class LocalEventMonitorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: LocalEventMonitor!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Create a monitor with a pass-through handler for testing
        sut = LocalEventMonitor(mask: .mouseMoved) { event in event }
    }
    
    override func tearDown() {
        sut?.stop()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - LEM-001: Initial isRunning is false
    
    func testLEM001_InitialIsRunningIsFalse() {
        // Arrange - sut is already created in setUp with no start() call
        
        // Act
        let isRunning = sut.isRunning
        
        // Assert
        XCTAssertFalse(
            isRunning,
            "LEM-001: isRunning should be false on init before start() is called"
        )
    }
}

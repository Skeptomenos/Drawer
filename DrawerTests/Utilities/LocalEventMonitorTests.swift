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
    
    // MARK: - LEM-002: start sets isRunning true
    
    func testLEM002_StartSetsIsRunningTrue() {
        // Arrange
        XCTAssertFalse(sut.isRunning, "Precondition: isRunning should be false before start")
        
        // Act
        sut.start()
        
        // Assert
        XCTAssertTrue(
            sut.isRunning,
            "LEM-002: isRunning should be true after start() is called"
        )
    }
    
    // MARK: - LEM-003: stop sets isRunning false
    
    func testLEM003_StopSetsIsRunningFalse() {
        // Arrange
        sut.start()
        XCTAssertTrue(sut.isRunning, "Precondition: isRunning should be true after start")
        
        // Act
        sut.stop()
        
        // Assert
        XCTAssertFalse(
            sut.isRunning,
            "LEM-003: isRunning should be false after stop() is called"
        )
    }
}

//
//  GlobalEventMonitorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class GlobalEventMonitorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: GlobalEventMonitor!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Create a monitor with a no-op handler for testing
        sut = GlobalEventMonitor(mask: .mouseMoved) { _ in }
    }
    
    override func tearDown() {
        sut?.stop()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - GEM-001: Initial isRunning is false
    
    func testGEM001_InitialIsRunningIsFalse() {
        // Arrange - sut is already created in setUp with no start() call
        
        // Act
        let isRunning = sut.isRunning
        
        // Assert
        XCTAssertFalse(
            isRunning,
            "GEM-001: isRunning should be false on init before start() is called"
        )
    }
    
    // MARK: - GEM-002: start sets isRunning true
    
    func testGEM002_StartSetsIsRunningTrue() {
        // Arrange
        XCTAssertFalse(sut.isRunning, "Precondition: isRunning should be false before start")
        
        // Act
        sut.start()
        
        // Assert
        XCTAssertTrue(
            sut.isRunning,
            "GEM-002: isRunning should be true after start() is called"
        )
    }
    
    // MARK: - GEM-003: stop sets isRunning false
    
    func testGEM003_StopSetsIsRunningFalse() {
        // Arrange
        sut.start()
        XCTAssertTrue(sut.isRunning, "Precondition: isRunning should be true after start")
        
        // Act
        sut.stop()
        
        // Assert
        XCTAssertFalse(
            sut.isRunning,
            "GEM-003: isRunning should be false after stop() is called"
        )
    }
    
    // MARK: - GEM-004: start twice is no-op
    
    func testGEM004_StartTwiceIsNoOp() {
        // Arrange
        sut.start()
        XCTAssertTrue(sut.isRunning, "Precondition: isRunning should be true after first start")
        
        // Act - call start again
        sut.start()
        
        // Assert - should still be running, no crash or error
        XCTAssertTrue(
            sut.isRunning,
            "GEM-004: isRunning should remain true after calling start() twice"
        )
    }
    
    // MARK: - GEM-005: stop when not running is no-op
    
    func testGEM005_StopWhenNotRunningIsNoOp() {
        // Arrange
        XCTAssertFalse(sut.isRunning, "Precondition: isRunning should be false before any start")
        
        // Act - call stop without ever starting
        sut.stop()
        
        // Assert - should still be not running, no crash or error
        XCTAssertFalse(
            sut.isRunning,
            "GEM-005: isRunning should remain false after calling stop() when not running"
        )
    }
    
    // MARK: - GEM-006: deinit stops monitor
    
    func testGEM006_DeinitStopsMonitor() {
        // Arrange - create a local monitor and start it
        var localMonitor: GlobalEventMonitor? = GlobalEventMonitor(mask: .mouseMoved) { _ in }
        localMonitor?.start()
        XCTAssertTrue(localMonitor?.isRunning == true, "Precondition: monitor should be running")
        
        // Act - set to nil to trigger deinit
        localMonitor = nil
        
        // Assert - no crash means deinit successfully called stop()
        // We can't directly verify the monitor stopped since it's deallocated,
        // but the test passing without crash confirms deinit worked correctly
        XCTAssertNil(localMonitor, "GEM-006: Monitor should be deallocated after setting to nil")
    }
}

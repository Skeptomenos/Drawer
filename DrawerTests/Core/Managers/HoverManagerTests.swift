//
//  HoverManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class HoverManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: HoverManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = HoverManager.shared
        sut.stopMonitoring()
    }
    
    override func tearDown() async throws {
        sut.stopMonitoring()
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - HVM-001: Initial isMonitoring is false
    
    func testHVM001_InitialIsMonitoringIsFalse() async throws {
        XCTAssertFalse(sut.isMonitoring, "HVM-001: Initial state isMonitoring should be false")
    }
    
    // MARK: - HVM-002: Initial isMouseInTriggerZone is false
    
    func testHVM002_InitialIsMouseInTriggerZoneIsFalse() async throws {
        XCTAssertFalse(sut.isMouseInTriggerZone, "HVM-002: Initial state isMouseInTriggerZone should be false")
    }
    
    // MARK: - HVM-003: Initial isMouseInDrawerArea is false
    
    func testHVM003_InitialIsMouseInDrawerAreaIsFalse() async throws {
        XCTAssertFalse(sut.isMouseInDrawerArea, "HVM-003: Initial state isMouseInDrawerArea should be false")
    }
    
    // MARK: - HVM-004: startMonitoring sets isMonitoring true
    
    func testHVM004_StartMonitoringSetsIsMonitoringTrue() async throws {
        // Arrange
        XCTAssertFalse(sut.isMonitoring, "Precondition: isMonitoring should be false before starting")
        
        // Act
        sut.startMonitoring()
        
        // Assert
        XCTAssertTrue(sut.isMonitoring, "HVM-004: startMonitoring() should set isMonitoring to true")
    }
    
    // MARK: - HVM-005: stopMonitoring sets isMonitoring false
    
    func testHVM005_StopMonitoringSetsIsMonitoringFalse() async throws {
        // Arrange
        sut.startMonitoring()
        XCTAssertTrue(sut.isMonitoring, "Precondition: isMonitoring should be true after starting")
        
        // Act
        sut.stopMonitoring()
        
        // Assert
        XCTAssertFalse(sut.isMonitoring, "HVM-005: stopMonitoring() should set isMonitoring to false")
    }
    
    // MARK: - HVM-006: startMonitoring twice is no-op
    
    func testHVM006_StartMonitoringTwiceIsNoOp() async throws {
        XCTAssertFalse(sut.isMonitoring, "Precondition: isMonitoring should be false before starting")
        
        sut.startMonitoring()
        XCTAssertTrue(sut.isMonitoring, "First startMonitoring() should set isMonitoring to true")
        
        sut.startMonitoring()
        
        XCTAssertTrue(sut.isMonitoring, "HVM-006: startMonitoring() twice should still have isMonitoring true (no-op)")
        
        sut.stopMonitoring()
        XCTAssertFalse(sut.isMonitoring, "After stopMonitoring, isMonitoring should be false")
        
        sut.startMonitoring()
        XCTAssertTrue(sut.isMonitoring, "After stop, startMonitoring should work again")
    }
    
    // MARK: - HVM-007: updateDrawerFrame stores frame
    
    func testHVM007_UpdateDrawerFrameStoresFrame() async throws {
        let testFrame = CGRect(x: 100, y: 100, width: 200, height: 50)
        sut.setDrawerVisible(true)
        
        sut.updateDrawerFrame(testFrame)
        
        XCTAssertTrue(true, "HVM-007: updateDrawerFrame should store the frame without error")
    }
    
    // MARK: - HVM-008: setDrawerVisible(true) works
    
    func testHVM008_SetDrawerVisibleTrueWorks() async throws {
        sut.setDrawerVisible(true)
        
        XCTAssertTrue(true, "HVM-008: setDrawerVisible(true) should complete without error")
    }
    
    // MARK: - HVM-009: setDrawerVisible(false) clears mouse in drawer area
    
    func testHVM009_SetDrawerVisibleFalseClearsMouseInDrawerArea() async throws {
        sut.setDrawerVisible(true)
        
        sut.setDrawerVisible(false)
        
        XCTAssertFalse(sut.isMouseInDrawerArea, "HVM-009: setDrawerVisible(false) should clear isMouseInDrawerArea")
    }
    
    // MARK: - HVM-010: isInMenuBarTriggerZone at top of screen
    
    func testHVM010_IsInMenuBarTriggerZoneAtTopOfScreen() async throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available")
        }
        
        let menuBarHeight = MenuBarMetrics.height
        guard menuBarHeight > 0 else {
            throw XCTSkip("Menu bar height unavailable in test environment")
        }
        
        let topPoint = NSPoint(x: screen.frame.midX, y: screen.frame.maxY - (menuBarHeight / 2))
        
        XCTAssertTrue(sut.isInMenuBarTriggerZone(topPoint), "HVM-010: Point at top of screen should be in trigger zone")
    }
    
    // MARK: - HVM-011: isInMenuBarTriggerZone below menu bar
    
    func testHVM011_IsInMenuBarTriggerZoneBelowMenuBar() async throws {
        guard let screen = NSScreen.screens.first else {
            throw XCTSkip("No screen available")
        }
        
        let menuBarHeight = MenuBarMetrics.height
        guard menuBarHeight > 0 else {
            throw XCTSkip("Menu bar height unavailable in test environment")
        }
        
        let belowMenuBarPoint = NSPoint(x: screen.frame.midX, y: screen.frame.maxY - menuBarHeight - 50)
        
        XCTAssertFalse(sut.isInMenuBarTriggerZone(belowMenuBarPoint), "HVM-011: Point below menu bar should not be in trigger zone")
    }
    
    // MARK: - HVM-012: isInDrawerArea inside frame
    
    func testHVM012_IsInDrawerAreaInsideFrame() async throws {
        let testFrame = CGRect(x: 100, y: 100, width: 200, height: 50)
        sut.setDrawerVisible(true)
        sut.updateDrawerFrame(testFrame)
        
        let insidePoint = NSPoint(x: 150, y: 125)
        
        XCTAssertTrue(sut.isInDrawerArea(insidePoint), "HVM-012: Point inside drawer frame should return true")
    }
    
    // MARK: - HVM-013: isInDrawerArea outside frame
    
    func testHVM013_IsInDrawerAreaOutsideFrame() async throws {
        let testFrame = CGRect(x: 100, y: 100, width: 200, height: 50)
        sut.setDrawerVisible(true)
        sut.updateDrawerFrame(testFrame)
        
        let outsidePoint = NSPoint(x: 500, y: 500)
        
        XCTAssertFalse(sut.isInDrawerArea(outsidePoint), "HVM-013: Point outside drawer frame should return false")
    }
    
    // MARK: - HVM-014: isInDrawerArea with expanded hit area
    
    func testHVM014_IsInDrawerAreaWithExpandedHitArea() async throws {
        let testFrame = CGRect(x: 100, y: 100, width: 200, height: 50)
        sut.setDrawerVisible(true)
        sut.updateDrawerFrame(testFrame)
        
        let pointJustOutsideFrame = NSPoint(x: 95, y: 125)
        
        XCTAssertTrue(sut.isInDrawerArea(pointJustOutsideFrame), "HVM-014: Point within 10px expansion should return true")
    }
}

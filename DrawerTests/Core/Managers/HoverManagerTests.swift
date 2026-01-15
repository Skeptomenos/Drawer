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
}

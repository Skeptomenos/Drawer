//
//  EventSimulatorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class EventSimulatorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: EventSimulator!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        sut = EventSimulator.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - EVS-001: hasAccessibilityPermission returns correct value
    
    func testEVS001_HasAccessibilityPermissionReturnsCorrectValue() {
        // Arrange
        let expectedValue = AXIsProcessTrusted()
        
        // Act
        let actualValue = sut.hasAccessibilityPermission
        
        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "EVS-001: hasAccessibilityPermission should match AXIsProcessTrusted()"
        )
    }
}

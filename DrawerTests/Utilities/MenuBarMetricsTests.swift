//
//  MenuBarMetricsTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class MenuBarMetricsTests: XCTestCase {
    
    // MARK: - MBR-001: fallbackHeight is 24
    
    func testMBR001_FallbackHeightIs24() {
        // Arrange & Act
        let fallbackHeight = MenuBarMetrics.fallbackHeight
        
        // Assert
        XCTAssertEqual(
            fallbackHeight,
            24,
            "MBR-001: fallbackHeight constant should be 24"
        )
    }
    
    // MARK: - MBR-002: height calculation
    
    func testMBR002_HeightCalculationFromScreen() {
        let height = MenuBarMetrics.height
        
        XCTAssertGreaterThan(
            height,
            0,
            "MBR-002: Menu bar height should be positive"
        )
        
        XCTAssertLessThanOrEqual(
            height,
            50,
            "MBR-002: Menu bar height should be within reasonable bounds (<=50pt)"
        )
        
        XCTAssertGreaterThanOrEqual(
            height,
            MenuBarMetrics.fallbackHeight,
            "MBR-002: Menu bar height should be at least the fallback height"
        )
        
        let heightSecondCall = MenuBarMetrics.height
        XCTAssertEqual(
            height,
            heightSecondCall,
            "MBR-002: Height calculation should be consistent across calls"
        )
    }
}

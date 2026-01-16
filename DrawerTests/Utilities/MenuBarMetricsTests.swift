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
}

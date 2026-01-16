//
//  PermissionTypeTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class PermissionTypeTests: XCTestCase {
    
    // MARK: - PRT-001: Accessibility displayName
    
    func testPRT001_AccessibilityDisplayName() {
        // Arrange
        let sut = PermissionType.accessibility
        
        // Act
        let displayName = sut.displayName
        
        // Assert
        XCTAssertEqual(
            displayName,
            "Accessibility",
            "PRT-001: Accessibility displayName should be 'Accessibility'"
        )
    }
    
    // MARK: - PRT-002: ScreenRecording displayName
    
    func testPRT002_ScreenRecordingDisplayName() {
        // Arrange
        let sut = PermissionType.screenRecording
        
        // Act
        let displayName = sut.displayName
        
        // Assert
        XCTAssertEqual(
            displayName,
            "Screen Recording",
            "PRT-002: ScreenRecording displayName should be 'Screen Recording'"
        )
    }
}

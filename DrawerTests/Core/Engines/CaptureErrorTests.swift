//
//  CaptureErrorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class CaptureErrorTests: XCTestCase {
    
    // MARK: - CAP-001: permissionDenied description
    
    func testCAP001_PermissionDeniedDescription() {
        // Arrange
        let error = CaptureError.permissionDenied
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-001: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Screen Recording permission is required to capture menu bar icons",
            "CAP-001: permissionDenied description should be correct"
        )
    }
    
    // MARK: - CAP-002: menuBarNotFound description
    
    func testCAP002_MenuBarNotFoundDescription() {
        // Arrange
        let error = CaptureError.menuBarNotFound
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-002: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Could not locate the menu bar window",
            "CAP-002: menuBarNotFound description should be correct"
        )
    }
    
    // MARK: - CAP-003: captureFailedNoImage description
    
    func testCAP003_CaptureFailedNoImageDescription() {
        // Arrange
        let error = CaptureError.captureFailedNoImage
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-003: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Screen capture returned no image",
            "CAP-003: captureFailedNoImage description should be correct"
        )
    }
    
    // MARK: - CAP-004: screenNotFound description
    
    func testCAP004_ScreenNotFoundDescription() {
        // Arrange
        let error = CaptureError.screenNotFound
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-004: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Could not find the main screen",
            "CAP-004: screenNotFound description should be correct"
        )
    }
    
    // MARK: - CAP-005: invalidRegion description
    
    func testCAP005_InvalidRegionDescription() {
        // Arrange
        let error = CaptureError.invalidRegion
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-005: Error description should not be nil")
        XCTAssertEqual(
            description,
            "The capture region is invalid",
            "CAP-005: invalidRegion description should be correct"
        )
    }
    
    // MARK: - CAP-006: noMenuBarItems description
    
    func testCAP006_NoMenuBarItemsDescription() {
        // Arrange
        let error = CaptureError.noMenuBarItems
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-006: Error description should not be nil")
        XCTAssertEqual(
            description,
            "No menu bar items found to capture",
            "CAP-006: noMenuBarItems description should be correct"
        )
    }
    
    // MARK: - CAP-007: systemError description includes wrapped error
    
    func testCAP007_SystemErrorDescriptionIncludesWrappedError() {
        // Arrange
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test underlying error message"]
        )
        let error = CaptureError.systemError(underlyingError)
        
        // Act
        let description = error.errorDescription
        
        // Assert
        XCTAssertNotNil(description, "CAP-007: Error description should not be nil")
        XCTAssertTrue(
            description?.contains("System error:") ?? false,
            "CAP-007: systemError description should start with 'System error:'"
        )
        XCTAssertTrue(
            description?.contains("Test underlying error message") ?? false,
            "CAP-007: systemError description should include the wrapped error's localized description"
        )
        XCTAssertEqual(
            description,
            "System error: Test underlying error message",
            "CAP-007: systemError description should be formatted correctly"
        )
        
        // Test with a different underlying error
        let anotherError = NSError(
            domain: "AnotherDomain",
            code: 99,
            userInfo: [NSLocalizedDescriptionKey: "Another error occurred"]
        )
        let anotherCaptureError = CaptureError.systemError(anotherError)
        XCTAssertEqual(
            anotherCaptureError.errorDescription,
            "System error: Another error occurred",
            "CAP-007: systemError should correctly wrap different underlying errors"
        )
    }
}

//
//  PermissionManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import XCTest

@testable import Drawer

@MainActor
final class PermissionManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: PermissionManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = PermissionManager.shared
        cancellables = []
    }
    
    override func tearDown() async throws {
        cancellables = nil
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - PRM-001: hasAccessibility returns correct value
    
    func testPRM001_HasAccessibilityReturnsCorrectValue() async throws {
        // Arrange
        let expectedValue = AXIsProcessTrusted()
        
        // Act
        let actualValue = sut.hasAccessibility
        
        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-001: hasAccessibility should match AXIsProcessTrusted()"
        )
    }
    
    // MARK: - PRM-002: hasScreenRecording returns correct value
    
    func testPRM002_HasScreenRecordingReturnsCorrectValue() async throws {
        // Arrange
        let expectedValue = CGPreflightScreenCaptureAccess()
        
        // Act
        let actualValue = sut.hasScreenRecording
        
        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-002: hasScreenRecording should match CGPreflightScreenCaptureAccess()"
        )
    }
    
    // MARK: - PRM-003: hasAllPermissions when both granted
    
    func testPRM003_HasAllPermissionsWhenBothGranted() async throws {
        // Arrange
        let hasAccessibility = AXIsProcessTrusted()
        let hasScreenRecording = CGPreflightScreenCaptureAccess()
        let expectedValue = hasAccessibility && hasScreenRecording
        
        // Act
        let actualValue = sut.hasAllPermissions
        
        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "PRM-003: hasAllPermissions should be true only when both permissions are granted"
        )
        
        // Additional verification: if both are granted, hasAllPermissions must be true
        if hasAccessibility && hasScreenRecording {
            XCTAssertTrue(
                actualValue,
                "PRM-003: hasAllPermissions should be true when both permissions are granted"
            )
        }
    }
    
    // MARK: - PRM-004: hasAllPermissions when one missing
    
    func testPRM004_HasAllPermissionsWhenOneMissing() async throws {
        // Arrange
        let hasAccessibility = AXIsProcessTrusted()
        let hasScreenRecording = CGPreflightScreenCaptureAccess()
        
        // Act
        let actualValue = sut.hasAllPermissions
        
        // Assert
        // Verify the logical AND behavior: if either permission is missing, hasAllPermissions must be false
        if !hasAccessibility || !hasScreenRecording {
            XCTAssertFalse(
                actualValue,
                "PRM-004: hasAllPermissions should be false when at least one permission is missing"
            )
        }
        
        // Verify the inverse relationship: hasAllPermissions == (hasAccessibility && hasScreenRecording)
        XCTAssertEqual(
            actualValue,
            hasAccessibility && hasScreenRecording,
            "PRM-004: hasAllPermissions should equal (hasAccessibility && hasScreenRecording)"
        )
        
        // Additional verification: if only one is granted, hasAllPermissions must be false
        if hasAccessibility != hasScreenRecording {
            XCTAssertFalse(
                actualValue,
                "PRM-004: hasAllPermissions should be false when permissions differ"
            )
        }
    }
}

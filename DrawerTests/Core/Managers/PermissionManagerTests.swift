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
}

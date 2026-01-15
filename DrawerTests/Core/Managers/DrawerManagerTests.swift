//
//  DrawerManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class DrawerManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: DrawerManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = DrawerManager()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - DRM-001: Initial items is empty
    
    func testDRM001_InitialItemsIsEmpty() async throws {
        // Arrange & Act - sut is already initialized in setUp
        
        // Assert
        XCTAssertTrue(sut.items.isEmpty, "DRM-001: Initial state items should be empty")
    }
    
    // MARK: - DRM-002: Initial isVisible is false
    
    func testDRM002_InitialIsVisibleIsFalse() async throws {
        // Arrange & Act - sut is already initialized in setUp
        
        // Assert
        XCTAssertFalse(sut.isVisible, "DRM-002: Initial state isVisible should be false")
    }
    
    // MARK: - DRM-003: Initial isLoading is false
    
    func testDRM003_InitialIsLoadingIsFalse() async throws {
        // Arrange & Act - sut is already initialized in setUp
        
        // Assert
        XCTAssertFalse(sut.isLoading, "DRM-003: Initial state isLoading should be false")
    }
    
    // MARK: - DRM-004: Initial lastError is nil
    
    func testDRM004_InitialLastErrorIsNil() async throws {
        // Arrange & Act - sut is already initialized in setUp
        
        // Assert
        XCTAssertNil(sut.lastError, "DRM-004: Initial state lastError should be nil")
    }
    
    // MARK: - DRM-005: updateItems from MenuBarCaptureResult
    
    func testDRM005_UpdateItemsFromMenuBarCaptureResult() async throws {
        // Arrange
        guard let mockResult = MockIconCapturer.createMockCaptureResult(iconCount: 3) else {
            XCTFail("DRM-005: Failed to create mock capture result")
            return
        }
        
        // Precondition
        XCTAssertTrue(sut.items.isEmpty, "DRM-005: Precondition - items should be empty before update")
        
        // Act
        sut.updateItems(from: mockResult)
        
        // Assert
        XCTAssertEqual(sut.items.count, 3, "DRM-005: Items should be updated from MenuBarCaptureResult")
        XCTAssertNil(sut.lastError, "DRM-005: lastError should be nil after successful update")
    }
}

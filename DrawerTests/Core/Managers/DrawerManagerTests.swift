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
    
    // MARK: - DRM-006: updateItems from [CapturedIcon] array
    
    func testDRM006_UpdateItemsFromCapturedIconArray() async throws {
        // Arrange
        let mockIcons = createMockCapturedIcons(count: 5)
        
        // Precondition
        XCTAssertTrue(sut.items.isEmpty, "DRM-006: Precondition - items should be empty before update")
        
        // Act
        sut.updateItems(from: mockIcons)
        
        // Assert
        XCTAssertEqual(sut.items.count, 5, "DRM-006: Items should be updated from [CapturedIcon] array")
        XCTAssertNil(sut.lastError, "DRM-006: lastError should be nil after successful update")
    }
    
    // MARK: - DRM-007: updateItems clears lastError
    
    func testDRM007_UpdateItemsClearsLastError() async throws {
        // Arrange - Set an error first
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        sut.setError(testError)
        
        // Precondition
        XCTAssertNotNil(sut.lastError, "DRM-007: Precondition - lastError should be set before update")
        
        // Act - Update items (should clear the error)
        let mockIcons = createMockCapturedIcons(count: 2)
        sut.updateItems(from: mockIcons)
        
        // Assert
        XCTAssertNil(sut.lastError, "DRM-007: updateItems should clear lastError")
    }
    
    // MARK: - DRM-008: clearItems removes all
    
    func testDRM008_ClearItemsRemovesAll() async throws {
        // Arrange - Add some items first
        let mockIcons = createMockCapturedIcons(count: 3)
        sut.updateItems(from: mockIcons)
        
        // Precondition
        XCTAssertEqual(sut.items.count, 3, "DRM-008: Precondition - items should have 3 items before clear")
        
        // Act
        sut.clearItems()
        
        // Assert
        XCTAssertTrue(sut.items.isEmpty, "DRM-008: clearItems() should empty the items array")
    }
    
    // MARK: - DRM-009: clearItems clears lastError
    
    func testDRM009_ClearItemsClearsLastError() async throws {
        // Arrange - Set an error first
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        sut.setError(testError)
        
        // Precondition
        XCTAssertNotNil(sut.lastError, "DRM-009: Precondition - lastError should be set before clearItems")
        
        // Act
        sut.clearItems()
        
        // Assert
        XCTAssertNil(sut.lastError, "DRM-009: clearItems() should set lastError to nil")
    }
    
    // MARK: - DRM-010: setLoading(true) sets isLoading true
    
    func testDRM010_SetLoadingTrueSetsIsLoadingTrue() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isLoading, "DRM-010: Precondition - isLoading should be false initially")
        
        // Act
        sut.setLoading(true)
        
        // Assert
        XCTAssertTrue(sut.isLoading, "DRM-010: setLoading(true) should set isLoading to true")
    }
    
    // MARK: - DRM-011: setLoading(false) sets isLoading false
    
    func testDRM011_SetLoadingFalseSetsIsLoadingFalse() async throws {
        // Arrange - Set loading to true first
        sut.setLoading(true)
        
        // Precondition
        XCTAssertTrue(sut.isLoading, "DRM-011: Precondition - isLoading should be true before setting to false")
        
        // Act
        sut.setLoading(false)
        
        // Assert
        XCTAssertFalse(sut.isLoading, "DRM-011: setLoading(false) should set isLoading to false")
    }
    
    // MARK: - DRM-012: setError stores error
    
    func testDRM012_SetErrorStoresError() async throws {
        // Arrange
        let testError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        
        // Precondition
        XCTAssertNil(sut.lastError, "DRM-012: Precondition - lastError should be nil initially")
        
        // Act
        sut.setError(testError)
        
        // Assert
        XCTAssertNotNil(sut.lastError, "DRM-012: setError should store the error")
        let storedError = sut.lastError as NSError?
        XCTAssertEqual(storedError?.domain, "TestDomain", "DRM-012: Stored error should have correct domain")
        XCTAssertEqual(storedError?.code, 42, "DRM-012: Stored error should have correct code")
    }
    
    // MARK: - DRM-013: setError(nil) clears error
    
    func testDRM013_SetErrorNilClearsError() async throws {
        // Arrange - Set an error first
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        sut.setError(testError)
        
        // Precondition
        XCTAssertNotNil(sut.lastError, "DRM-013: Precondition - lastError should be set before clearing")
        
        // Act
        sut.setError(nil)
        
        // Assert
        XCTAssertNil(sut.lastError, "DRM-013: setError(nil) should clear the error")
    }
    
    // MARK: - DRM-014: show() sets isVisible true
    
    func testDRM014_ShowSetsIsVisibleTrue() async throws {
        // Arrange & Precondition
        XCTAssertFalse(sut.isVisible, "DRM-014: Precondition - isVisible should be false initially")
        
        // Act
        sut.show()
        
        // Assert
        XCTAssertTrue(sut.isVisible, "DRM-014: show() should set isVisible to true")
    }
    
    // MARK: - Test Helpers
    
    private func createMockCapturedIcons(count: Int) -> [CapturedIcon] {
        var icons: [CapturedIcon] = []
        let iconWidth: CGFloat = 22
        let iconHeight: CGFloat = 24
        let spacing: CGFloat = 4
        
        for i in 0..<count {
            let x = CGFloat(i) * (iconWidth + spacing)
            let frame = CGRect(x: x, y: 0, width: iconWidth, height: iconHeight)
            
            if let image = MockIconCapturer.createMockImage(width: Int(iconWidth), height: Int(iconHeight)) {
                let icon = CapturedIcon(image: image, originalFrame: frame)
                icons.append(icon)
            }
        }
        
        return icons
    }
}

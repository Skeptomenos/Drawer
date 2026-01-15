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
}

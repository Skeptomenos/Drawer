//
//  MenuBarManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: MenuBarManager!
    private var mockSettings: MockSettingsManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockSettingsManager()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockSettings = nil
        try await super.tearDown()
    }
    
    // MARK: - MBM-001: Initial State Tests
    
    func testMBM001_InitialStateIsCollapsedIsTrue() async throws {
        sut = MenuBarManager(settings: SettingsManager.shared)
        
        XCTAssertTrue(sut.isCollapsed, "MBM-001: Initial state isCollapsed should be true")
    }
}

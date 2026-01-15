//
//  LaunchAtLoginManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class LaunchAtLoginManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: LaunchAtLoginManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = LaunchAtLoginManager.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - LAL-001: Initial lastError is nil
    
    func testLAL001_InitialLastErrorIsNil() async throws {
        XCTAssertNil(sut.lastError, "LAL-001: Initial state lastError should be nil")
    }
    
    // MARK: - LAL-002: refreshStatus updates isEnabled
    
    func testLAL002_RefreshStatusUpdatesIsEnabled() async throws {
        let initialState = sut.isEnabled
        
        sut.refreshStatus()
        
        let stateAfterRefresh = sut.isEnabled
        XCTAssertEqual(initialState, stateAfterRefresh,
                       "LAL-002: refreshStatus() should return consistent state when system state hasn't changed")
    }
}

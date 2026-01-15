//
//  HoverManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class HoverManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: HoverManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = HoverManager.shared
        sut.stopMonitoring()
    }
    
    override func tearDown() async throws {
        sut.stopMonitoring()
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - HVM-001: Initial isMonitoring is false
    
    func testHVM001_InitialIsMonitoringIsFalse() async throws {
        XCTAssertFalse(sut.isMonitoring, "HVM-001: Initial state isMonitoring should be false")
    }
}

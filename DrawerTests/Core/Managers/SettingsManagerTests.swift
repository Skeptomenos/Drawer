//
//  SettingsManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import Combine
import XCTest

@testable import Drawer

@MainActor
final class SettingsManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: SettingsManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = SettingsManager.shared
        cancellables = []
        
        // Reset to defaults before each test to ensure clean state
        sut.resetToDefaults()
    }
    
    override func tearDown() async throws {
        // Reset to defaults after each test
        sut.resetToDefaults()
        cancellables = nil
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - SET-001: Default autoCollapseEnabled is true
    
    func testSET001_DefaultAutoCollapseEnabledIsTrue() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertTrue(sut.autoCollapseEnabled, "SET-001: Default autoCollapseEnabled should be true")
    }
    
    // MARK: - SET-002: Default autoCollapseDelay is 10.0
    
    func testSET002_DefaultAutoCollapseDelayIsTen() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertEqual(sut.autoCollapseDelay, 10.0, accuracy: 0.001, "SET-002: Default autoCollapseDelay should be 10.0")
    }
    
    // MARK: - SET-003: Default launchAtLogin is false
    
    func testSET003_DefaultLaunchAtLoginIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertFalse(sut.launchAtLogin, "SET-003: Default launchAtLogin should be false")
    }
}

//
//  MockSettingsManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

@testable import Drawer

/// SETUP-004: Verify MockSettingsManager can be instantiated
final class MockSettingsManagerTests: XCTestCase {
    
    @MainActor
    func testSETUP004_MockSettingsManagerCanBeInstantiated() {
        let mock = MockSettingsManager()
        
        XCTAssertTrue(mock.autoCollapseEnabled)
        XCTAssertEqual(mock.autoCollapseDelay, 10.0)
        XCTAssertFalse(mock.launchAtLogin)
        XCTAssertFalse(mock.showOnHover)
        XCTAssertFalse(mock.hasCompletedOnboarding)
        XCTAssertNil(mock.globalHotkey)
    }
    
    @MainActor
    func testMockSettingsManagerResetToDefaults() {
        let mock = MockSettingsManager()
        
        mock.autoCollapseEnabled = false
        mock.autoCollapseDelay = 5.0
        mock.showOnHover = true
        
        mock.resetToDefaults()
        
        XCTAssertTrue(mock.resetToDefaultsCalled)
        XCTAssertEqual(mock.resetToDefaultsCallCount, 1)
        XCTAssertTrue(mock.autoCollapseEnabled)
        XCTAssertEqual(mock.autoCollapseDelay, 10.0)
        XCTAssertFalse(mock.showOnHover)
    }
}

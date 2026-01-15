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
    
    // MARK: - SET-004: Default hideSeparators is false
    
    func testSET004_DefaultHideSeparatorsIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertFalse(sut.hideSeparators, "SET-004: Default hideSeparators should be false")
    }
    
    // MARK: - SET-005: Default alwaysHiddenEnabled is false
    
    func testSET005_DefaultAlwaysHiddenEnabledIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertFalse(sut.alwaysHiddenEnabled, "SET-005: Default alwaysHiddenEnabled should be false")
    }
    
    // MARK: - SET-006: Default useFullStatusBarOnExpand is false
    
    func testSET006_DefaultUseFullStatusBarOnExpandIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertFalse(sut.useFullStatusBarOnExpand, "SET-006: Default useFullStatusBarOnExpand should be false")
    }
    
    // MARK: - SET-007: Default showOnHover is false
    
    func testSET007_DefaultShowOnHoverIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()
        
        // Assert
        XCTAssertFalse(sut.showOnHover, "SET-007: Default showOnHover should be false")
    }
    
    // MARK: - SET-008: Default hasCompletedOnboarding is false
    
    func testSET008_DefaultHasCompletedOnboardingIsFalse() async throws {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        XCTAssertFalse(sut.hasCompletedOnboarding, "SET-008: Default hasCompletedOnboarding should be false")
    }
    
    // MARK: - SET-009: resetToDefaults restores all settings
    
    func testSET009_ResetToDefaultsRestoresAllSettings() async throws {
        // Arrange - modify all settings to non-default values
        sut.autoCollapseEnabled = false
        sut.autoCollapseDelay = 30.0
        sut.launchAtLogin = true
        sut.hideSeparators = true
        sut.alwaysHiddenEnabled = true
        sut.useFullStatusBarOnExpand = true
        sut.showOnHover = true
        sut.globalHotkey = GlobalHotkeyConfig(
            keyCode: 49,
            carbonFlags: 0,
            characters: " ",
            function: false,
            control: false,
            command: true,
            shift: true,
            option: false,
            capsLock: false
        )
        
        // Verify settings were changed
        XCTAssertFalse(sut.autoCollapseEnabled)
        XCTAssertEqual(sut.autoCollapseDelay, 30.0, accuracy: 0.001)
        XCTAssertTrue(sut.hideSeparators)
        XCTAssertTrue(sut.alwaysHiddenEnabled)
        XCTAssertTrue(sut.useFullStatusBarOnExpand)
        XCTAssertTrue(sut.showOnHover)
        XCTAssertNotNil(sut.globalHotkey)
        
        // Act
        sut.resetToDefaults()
        
        // Assert - all settings should be restored to defaults
        XCTAssertTrue(sut.autoCollapseEnabled, "SET-009: autoCollapseEnabled should be reset to true")
        XCTAssertEqual(sut.autoCollapseDelay, 10.0, accuracy: 0.001, "SET-009: autoCollapseDelay should be reset to 10.0")
        XCTAssertFalse(sut.launchAtLogin, "SET-009: launchAtLogin should be reset to false")
        XCTAssertFalse(sut.hideSeparators, "SET-009: hideSeparators should be reset to false")
        XCTAssertFalse(sut.alwaysHiddenEnabled, "SET-009: alwaysHiddenEnabled should be reset to false")
        XCTAssertFalse(sut.useFullStatusBarOnExpand, "SET-009: useFullStatusBarOnExpand should be reset to false")
        XCTAssertFalse(sut.showOnHover, "SET-009: showOnHover should be reset to false")
        XCTAssertNil(sut.globalHotkey, "SET-009: globalHotkey should be reset to nil")
    }
    
    // MARK: - SET-010: autoCollapseEnabled subject fires on change
    
    func testSET010_AutoCollapseEnabledSubjectFiresOnChange() async throws {
        // Arrange
        var receivedValues: [Bool] = []
        let expectation = XCTestExpectation(description: "Subject should fire on change")
        
        sut.autoCollapseEnabledSubject
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - change the value
        sut.autoCollapseEnabled = false
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 1, "SET-010: Subject should fire exactly once")
        XCTAssertFalse(receivedValues.first ?? true, "SET-010: Subject should emit the new value (false)")
    }
    
    // MARK: - SET-011: autoCollapseDelay subject fires on change
    
    func testSET011_AutoCollapseDelaySubjectFiresOnChange() async throws {
        // Arrange
        var receivedValues: [Double] = []
        let expectation = XCTestExpectation(description: "Subject should fire on change")
        
        sut.autoCollapseDelaySubject
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - change the value
        sut.autoCollapseDelay = 20.0
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 1, "SET-011: Subject should fire exactly once")
        XCTAssertEqual(receivedValues.first ?? 0.0, 20.0, accuracy: 0.001, "SET-011: Subject should emit the new value (20.0)")
    }
    
    // MARK: - SET-012: showOnHover subject fires on change
    
    func testSET012_ShowOnHoverSubjectFiresOnChange() async throws {
        // Arrange
        var receivedValues: [Bool] = []
        let expectation = XCTestExpectation(description: "Subject should fire on change")
        
        sut.showOnHoverSubject
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - change the value
        sut.showOnHover = true
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.count, 1, "SET-012: Subject should fire exactly once")
        XCTAssertTrue(receivedValues.first ?? false, "SET-012: Subject should emit the new value (true)")
    }
    
    // MARK: - SET-013: autoCollapseSettingsChanged publisher fires
    
    func testSET013_AutoCollapseSettingsChangedPublisherFires() async throws {
        // Arrange
        var fireCount = 0
        let expectation = XCTestExpectation(description: "Combined publisher should fire on either setting change")
        expectation.expectedFulfillmentCount = 2
        
        sut.autoCollapseSettingsChanged
            .sink { _ in
                fireCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - change autoCollapseEnabled
        sut.autoCollapseEnabled = false
        
        // Act - change autoCollapseDelay
        sut.autoCollapseDelay = 15.0
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(fireCount, 2, "SET-013: Combined publisher should fire twice (once for each setting change)")
    }
    
    // MARK: - SET-014: globalHotkey get/set roundtrip
    
    func testSET014_GlobalHotkeyGetSetRoundtrip() async throws {
        // Arrange - create a hotkey config
        let config = GlobalHotkeyConfig(
            keyCode: 49,           // Space key
            carbonFlags: 256,      // Command modifier
            characters: " ",
            function: false,
            control: false,
            command: true,
            shift: false,
            option: false,
            capsLock: false
        )
        
        // Act - set the hotkey
        sut.globalHotkey = config
        
        // Assert - retrieve and verify roundtrip
        let retrieved = sut.globalHotkey
        XCTAssertNotNil(retrieved, "SET-014: globalHotkey should be retrievable after set")
        XCTAssertEqual(retrieved?.keyCode, config.keyCode, "SET-014: keyCode should match")
        XCTAssertEqual(retrieved?.carbonFlags, config.carbonFlags, "SET-014: carbonFlags should match")
        XCTAssertEqual(retrieved?.characters, config.characters, "SET-014: characters should match")
        XCTAssertEqual(retrieved?.function, config.function, "SET-014: function should match")
        XCTAssertEqual(retrieved?.control, config.control, "SET-014: control should match")
        XCTAssertEqual(retrieved?.command, config.command, "SET-014: command should match")
        XCTAssertEqual(retrieved?.shift, config.shift, "SET-014: shift should match")
        XCTAssertEqual(retrieved?.option, config.option, "SET-014: option should match")
        XCTAssertEqual(retrieved?.capsLock, config.capsLock, "SET-014: capsLock should match")
        XCTAssertEqual(retrieved, config, "SET-014: Full config should be equal via Equatable")
    }
}

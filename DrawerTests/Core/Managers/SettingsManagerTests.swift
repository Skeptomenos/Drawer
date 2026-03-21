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

    // MARK: - SET-005: Default alwaysHiddenSectionEnabled is false

    func testSET005_DefaultAlwaysHiddenEnabledIsFalse() async throws {
        // Arrange - reset to defaults to ensure we're testing default values
        sut.resetToDefaults()

        // Assert
        XCTAssertFalse(sut.alwaysHiddenSectionEnabled, "SET-005: Default alwaysHiddenSectionEnabled should be false")
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
        sut.alwaysHiddenSectionEnabled = true
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
        XCTAssertTrue(sut.alwaysHiddenSectionEnabled)
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
        XCTAssertFalse(sut.alwaysHiddenSectionEnabled, "SET-009: alwaysHiddenSectionEnabled should be reset to false")
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

    // MARK: - SET-015: globalHotkey set nil removes from defaults

    func testSET015_GlobalHotkeySetNilRemovesFromDefaults() async throws {
        // Arrange - first set a hotkey config
        let config = GlobalHotkeyConfig(
            keyCode: 36,           // Return key
            carbonFlags: 256,      // Command modifier
            characters: nil,
            function: false,
            control: false,
            command: true,
            shift: false,
            option: false,
            capsLock: false
        )
        sut.globalHotkey = config

        // Verify the hotkey was set
        XCTAssertNotNil(sut.globalHotkey, "SET-015: globalHotkey should be set before test")
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "globalHotkey"), "SET-015: UserDefaults should contain globalHotkey data")

        // Act - set globalHotkey to nil
        sut.globalHotkey = nil

        // Assert - globalHotkey should be nil and removed from UserDefaults
        XCTAssertNil(sut.globalHotkey, "SET-015: globalHotkey should be nil after setting to nil")
        XCTAssertNil(UserDefaults.standard.data(forKey: "globalHotkey"), "SET-015: UserDefaults should not contain globalHotkey key after setting to nil")
    }

    // MARK: - SET-016: menuBarLayout default is empty

    func testSET016_MenuBarLayoutDefaultIsEmpty() async throws {
        // Arrange - clear any existing layout
        sut.clearMenuBarLayout()

        // Assert
        XCTAssertTrue(sut.menuBarLayout.isEmpty, "SET-016: Default menuBarLayout should be empty")
    }

    // MARK: - SET-017: menuBarLayout save and retrieve roundtrip

    func testSET017_MenuBarLayoutSaveAndRetrieveRoundtrip() async throws {
        // Arrange - create layout items
        let items = [
            SettingsLayoutItem(bundleIdentifier: "com.apple.controlcenter", title: "WiFi", section: .visible, order: 0),
            SettingsLayoutItem(bundleIdentifier: "com.1password.1password", title: nil, section: .hidden, order: 1),
            SettingsLayoutItem.spacer(section: .hidden, order: 2)
        ]

        // Act - save layout
        sut.saveMenuBarLayout(items)

        // Assert - retrieve and verify
        let retrieved = sut.menuBarLayout
        XCTAssertEqual(retrieved.count, 3, "SET-017: Should retrieve 3 items")

        // Verify first item
        XCTAssertEqual(retrieved[0].bundleIdentifier, "com.apple.controlcenter")
        XCTAssertEqual(retrieved[0].title, "WiFi")
        XCTAssertEqual(retrieved[0].section, .visible)
        XCTAssertEqual(retrieved[0].order, 0)

        // Verify second item
        XCTAssertEqual(retrieved[1].bundleIdentifier, "com.1password.1password")
        XCTAssertNil(retrieved[1].title)
        XCTAssertEqual(retrieved[1].section, .hidden)
        XCTAssertEqual(retrieved[1].order, 1)

        // Verify third item is a spacer
        XCTAssertTrue(retrieved[2].isSpacer, "SET-017: Third item should be a spacer")
        XCTAssertEqual(retrieved[2].section, .hidden)

        // Cleanup
        sut.clearMenuBarLayout()
    }

    // MARK: - SET-018: clearMenuBarLayout removes layout

    func testSET018_ClearMenuBarLayoutRemovesLayout() async throws {
        // Arrange - save some items first
        let items = [
            SettingsLayoutItem(bundleIdentifier: "com.test.app", title: nil, section: .visible, order: 0)
        ]
        sut.saveMenuBarLayout(items)
        XCTAssertFalse(sut.menuBarLayout.isEmpty, "SET-018: Layout should not be empty before clear")

        // Act
        sut.clearMenuBarLayout()

        // Assert
        XCTAssertTrue(sut.menuBarLayout.isEmpty, "SET-018: Layout should be empty after clear")
    }

    // MARK: - SET-019: menuBarLayoutChangedSubject fires on save

    func testSET019_MenuBarLayoutChangedSubjectFiresOnSave() async throws {
        // Arrange
        var receivedLayouts: [[SettingsLayoutItem]] = []
        let expectation = XCTestExpectation(description: "Subject should fire on save")

        sut.menuBarLayoutChangedSubject
            .sink { layout in
                receivedLayouts.append(layout)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        let items = [
            SettingsLayoutItem(bundleIdentifier: "com.test.app", title: nil, section: .hidden, order: 0)
        ]
        sut.saveMenuBarLayout(items)

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedLayouts.count, 1, "SET-019: Subject should fire once")
        XCTAssertEqual(receivedLayouts.first?.count, 1, "SET-019: Should receive the saved layout")

        // Cleanup
        sut.clearMenuBarLayout()
    }

    // MARK: - SET-020: menuBarLayout persists with all section types

    func testSET020_MenuBarLayoutPersistsAllSectionTypes() async throws {
        // Arrange - create items in all section types
        let items = [
            SettingsLayoutItem(bundleIdentifier: "com.visible.app", title: nil, section: .visible, order: 0),
            SettingsLayoutItem(bundleIdentifier: "com.hidden.app", title: nil, section: .hidden, order: 0),
            SettingsLayoutItem(bundleIdentifier: "com.always.app", title: nil, section: .alwaysHidden, order: 0)
        ]

        // Act
        sut.saveMenuBarLayout(items)

        // Assert
        let retrieved = sut.menuBarLayout
        let visibleItems = retrieved.filter { $0.section == .visible }
        let hiddenItems = retrieved.filter { $0.section == .hidden }
        let alwaysHiddenItems = retrieved.filter { $0.section == .alwaysHidden }

        XCTAssertEqual(visibleItems.count, 1, "SET-020: Should have 1 visible item")
        XCTAssertEqual(hiddenItems.count, 1, "SET-020: Should have 1 hidden item")
        XCTAssertEqual(alwaysHiddenItems.count, 1, "SET-020: Should have 1 always-hidden item")

        // Cleanup
        sut.clearMenuBarLayout()
    }

    // MARK: - SET-021: savedIconPositions save and load roundtrip

    func testSET021_SaveAndLoadIconPositionsRoundtrip() async throws {
        // Arrange - clear any existing positions
        sut.clearSavedPositions()
        XCTAssertTrue(sut.savedIconPositions.isEmpty, "SET-021: Should start with empty positions")

        // Create test icon identifiers
        let visibleIcons = [
            IconIdentifier(namespace: "com.apple.controlcenter", title: "WiFi"),
            IconIdentifier(namespace: "com.1password.1password", title: "1Password")
        ]
        let hiddenIcons = [
            IconIdentifier(namespace: "com.spotify.client", title: "Spotify"),
            IconIdentifier(namespace: "com.slack.Slack", title: "Slack")
        ]
        let alwaysHiddenIcons = [
            IconIdentifier(namespace: "com.adobe.acc.AdobeCreativeCloud", title: "Creative Cloud")
        ]

        // Act - save positions for each section
        sut.updateSavedPositions(for: .visible, icons: visibleIcons)
        sut.updateSavedPositions(for: .hidden, icons: hiddenIcons)
        sut.updateSavedPositions(for: .alwaysHidden, icons: alwaysHiddenIcons)

        // Assert - retrieve and verify roundtrip
        let retrieved = sut.loadIconPositions()

        // Verify visible section
        XCTAssertEqual(retrieved[MenuBarSectionType.visible.rawValue]?.count, 2, "SET-021: Should have 2 visible icons")
        XCTAssertEqual(retrieved[MenuBarSectionType.visible.rawValue]?[0].namespace, "com.apple.controlcenter")
        XCTAssertEqual(retrieved[MenuBarSectionType.visible.rawValue]?[0].title, "WiFi")
        XCTAssertEqual(retrieved[MenuBarSectionType.visible.rawValue]?[1].namespace, "com.1password.1password")

        // Verify hidden section
        XCTAssertEqual(retrieved[MenuBarSectionType.hidden.rawValue]?.count, 2, "SET-021: Should have 2 hidden icons")
        XCTAssertEqual(retrieved[MenuBarSectionType.hidden.rawValue]?[0].namespace, "com.spotify.client")

        // Verify always-hidden section
        XCTAssertEqual(retrieved[MenuBarSectionType.alwaysHidden.rawValue]?.count, 1, "SET-021: Should have 1 always-hidden icon")
        XCTAssertEqual(retrieved[MenuBarSectionType.alwaysHidden.rawValue]?[0].namespace, "com.adobe.acc.AdobeCreativeCloud")

        // Verify data is actually in UserDefaults
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "menuBarIconPositions"), "SET-021: UserDefaults should contain icon positions data")

        // Cleanup
        sut.clearSavedPositions()
    }

    // MARK: - SET-022: clearSavedPositions removes all positions

    func testSET022_ClearSavedPositionsRemovesAllPositions() async throws {
        // Arrange - save some positions first
        let icons = [
            IconIdentifier(namespace: "com.test.app", title: "TestIcon")
        ]
        sut.updateSavedPositions(for: .visible, icons: icons)
        sut.updateSavedPositions(for: .hidden, icons: icons)
        XCTAssertFalse(sut.savedIconPositions.isEmpty, "SET-022: Positions should not be empty before clear")
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "menuBarIconPositions"), "SET-022: UserDefaults should contain data before clear")

        // Act
        sut.clearSavedPositions()

        // Assert
        XCTAssertTrue(sut.savedIconPositions.isEmpty, "SET-022: Positions should be empty after clear")
        XCTAssertNil(UserDefaults.standard.data(forKey: "menuBarIconPositions"), "SET-022: UserDefaults should not contain data after clear")
    }

    // MARK: - SET-023: iconPositionsChangedSubject fires on save

    func testSET023_IconPositionsChangedSubjectFiresOnSave() async throws {
        // Arrange - clear any existing positions
        sut.clearSavedPositions()

        var receivedPositions: [[String: [IconIdentifier]]] = []
        let expectation = XCTestExpectation(description: "Subject should fire on save")

        sut.iconPositionsChangedSubject
            .sink { positions in
                receivedPositions.append(positions)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act - save positions
        let icons = [
            IconIdentifier(namespace: "com.test.app", title: "TestIcon")
        ]
        sut.updateSavedPositions(for: .hidden, icons: icons)

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedPositions.count, 1, "SET-023: Subject should fire once")
        XCTAssertEqual(receivedPositions.first?[MenuBarSectionType.hidden.rawValue]?.count, 1, "SET-023: Should receive saved positions")

        // Cleanup
        sut.clearSavedPositions()
    }

    // MARK: - SET-024: savedIconPositions default is empty

    func testSET024_SavedIconPositionsDefaultIsEmpty() async throws {
        // Arrange - clear any existing positions
        sut.clearSavedPositions()

        // Assert
        XCTAssertTrue(sut.savedIconPositions.isEmpty, "SET-024: Default savedIconPositions should be empty")
        XCTAssertTrue(sut.loadIconPositions().isEmpty, "SET-024: loadIconPositions() should return empty dictionary")
    }
}

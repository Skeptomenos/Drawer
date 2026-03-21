//
//  SettingsLayoutItemTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

/// Tests for SettingsLayoutItem model used in Settings "Menu Bar Layout" view.
///
/// Test naming convention: test[ID]_[Scenario]
/// - SLI-001 to SLI-010: Basic initialization and properties
/// - SLI-011 to SLI-020: Codable conformance
/// - SLI-021 to SLI-030: Section and ordering
/// - SLI-031 to SLI-040: Matching logic
final class SettingsLayoutItemTests: XCTestCase {

    // MARK: - SLI-001 to SLI-010: Basic Initialization

    func testSLI001_MenuBarItemInitialization() {
        // Given
        let bundleId = "com.apple.controlcenter"
        let title = "Bluetooth"

        // When
        let item = SettingsLayoutItem(
            bundleIdentifier: bundleId,
            title: title,
            section: .hidden,
            order: 5
        )

        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.bundleIdentifier, bundleId)
        XCTAssertEqual(item.title, title)
        XCTAssertEqual(item.section, .hidden)
        XCTAssertEqual(item.order, 5)
        XCTAssertFalse(item.isSpacer)
    }

    func testSLI002_SpacerCreation() {
        // When
        let spacer = SettingsLayoutItem.spacer(section: .hidden, order: 3)

        // Then
        XCTAssertNotNil(spacer.id)
        XCTAssertTrue(spacer.isSpacer)
        XCTAssertNil(spacer.bundleIdentifier)
        XCTAssertNil(spacer.title)
        XCTAssertEqual(spacer.section, .hidden)
        XCTAssertEqual(spacer.order, 3)
    }

    func testSLI003_MenuBarItemWithoutTitle() {
        // When
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.example.app",
            section: .visible
        )

        // Then
        XCTAssertEqual(item.bundleIdentifier, "com.example.app")
        XCTAssertNil(item.title)
        XCTAssertEqual(item.section, .visible)
        XCTAssertEqual(item.order, 0)
    }

    func testSLI004_DisplayNameForSpacer() {
        // Given
        let spacer = SettingsLayoutItem.spacer(section: .hidden)

        // Then
        XCTAssertEqual(spacer.displayName, "Spacer")
    }

    func testSLI005_DisplayNameForUnknownBundleId() {
        // Given - a bundle ID that doesn't exist on the system
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.nonexistent.app.xyz123",
            title: "Window",
            section: .hidden
        )

        // Then - falls back to bundle ID with title
        XCTAssertEqual(item.displayName, "com.nonexistent.app.xyz123 - Window")
    }

    func testSLI006_DisplayNameForUnknownBundleIdWithoutTitle() {
        // Given
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.nonexistent.app.xyz123",
            section: .hidden
        )

        // Then - falls back to just bundle ID
        XCTAssertEqual(item.displayName, "com.nonexistent.app.xyz123")
    }

    func testSLI007_ItemTypeInitWithMenuBarItem() {
        // When
        let itemType = SettingsLayoutItemType.menuBarItem(
            bundleIdentifier: "com.test.app",
            title: "Test"
        )
        let item = SettingsLayoutItem(
            itemType: itemType,
            section: .alwaysHidden,
            order: 10
        )

        // Then
        XCTAssertFalse(item.isSpacer)
        XCTAssertEqual(item.bundleIdentifier, "com.test.app")
        XCTAssertEqual(item.title, "Test")
    }

    func testSLI008_ItemTypeInitWithSpacer() {
        // When
        let spacerId = UUID()
        let itemType = SettingsLayoutItemType.spacer(id: spacerId)
        let item = SettingsLayoutItem(
            itemType: itemType,
            section: .hidden
        )

        // Then
        XCTAssertTrue(item.isSpacer)
        XCTAssertNil(item.bundleIdentifier)
    }

    func testSLI009_AllSectionTypesSupported() {
        // Given
        let sections: [MenuBarSectionType] = [.visible, .hidden, .alwaysHidden]

        // When/Then
        for section in sections {
            let item = SettingsLayoutItem(
                bundleIdentifier: "com.test.app",
                section: section
            )
            XCTAssertEqual(item.section, section)
        }
    }

    func testSLI010_UniqueIdsPerInstance() {
        // When
        let item1 = SettingsLayoutItem(bundleIdentifier: "com.test.app", section: .hidden)
        let item2 = SettingsLayoutItem(bundleIdentifier: "com.test.app", section: .hidden)

        // Then
        XCTAssertNotEqual(item1.id, item2.id)
    }

    // MARK: - SLI-011 to SLI-020: Codable Conformance

    func testSLI011_MenuBarItemEncodeDecode() throws {
        // Given
        let original = SettingsLayoutItem(
            bundleIdentifier: "com.apple.Safari",
            title: "Downloads",
            section: .hidden,
            order: 5
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SettingsLayoutItem.self, from: data)

        // Then
        XCTAssertEqual(decoded.bundleIdentifier, original.bundleIdentifier)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.section, original.section)
        XCTAssertEqual(decoded.order, original.order)
    }

    func testSLI012_SpacerEncodeDecode() throws {
        // Given
        let original = SettingsLayoutItem.spacer(section: .alwaysHidden, order: 2)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SettingsLayoutItem.self, from: data)

        // Then
        XCTAssertTrue(decoded.isSpacer)
        XCTAssertEqual(decoded.section, .alwaysHidden)
        XCTAssertEqual(decoded.order, 2)
    }

    func testSLI013_MenuBarItemTypeEncodeDecode() throws {
        // Given
        let original = SettingsLayoutItemType.menuBarItem(
            bundleIdentifier: "com.test.app",
            title: "Window"
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SettingsLayoutItemType.self, from: data)

        // Then
        if case .menuBarItem(let bundleId, let title) = decoded {
            XCTAssertEqual(bundleId, "com.test.app")
            XCTAssertEqual(title, "Window")
        } else {
            XCTFail("Expected menuBarItem type")
        }
    }

    func testSLI014_SpacerTypeEncodeDecode() throws {
        // Given
        let spacerId = UUID()
        let original = SettingsLayoutItemType.spacer(id: spacerId)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SettingsLayoutItemType.self, from: data)

        // Then
        if case .spacer(let decodedId) = decoded {
            XCTAssertEqual(decodedId, spacerId)
        } else {
            XCTFail("Expected spacer type")
        }
    }

    func testSLI015_MenuBarItemWithNilTitleEncodeDecode() throws {
        // Given
        let original = SettingsLayoutItem(
            bundleIdentifier: "com.apple.Music",
            section: .visible
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SettingsLayoutItem.self, from: data)

        // Then
        XCTAssertEqual(decoded.bundleIdentifier, "com.apple.Music")
        XCTAssertNil(decoded.title)
    }

    func testSLI016_ArrayOfItemsEncodeDecode() throws {
        // Given
        let items: [SettingsLayoutItem] = [
            SettingsLayoutItem(bundleIdentifier: "com.app1", section: .visible, order: 0),
            SettingsLayoutItem.spacer(section: .hidden, order: 1),
            SettingsLayoutItem(bundleIdentifier: "com.app2", title: "Window", section: .hidden, order: 2)
        ]

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([SettingsLayoutItem].self, from: data)

        // Then
        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0].bundleIdentifier, "com.app1")
        XCTAssertTrue(decoded[1].isSpacer)
        XCTAssertEqual(decoded[2].title, "Window")
    }

    // MARK: - SLI-021 to SLI-030: Equatable and Hashable

    func testSLI021_MenuBarItemTypeEquality() {
        // Given
        let type1 = SettingsLayoutItemType.menuBarItem(bundleIdentifier: "com.test", title: "A")
        let type2 = SettingsLayoutItemType.menuBarItem(bundleIdentifier: "com.test", title: "A")
        let type3 = SettingsLayoutItemType.menuBarItem(bundleIdentifier: "com.test", title: "B")

        // Then
        XCTAssertEqual(type1, type2)
        XCTAssertNotEqual(type1, type3)
    }

    func testSLI022_SpacerTypeEquality() {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let spacer1 = SettingsLayoutItemType.spacer(id: id1)
        let spacer2 = SettingsLayoutItemType.spacer(id: id1)
        let spacer3 = SettingsLayoutItemType.spacer(id: id2)

        // Then
        XCTAssertEqual(spacer1, spacer2)
        XCTAssertNotEqual(spacer1, spacer3)
    }

    func testSLI023_DifferentTypesNotEqual() {
        // Given
        let menuBarItem = SettingsLayoutItemType.menuBarItem(bundleIdentifier: "com.test", title: nil)
        let spacer = SettingsLayoutItemType.spacer(id: UUID())

        // Then
        XCTAssertNotEqual(menuBarItem, spacer)
    }

    func testSLI024_ItemHashableInSet() {
        // Given
        let item1 = SettingsLayoutItem(bundleIdentifier: "com.app1", section: .hidden)
        let item2 = SettingsLayoutItem(bundleIdentifier: "com.app2", section: .hidden)

        // When
        var itemSet: Set<SettingsLayoutItem> = []
        itemSet.insert(item1)
        itemSet.insert(item2)

        // Then
        XCTAssertEqual(itemSet.count, 2)
    }

    func testSLI025_ItemTypeHashableInSet() {
        // Given
        let type1 = SettingsLayoutItemType.menuBarItem(bundleIdentifier: "com.app", title: nil)
        let type2 = SettingsLayoutItemType.spacer(id: UUID())

        // When
        var typeSet: Set<SettingsLayoutItemType> = []
        typeSet.insert(type1)
        typeSet.insert(type2)

        // Then
        XCTAssertEqual(typeSet.count, 2)
    }

    // MARK: - SLI-031 to SLI-040: Section Assignment

    func testSLI031_MutableSection() {
        // Given
        var item = SettingsLayoutItem(bundleIdentifier: "com.test", section: .hidden)

        // When
        item.section = .alwaysHidden

        // Then
        XCTAssertEqual(item.section, .alwaysHidden)
    }

    func testSLI032_MutableOrder() {
        // Given
        var item = SettingsLayoutItem(bundleIdentifier: "com.test", section: .hidden, order: 0)

        // When
        item.order = 10

        // Then
        XCTAssertEqual(item.order, 10)
    }

    func testSLI033_DefaultOrderIsZero() {
        // When
        let item = SettingsLayoutItem(bundleIdentifier: "com.test", section: .hidden)

        // Then
        XCTAssertEqual(item.order, 0)
    }

    // MARK: - SLI-041 to SLI-050: Immovable Items (Phase 5.4)

    func testSLI041_ControlCenterBentoBoxIsImmovable() {
        // Given - Control Center's BentoBox is a system item that cannot be moved
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.controlcenter",
            title: "BentoBox",
            section: .visible
        )

        // Then
        XCTAssertTrue(item.isImmovable)
    }

    func testSLI042_ControlCenterClockIsImmovable() {
        // Given - Control Center's Clock is a system item that cannot be moved
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.controlcenter",
            title: "Clock",
            section: .visible
        )

        // Then
        XCTAssertTrue(item.isImmovable)
    }

    func testSLI043_SiriIsImmovable() {
        // Given - Siri is a system item that cannot be moved
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.Siri",
            title: "Siri",
            section: .visible
        )

        // Then
        XCTAssertTrue(item.isImmovable)
    }

    func testSLI044_SpotlightIsImmovable() {
        // Given - Spotlight is a system item that cannot be moved
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.Spotlight",
            title: "Spotlight",
            section: .visible
        )

        // Then
        XCTAssertTrue(item.isImmovable)
    }

    func testSLI045_RegularAppIsMovable() {
        // Given - A regular third-party app should be movable
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.example.app",
            title: "StatusItem",
            section: .hidden
        )

        // Then
        XCTAssertFalse(item.isImmovable)
    }

    func testSLI046_ControlCenterOtherItemIsMovable() {
        // Given - Other Control Center items (like WiFi, Bluetooth) are movable
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.controlcenter",
            title: "WiFi",
            section: .hidden
        )

        // Then
        XCTAssertFalse(item.isImmovable)
    }

    func testSLI047_SpacerIsAlwaysMovable() {
        // Given - Spacers are user-created and should always be movable
        let spacer = SettingsLayoutItem.spacer(section: .hidden)

        // Then
        XCTAssertFalse(spacer.isImmovable)
    }

    func testSLI048_ItemWithNilTitleIsMovable() {
        // Given - Items without a title should be treated as movable
        // (immovable items require an exact namespace+title match)
        let item = SettingsLayoutItem(
            bundleIdentifier: "com.apple.controlcenter",
            section: .hidden
        )

        // Then - nil title doesn't match "BentoBox" or "Clock"
        XCTAssertFalse(item.isImmovable)
    }
}

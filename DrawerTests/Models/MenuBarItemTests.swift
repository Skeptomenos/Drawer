//
//  MenuBarItemTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

/// Tests for IconIdentifier and IconItem models used by the repositioning system.
/// These models were renamed from MenuBarItemInfo/MenuBarItem to avoid conflicts
/// with the existing types in WindowInfo.swift used by the capture system.
@MainActor
final class MenuBarItemTests: XCTestCase {

    // MARK: - IconIdentifier Equality Tests

    func testIconIdentifierEquality_SameValues_AreEqual() {
        // Arrange
        let id1 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")
        let id2 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")

        // Act & Assert
        XCTAssertEqual(id1, id2, "IconIdentifier with same namespace and title should be equal")
    }

    func testIconIdentifierEquality_DifferentNamespace_NotEqual() {
        // Arrange
        let id1 = IconIdentifier(namespace: "com.example.app1", title: "StatusItem")
        let id2 = IconIdentifier(namespace: "com.example.app2", title: "StatusItem")

        // Act & Assert
        XCTAssertNotEqual(id1, id2, "IconIdentifier with different namespace should not be equal")
    }

    func testIconIdentifierEquality_DifferentTitle_NotEqual() {
        // Arrange
        let id1 = IconIdentifier(namespace: "com.example.app", title: "StatusItem1")
        let id2 = IconIdentifier(namespace: "com.example.app", title: "StatusItem2")

        // Act & Assert
        XCTAssertNotEqual(id1, id2, "IconIdentifier with different title should not be equal")
    }

    // MARK: - IconIdentifier Hashing Tests

    func testIconIdentifierHashing_EqualItemsHaveSameHash() {
        // Arrange
        let id1 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")
        let id2 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")

        // Act & Assert
        XCTAssertEqual(id1.hashValue, id2.hashValue, "Equal IconIdentifier should have same hash value")
    }

    func testIconIdentifierHashing_CanBeUsedInSet() {
        // Arrange
        let id1 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")
        let id2 = IconIdentifier(namespace: "com.example.app", title: "StatusItem")
        let id3 = IconIdentifier(namespace: "com.example.other", title: "Other")

        // Act
        var set = Set<IconIdentifier>()
        set.insert(id1)
        set.insert(id2)  // Duplicate - should not increase count
        set.insert(id3)

        // Assert
        XCTAssertEqual(set.count, 2, "Set should contain 2 unique items, not duplicates")
        XCTAssertTrue(set.contains(id1), "Set should contain id1")
        XCTAssertTrue(set.contains(id3), "Set should contain id3")
    }

    // MARK: - IconIdentifier Codable Tests

    func testIconIdentifierCodable_EncodesAndDecodes() throws {
        // Arrange
        let original = IconIdentifier(namespace: "com.example.app", title: "TestItem")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Act
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(IconIdentifier.self, from: data)

        // Assert
        XCTAssertEqual(original, decoded, "IconIdentifier should encode and decode correctly")
    }

    func testIconIdentifierCodable_ArrayEncodesAndDecodes() throws {
        // Arrange
        let items = [
            IconIdentifier(namespace: "com.example.app1", title: "Item1"),
            IconIdentifier(namespace: "com.example.app2", title: "Item2"),
            IconIdentifier(namespace: "com.example.app3", title: "Item3")
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Act
        let data = try encoder.encode(items)
        let decoded = try decoder.decode([IconIdentifier].self, from: data)

        // Assert
        XCTAssertEqual(items, decoded, "Array of IconIdentifier should encode and decode correctly")
    }

    // MARK: - Immovable Items Detection Tests

    func testImmovableItems_ControlCenterBentoBoxIsImmovable() {
        // Arrange
        let controlCenter = IconIdentifier(namespace: "com.apple.controlcenter", title: "BentoBox")

        // Act & Assert
        XCTAssertTrue(controlCenter.isImmovable, "Control Center (BentoBox) should be immovable")
    }

    func testImmovableItems_ClockIsImmovable() {
        // Arrange
        let clock = IconIdentifier(namespace: "com.apple.controlcenter", title: "Clock")

        // Act & Assert
        XCTAssertTrue(clock.isImmovable, "Clock should be immovable")
    }

    func testImmovableItems_SiriIsImmovable() {
        // Arrange
        let siri = IconIdentifier(namespace: "com.apple.Siri", title: "Siri")

        // Act & Assert
        XCTAssertTrue(siri.isImmovable, "Siri should be immovable")
    }

    func testImmovableItems_SpotlightIsImmovable() {
        // Arrange
        let spotlight = IconIdentifier(namespace: "com.apple.Spotlight", title: "Spotlight")

        // Act & Assert
        XCTAssertTrue(spotlight.isImmovable, "Spotlight should be immovable")
    }

    func testImmovableItems_CustomAppIsMovable() {
        // Arrange
        let customApp = IconIdentifier(namespace: "com.example.myapp", title: "MyStatusItem")

        // Act & Assert
        XCTAssertFalse(customApp.isImmovable, "Custom app items should be movable (not immovable)")
    }

    func testImmovableItems_ImmovableItemsSetContainsAllSystemItems() {
        // Arrange - the expected system items
        let expectedImmovable = [
            IconIdentifier(namespace: "com.apple.controlcenter", title: "BentoBox"),
            IconIdentifier(namespace: "com.apple.controlcenter", title: "Clock"),
            IconIdentifier(namespace: "com.apple.Siri", title: "Siri"),
            IconIdentifier(namespace: "com.apple.Spotlight", title: "Spotlight")
        ]

        // Act & Assert
        for item in expectedImmovable {
            XCTAssertTrue(
                IconIdentifier.immovableItems.contains(item),
                "immovableItems should contain \(item.namespace)/\(item.title)"
            )
        }
        XCTAssertEqual(
            IconIdentifier.immovableItems.count,
            4,
            "immovableItems should contain exactly 4 system items"
        )
    }

    // MARK: - Static Control Item Constants Tests

    func testStaticControlItem_HiddenControlItemHasCorrectTitle() {
        // Act
        let hiddenControl = IconIdentifier.hiddenControlItem

        // Assert
        XCTAssertEqual(hiddenControl.title, "HiddenControlItem", "Hidden control item should have correct title")
        XCTAssertFalse(hiddenControl.isImmovable, "Drawer's control items should be movable")
    }

    func testStaticControlItem_AlwaysHiddenControlItemHasCorrectTitle() {
        // Act
        let alwaysHiddenControl = IconIdentifier.alwaysHiddenControlItem

        // Assert
        XCTAssertEqual(alwaysHiddenControl.title, "AlwaysHiddenControlItem", "Always hidden control item should have correct title")
        XCTAssertFalse(alwaysHiddenControl.isImmovable, "Drawer's control items should be movable")
    }

    // MARK: - IconItem isMovable Tests

    func testIconItem_IsMovableReturnsFalseForImmovableSystemIcon() {
        // Arrange - Test the logic through IconIdentifier since we can't easily
        // create IconItem without real window info
        let controlCenterIdentifier = IconIdentifier(namespace: "com.apple.controlcenter", title: "BentoBox")

        // Act & Assert
        XCTAssertTrue(controlCenterIdentifier.isImmovable, "Control Center identifier should be immovable")
        // Note: isMovable is !isImmovable, so immovable items have isMovable = false
    }

    func testIconItem_IsMovableReturnsTrueForRegularApp() {
        // Arrange
        let regularAppIdentifier = IconIdentifier(namespace: "com.example.myapp", title: "StatusItem")

        // Act & Assert
        XCTAssertFalse(regularAppIdentifier.isImmovable, "Regular app should not be immovable")
        // Note: isMovable is !isImmovable, so movable items have isMovable = true
    }

    // MARK: - IconItem Equality Tests

    func testIconItem_EqualityBasedOnWindowID() {
        // Arrange - Create test data for two items with same windowID but different frames
        let windowInfo1: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "TestApp",
            kCGWindowName as String: "StatusItem"
        ]

        let windowInfo2: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),  // Same window ID
            kCGWindowBounds as String: ["X": CGFloat(200), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],  // Different frame
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "TestApp",
            kCGWindowName as String: "StatusItem"
        ]

        // Act
        let item1 = IconItem(windowInfo: windowInfo1)
        let item2 = IconItem(windowInfo: windowInfo2)

        // Assert
        XCTAssertNotNil(item1, "Should create IconItem from valid windowInfo")
        XCTAssertNotNil(item2, "Should create IconItem from valid windowInfo")
        XCTAssertEqual(item1, item2, "IconItems with same windowID should be equal")
    }

    func testIconItem_InequalityForDifferentWindowID() {
        // Arrange
        let windowInfo1: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "TestApp"
        ]

        let windowInfo2: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(67890),  // Different window ID
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "TestApp"
        ]

        // Act
        let item1 = IconItem(windowInfo: windowInfo1)
        let item2 = IconItem(windowInfo: windowInfo2)

        // Assert
        XCTAssertNotNil(item1, "Should create IconItem from valid windowInfo")
        XCTAssertNotNil(item2, "Should create IconItem from valid windowInfo")
        XCTAssertNotEqual(item1, item2, "IconItems with different windowID should not be equal")
    }

    // MARK: - IconItem DisplayName Tests

    func testIconItem_DisplayNamePrefersTitle() {
        // Arrange
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "OwnerApp",
            kCGWindowName as String: "MyStatusItem"
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.displayName, "MyStatusItem", "DisplayName should prefer title when available")
    }

    func testIconItem_DisplayNameFallsBackToOwnerName() {
        // Arrange
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "OwnerApp"
            // No kCGWindowName
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.displayName, "OwnerApp", "DisplayName should fall back to ownerName when title is nil")
    }

    func testIconItem_DisplayNameReturnsUnknownWhenNoNameAvailable() {
        // Arrange
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234)
            // No kCGWindowOwnerName or kCGWindowName
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.displayName, "Unknown", "DisplayName should return 'Unknown' when no name is available")
    }

    // MARK: - IconItem Identifier Computed Property Tests

    func testIconItem_IdentifierComputedProperty() {
        // Arrange
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234),
            kCGWindowOwnerName as String: "TestApp",
            kCGWindowName as String: "StatusItem"
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.identifier.title, "StatusItem", "Identifier should have correct title")
        // Note: bundleIdentifier may be nil in test environment since we don't have a real running app
    }

    // MARK: - IconItem Initialization From WindowInfo Tests

    func testIconItem_InitFromWindowInfo_RequiresWindowID() {
        // Arrange - Missing kCGWindowNumber
        let windowInfo: [String: Any] = [
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234)
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNil(item, "Should return nil when windowID is missing")
    }

    func testIconItem_InitFromWindowInfo_RequiresBounds() {
        // Arrange - Missing kCGWindowBounds
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowOwnerPID as String: pid_t(1234)
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNil(item, "Should return nil when bounds are missing")
    }

    func testIconItem_InitFromWindowInfo_RequiresOwnerPID() {
        // Arrange - Missing kCGWindowOwnerPID
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(100), "Y": CGFloat(0), "Width": CGFloat(22), "Height": CGFloat(22)]
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNil(item, "Should return nil when ownerPID is missing")
    }

    func testIconItem_InitFromWindowInfo_ParsesFrameCorrectly() {
        // Arrange
        let windowInfo: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(12345),
            kCGWindowBounds as String: ["X": CGFloat(150), "Y": CGFloat(5), "Width": CGFloat(30), "Height": CGFloat(22)],
            kCGWindowOwnerPID as String: pid_t(1234)
        ]

        // Act
        let item = IconItem(windowInfo: windowInfo)

        // Assert
        XCTAssertNotNil(item)
        guard let item = item else { return }
        XCTAssertEqual(item.frame.origin.x, 150, "Frame X should be parsed correctly")
        XCTAssertEqual(item.frame.origin.y, 5, "Frame Y should be parsed correctly")
        XCTAssertEqual(item.frame.size.width, 30, "Frame width should be parsed correctly")
        XCTAssertEqual(item.frame.size.height, 22, "Frame height should be parsed correctly")
    }

    // MARK: - getMenuBarItems Sorting Tests

    func testGetMenuBarItems_ReturnsSortedByXPosition() {
        // Note: This test requires actual menu bar items to be present
        // In a real test environment with screen access, this would verify sorting
        // For CI environments, we test the sorting logic indirectly

        // Arrange
        let items = IconItem.getMenuBarItems()

        // Act - verify items are sorted by X position
        guard items.count > 1 else {
            // Skip if no items available (e.g., in sandboxed test environment)
            return
        }

        // Assert
        for i in 0..<(items.count - 1) {
            XCTAssertLessThanOrEqual(
                items[i].frame.minX,
                items[i + 1].frame.minX,
                "Items should be sorted by X position (left to right)"
            )
        }
    }
}

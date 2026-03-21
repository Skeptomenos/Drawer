//
//  LayoutDisplayMapperTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class LayoutDisplayMapperTests: XCTestCase {

    func testItemsForDisplay_WhenAlwaysHiddenEnabled_ReturnsSectionItemsOnly() {
        let visible = SettingsLayoutItem(bundleIdentifier: "com.test.visible", section: .visible, order: 1)
        let hidden = SettingsLayoutItem(bundleIdentifier: "com.test.hidden", section: .hidden, order: 0)
        let alwaysHidden = SettingsLayoutItem(bundleIdentifier: "com.test.always", section: .alwaysHidden, order: 2)
        let layoutItems = [visible, hidden, alwaysHidden]

        let visibleItems = LayoutDisplayMapper.itemsForDisplay(
            layoutItems: layoutItems,
            sectionType: .visible,
            alwaysHiddenEnabled: true
        )
        let hiddenItems = LayoutDisplayMapper.itemsForDisplay(
            layoutItems: layoutItems,
            sectionType: .hidden,
            alwaysHiddenEnabled: true
        )
        let alwaysHiddenItems = LayoutDisplayMapper.itemsForDisplay(
            layoutItems: layoutItems,
            sectionType: .alwaysHidden,
            alwaysHiddenEnabled: true
        )

        XCTAssertEqual(visibleItems.compactMap { $0.bundleIdentifier }, ["com.test.visible"])
        XCTAssertEqual(hiddenItems.compactMap { $0.bundleIdentifier }, ["com.test.hidden"])
        XCTAssertEqual(alwaysHiddenItems.compactMap { $0.bundleIdentifier }, ["com.test.always"])
    }

    func testItemsForDisplay_WhenAlwaysHiddenDisabled_ShowsAlwaysHiddenInHidden() {
        let alwaysHiddenA = SettingsLayoutItem(bundleIdentifier: "com.test.alwaysA", section: .alwaysHidden, order: 0)
        let alwaysHiddenB = SettingsLayoutItem(bundleIdentifier: "com.test.alwaysB", section: .alwaysHidden, order: 1)
        let hiddenA = SettingsLayoutItem(bundleIdentifier: "com.test.hiddenA", section: .hidden, order: 0)
        let hiddenB = SettingsLayoutItem(bundleIdentifier: "com.test.hiddenB", section: .hidden, order: 1)
        let layoutItems = [hiddenB, alwaysHiddenB, hiddenA, alwaysHiddenA]

        let hiddenItems = LayoutDisplayMapper.itemsForDisplay(
            layoutItems: layoutItems,
            sectionType: .hidden,
            alwaysHiddenEnabled: false
        )

        XCTAssertEqual(
            hiddenItems.compactMap { $0.bundleIdentifier },
            ["com.test.alwaysA", "com.test.alwaysB", "com.test.hiddenA", "com.test.hiddenB"]
        )

        let alwaysHiddenItems = LayoutDisplayMapper.itemsForDisplay(
            layoutItems: layoutItems,
            sectionType: .alwaysHidden,
            alwaysHiddenEnabled: false
        )
        XCTAssertTrue(alwaysHiddenItems.isEmpty)
    }
}

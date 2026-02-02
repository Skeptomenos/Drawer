//
//  ControlItemTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest
@testable import Drawer

@MainActor
final class ControlItemTests: XCTestCase {

    // MARK: - Properties

    private var sut: ControlItem!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - CI-001: Default Initial State is Collapsed

    func testCI001_DefaultInitialStateIsCollapsed() throws {
        // Arrange & Act
        sut = ControlItem()

        // Assert
        XCTAssertEqual(sut.state, .collapsed, "CI-001: Default initial state should be collapsed")
    }

    // MARK: - CI-002: Initial State Configurable

    func testCI002_InitialStateConfigurable() throws {
        // Act
        let expandedItem = ControlItem(initialState: .expanded)
        let collapsedItem = ControlItem(initialState: .collapsed)
        let hiddenItem = ControlItem(initialState: .hidden)

        // Assert
        XCTAssertEqual(expandedItem.state, .expanded, "CI-002: Should initialize to expanded")
        XCTAssertEqual(collapsedItem.state, .collapsed, "CI-002: Should initialize to collapsed")
        XCTAssertEqual(hiddenItem.state, .hidden, "CI-002: Should initialize to hidden")
    }

    // MARK: - CI-003: Collapsed State Sets Length to 10000

    func testCI003_CollapsedStateSetsLengthTo10000() throws {
        // Arrange
        sut = ControlItem(collapsedLength: 10000, initialState: .collapsed)

        // Assert
        XCTAssertEqual(sut.length, 10000, "CI-003: Collapsed state should set length to 10000")
    }

    // MARK: - CI-004: Expanded State Sets Length to Expanded Value

    func testCI004_ExpandedStateSetsLengthToExpandedValue() throws {
        // Arrange
        let expandedLength: CGFloat = 20

        // Act
        sut = ControlItem(expandedLength: expandedLength, initialState: .expanded)

        // Assert
        XCTAssertEqual(sut.length, expandedLength, "CI-004: Expanded state should set length to expandedLength")
    }

    // MARK: - CI-005: Hidden State Sets Visibility False

    func testCI005_HiddenStateSetsVisibilityFalse() throws {
        // Arrange & Act
        sut = ControlItem(initialState: .hidden)

        // Assert
        XCTAssertFalse(sut.statusItem.isVisible, "CI-005: Hidden state should set isVisible to false")
    }

    // MARK: - CI-006: State Change Updates Length

    func testCI006_StateChangeUpdatesLength() throws {
        // Arrange
        let expandedLength: CGFloat = 20
        let collapsedLength: CGFloat = 10000
        sut = ControlItem(expandedLength: expandedLength, collapsedLength: collapsedLength, initialState: .collapsed)

        // Act - Change to expanded
        sut.state = .expanded

        // Assert
        XCTAssertEqual(sut.length, expandedLength, "CI-006: Changing to expanded should update length")

        // Act - Change back to collapsed
        sut.state = .collapsed

        // Assert
        XCTAssertEqual(sut.length, collapsedLength, "CI-006: Changing to collapsed should update length")
    }

    // MARK: - CI-007: State Change Is Observable

    func testCI007_StateChangeIsObservable() throws {
        // Arrange
        sut = ControlItem(initialState: .collapsed)
        let initialState = sut.state
        XCTAssertEqual(initialState, .collapsed, "CI-007: Precondition - should be collapsed")

        // Act
        sut.state = .expanded

        // Assert
        XCTAssertEqual(sut.state, .expanded, "CI-007: State change should be reflected")
        XCTAssertNotEqual(sut.state, initialState, "CI-007: State should have changed from initial")
    }

    // MARK: - CI-008: Setting Same State Does Not Trigger Side Effects

    func testCI008_SettingSameStateDoesNotTriggerSideEffects() throws {
        // Arrange
        sut = ControlItem(expandedLength: 20, collapsedLength: 10000, initialState: .collapsed)
        let initialLength = sut.length
        XCTAssertEqual(initialLength, 10000, "CI-008: Precondition - should be collapsed")

        // Act - Set same state (collapsed) again
        sut.state = .collapsed

        // Assert - Length should remain unchanged (side effects not triggered)
        XCTAssertEqual(sut.length, initialLength, "CI-008: Setting same state should not trigger side effects")
        XCTAssertEqual(sut.state, .collapsed, "CI-008: State should remain collapsed")
    }

    // MARK: - CI-009: Image Property Updates Button

    func testCI009_ImagePropertyUpdatesButton() throws {
        // Arrange
        sut = ControlItem(initialState: .expanded)

        // Act
        sut.image = .chevronLeft

        // Assert
        XCTAssertNotNil(sut.button?.image, "CI-009: Setting image should update button image")
    }

    // MARK: - CI-010: Nil Image Clears Button Image

    func testCI010_NilImageClearsButtonImage() throws {
        // Arrange
        sut = ControlItem(initialState: .expanded)
        sut.image = .chevronLeft
        XCTAssertNotNil(sut.button?.image, "CI-010: Precondition - button should have image")

        // Act
        sut.image = nil

        // Assert
        XCTAssertNil(sut.button?.image, "CI-010: Setting image to nil should clear button image")
    }

    // MARK: - CI-011: Autosave Name Passthrough

    func testCI011_AutosaveNamePassthrough() throws {
        // Arrange
        sut = ControlItem()
        let testName = "TestAutosaveName"

        // Act
        sut.autosaveName = testName

        // Assert
        XCTAssertEqual(sut.autosaveName, testName, "CI-011: autosaveName should pass through to statusItem")
        XCTAssertEqual(sut.statusItem.autosaveName, testName, "CI-011: statusItem.autosaveName should be set")
    }

    // MARK: - CI-012: Button Property Returns Status Item Button

    func testCI012_ButtonPropertyReturnsStatusItemButton() throws {
        // Arrange
        sut = ControlItem(initialState: .expanded)

        // Assert
        XCTAssertNotNil(sut.button, "CI-012: button property should return statusItem.button")
        XCTAssertTrue(sut.button === sut.statusItem.button, "CI-012: button should be same object as statusItem.button")
    }

    // MARK: - CI-013: Custom Lengths

    func testCI013_CustomLengths() throws {
        // Arrange
        let customExpanded: CGFloat = 30
        let customCollapsed: CGFloat = 5000

        // Act
        let expandedItem = ControlItem(expandedLength: customExpanded, collapsedLength: customCollapsed, initialState: .expanded)
        let collapsedItem = ControlItem(expandedLength: customExpanded, collapsedLength: customCollapsed, initialState: .collapsed)

        // Assert
        XCTAssertEqual(expandedItem.length, customExpanded, "CI-013: Should use custom expanded length")
        XCTAssertEqual(collapsedItem.length, customCollapsed, "CI-013: Should use custom collapsed length")
    }

    // MARK: - CI-014: Identifiable Conformance

    func testCI014_IdentifiableConformance() throws {
        // Arrange
        let item1 = ControlItem()
        let item2 = ControlItem()

        // Assert
        XCTAssertNotEqual(item1.id, item2.id, "CI-014: Different instances should have different IDs")
    }

    // MARK: - CI-015: Visibility State Transitions

    func testCI015_VisibilityStateTransitions() throws {
        // Arrange
        sut = ControlItem(initialState: .expanded)
        XCTAssertTrue(sut.statusItem.isVisible, "CI-015: Precondition - expanded should be visible")

        // Act - Hide
        sut.state = .hidden

        // Assert
        XCTAssertFalse(sut.statusItem.isVisible, "CI-015: Hidden state should set isVisible false")

        // Act - Show again
        sut.state = .collapsed

        // Assert
        XCTAssertTrue(sut.statusItem.isVisible, "CI-015: Collapsed state should set isVisible true")

        // Act - Expand
        sut.state = .expanded

        // Assert
        XCTAssertTrue(sut.statusItem.isVisible, "CI-015: Expanded state should set isVisible true")
    }
}

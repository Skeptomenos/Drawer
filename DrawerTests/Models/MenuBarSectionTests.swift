//
//  MenuBarSectionTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import XCTest
@testable import Drawer

@MainActor
final class MenuBarSectionTests: XCTestCase {

    // MARK: - Properties

    private var sut: MenuBarSection!
    private var controlItem: ControlItem!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        cancellables = Set<AnyCancellable>()
        controlItem = ControlItem()
    }

    override func tearDown() async throws {
        sut = nil
        controlItem = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - MBS-001: Default State is Collapsed (Not Expanded)

    func testMBS001_DefaultStateIsCollapsed() throws {
        // Arrange & Act
        sut = MenuBarSection(type: .hidden, controlItem: controlItem)

        // Assert
        XCTAssertFalse(sut.isExpanded, "MBS-001: Default isExpanded should be false")
    }

    // MARK: - MBS-002: Default Enabled is True

    func testMBS002_DefaultEnabledIsTrue() throws {
        // Arrange & Act
        sut = MenuBarSection(type: .hidden, controlItem: controlItem)

        // Assert
        XCTAssertTrue(sut.isEnabled, "MBS-002: Default isEnabled should be true")
    }

    // MARK: - MBS-003: Initial State Configurable

    func testMBS003_InitialStateConfigurable() throws {
        // Act
        let expanded = MenuBarSection(type: .hidden, controlItem: ControlItem(), isExpanded: true)
        let collapsed = MenuBarSection(type: .hidden, controlItem: ControlItem(), isExpanded: false)

        // Assert
        XCTAssertTrue(expanded.isExpanded, "MBS-003: Should initialize to expanded")
        XCTAssertFalse(collapsed.isExpanded, "MBS-003: Should initialize to collapsed")
    }

    // MARK: - MBS-004: IsExpanded Syncs With ControlItem State

    func testMBS004_IsExpandedSyncsWithControlItemState() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: false)
        XCTAssertEqual(controlItem.state, .collapsed, "MBS-004: Precondition - controlItem should be collapsed")

        // Act
        sut.isExpanded = true

        // Assert
        XCTAssertEqual(controlItem.state, .expanded, "MBS-004: Setting isExpanded=true should set controlItem.state to .expanded")

        // Act
        sut.isExpanded = false

        // Assert
        XCTAssertEqual(controlItem.state, .collapsed, "MBS-004: Setting isExpanded=false should set controlItem.state to .collapsed")
    }

    // MARK: - MBS-005: IsEnabled False Hides ControlItem

    func testMBS005_IsEnabledFalseHidesControlItem() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isEnabled: true)
        XCTAssertNotEqual(controlItem.state, .hidden, "MBS-005: Precondition - controlItem should not be hidden")

        // Act
        sut.isEnabled = false

        // Assert
        XCTAssertEqual(controlItem.state, .hidden, "MBS-005: Setting isEnabled=false should set controlItem.state to .hidden")
    }

    // MARK: - MBS-006: Re-Enabling Restores Correct State

    func testMBS006_ReEnablingRestoresCorrectState() throws {
        // Arrange - Start expanded, then disable
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: true, isEnabled: true)
        sut.isEnabled = false
        XCTAssertEqual(controlItem.state, .hidden, "MBS-006: Precondition - should be hidden")

        // Act - Re-enable
        sut.isEnabled = true

        // Assert - Should restore expanded state
        XCTAssertEqual(controlItem.state, .expanded, "MBS-006: Re-enabling should restore expanded state")
    }

    // MARK: - MBS-007: Toggle Method

    func testMBS007_ToggleMethod() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: false)

        // Act & Assert
        sut.toggle()
        XCTAssertTrue(sut.isExpanded, "MBS-007: First toggle should expand")

        sut.toggle()
        XCTAssertFalse(sut.isExpanded, "MBS-007: Second toggle should collapse")
    }

    // MARK: - MBS-008: Expand Method

    func testMBS008_ExpandMethod() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: false)

        // Act
        sut.expand()

        // Assert
        XCTAssertTrue(sut.isExpanded, "MBS-008: expand() should set isExpanded to true")
    }

    // MARK: - MBS-009: Expand When Already Expanded is No-Op

    func testMBS009_ExpandWhenAlreadyExpandedIsNoOp() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: true)
        var changeCount = 0

        sut.$isExpanded
            .dropFirst()
            .sink { _ in changeCount += 1 }
            .store(in: &cancellables)

        // Act
        sut.expand()

        // Assert
        XCTAssertEqual(changeCount, 0, "MBS-009: expand() when already expanded should not trigger change")
    }

    // MARK: - MBS-010: Collapse Method

    func testMBS010_CollapseMethod() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: true)

        // Act
        sut.collapse()

        // Assert
        XCTAssertFalse(sut.isExpanded, "MBS-010: collapse() should set isExpanded to false")
    }

    // MARK: - MBS-011: Collapse When Already Collapsed is No-Op

    func testMBS011_CollapseWhenAlreadyCollapsedIsNoOp() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: false)
        var changeCount = 0

        sut.$isExpanded
            .dropFirst()
            .sink { _ in changeCount += 1 }
            .store(in: &cancellables)

        // Act
        sut.collapse()

        // Assert
        XCTAssertEqual(changeCount, 0, "MBS-011: collapse() when already collapsed should not trigger change")
    }

    // MARK: - MBS-012: Section Type Visible

    func testMBS012_SectionTypeVisible() throws {
        // Arrange & Act
        sut = MenuBarSection(type: .visible, controlItem: controlItem)

        // Assert
        XCTAssertEqual(sut.type, .visible, "MBS-012: Should store visible type")
        XCTAssertEqual(sut.type.displayName, "Visible", "MBS-012: displayName should be 'Visible'")
    }

    // MARK: - MBS-013: Section Type Hidden

    func testMBS013_SectionTypeHidden() throws {
        // Arrange & Act
        sut = MenuBarSection(type: .hidden, controlItem: controlItem)

        // Assert
        XCTAssertEqual(sut.type, .hidden, "MBS-013: Should store hidden type")
        XCTAssertEqual(sut.type.displayName, "Hidden", "MBS-013: displayName should be 'Hidden'")
    }

    // MARK: - MBS-014: Section Type Always Hidden

    func testMBS014_SectionTypeAlwaysHidden() throws {
        // Arrange & Act
        sut = MenuBarSection(type: .alwaysHidden, controlItem: controlItem)

        // Assert
        XCTAssertEqual(sut.type, .alwaysHidden, "MBS-014: Should store alwaysHidden type")
        XCTAssertEqual(sut.type.displayName, "Always Hidden", "MBS-014: displayName should be 'Always Hidden'")
    }

    // MARK: - MBS-015: Identifiable Conformance

    func testMBS015_IdentifiableConformance() throws {
        // Arrange
        let section1 = MenuBarSection(type: .hidden, controlItem: ControlItem())
        let section2 = MenuBarSection(type: .hidden, controlItem: ControlItem())

        // Assert
        XCTAssertNotEqual(section1.id, section2.id, "MBS-015: Different sections should have different IDs")
    }

    // MARK: - MBS-016: MenuBarSectionType All Cases

    func testMBS016_MenuBarSectionTypeAllCases() throws {
        // Arrange & Act
        let allTypes = MenuBarSectionType.allCases

        // Assert
        XCTAssertEqual(allTypes.count, 3, "MBS-016: Should have 3 section types")
        XCTAssertTrue(allTypes.contains(.visible), "MBS-016: Should contain visible")
        XCTAssertTrue(allTypes.contains(.hidden), "MBS-016: Should contain hidden")
        XCTAssertTrue(allTypes.contains(.alwaysHidden), "MBS-016: Should contain alwaysHidden")
    }

    // MARK: - MBS-017: MenuBarSectionType Identifiable

    func testMBS017_MenuBarSectionTypeIdentifiable() throws {
        // Assert
        XCTAssertEqual(MenuBarSectionType.visible.id, "visible", "MBS-017: visible.id should be 'visible'")
        XCTAssertEqual(MenuBarSectionType.hidden.id, "hidden", "MBS-017: hidden.id should be 'hidden'")
        XCTAssertEqual(MenuBarSectionType.alwaysHidden.id, "alwaysHidden", "MBS-017: alwaysHidden.id should be 'alwaysHidden'")
    }

    // MARK: - MBS-018: Setting Same IsExpanded Does Not Trigger Side Effects

    func testMBS018_SettingSameIsExpandedDoesNotTriggerSideEffects() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: true)
        let initialState = controlItem.state
        XCTAssertEqual(initialState, .expanded, "MBS-018: Precondition - controlItem should be expanded")

        // Act - Set same value again
        sut.isExpanded = true

        // Assert - No side effects should occur (controlItem state unchanged)
        XCTAssertEqual(controlItem.state, initialState, "MBS-018: Setting same value should not trigger side effects on controlItem")
        XCTAssertTrue(sut.isExpanded, "MBS-018: isExpanded should remain true")
    }

    // MARK: - MBS-019: Setting Same IsEnabled Does Not Trigger Side Effects

    func testMBS019_SettingSameIsEnabledDoesNotTriggerSideEffects() throws {
        // Arrange
        sut = MenuBarSection(type: .hidden, controlItem: controlItem, isExpanded: false, isEnabled: true)
        let initialState = controlItem.state
        XCTAssertEqual(initialState, .collapsed, "MBS-019: Precondition - controlItem should be collapsed")

        // Act - Set same value again
        sut.isEnabled = true

        // Assert - No side effects should occur (controlItem state unchanged)
        XCTAssertEqual(controlItem.state, initialState, "MBS-019: Setting same value should not trigger side effects on controlItem")
        XCTAssertTrue(sut.isEnabled, "MBS-019: isEnabled should remain true")
    }
}

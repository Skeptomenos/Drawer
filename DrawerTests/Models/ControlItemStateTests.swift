//
//  ControlItemStateTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class ControlItemStateTests: XCTestCase {

    // MARK: - CIS-001: All Cases Exist

    func testCIS001_AllCasesExist() {
        // Arrange & Act
        let allCases = ControlItemState.allCases

        // Assert
        XCTAssertEqual(allCases.count, 3, "CIS-001: Should have exactly 3 cases")
        XCTAssertTrue(allCases.contains(.expanded), "CIS-001: Should contain expanded case")
        XCTAssertTrue(allCases.contains(.collapsed), "CIS-001: Should contain collapsed case")
        XCTAssertTrue(allCases.contains(.hidden), "CIS-001: Should contain hidden case")
    }

    // MARK: - CIS-002: Raw Values

    func testCIS002_RawValues() {
        // Assert
        XCTAssertEqual(ControlItemState.expanded.rawValue, "expanded", "CIS-002: expanded rawValue should be 'expanded'")
        XCTAssertEqual(ControlItemState.collapsed.rawValue, "collapsed", "CIS-002: collapsed rawValue should be 'collapsed'")
        XCTAssertEqual(ControlItemState.hidden.rawValue, "hidden", "CIS-002: hidden rawValue should be 'hidden'")
    }

    // MARK: - CIS-003: Init from Raw Value

    func testCIS003_InitFromRawValue() {
        // Act
        let expanded = ControlItemState(rawValue: "expanded")
        let collapsed = ControlItemState(rawValue: "collapsed")
        let hidden = ControlItemState(rawValue: "hidden")
        let invalid = ControlItemState(rawValue: "invalid")

        // Assert
        XCTAssertEqual(expanded, .expanded, "CIS-003: Should init from 'expanded' string")
        XCTAssertEqual(collapsed, .collapsed, "CIS-003: Should init from 'collapsed' string")
        XCTAssertEqual(hidden, .hidden, "CIS-003: Should init from 'hidden' string")
        XCTAssertNil(invalid, "CIS-003: Should return nil for invalid raw value")
    }

    // MARK: - CIS-004: CaseIterable Conformance

    func testCIS004_CaseIterableConformance() {
        // Arrange
        var visitedCases = Set<ControlItemState>()

        // Act
        for state in ControlItemState.allCases {
            visitedCases.insert(state)
        }

        // Assert
        XCTAssertEqual(visitedCases.count, 3, "CIS-004: Should iterate over all 3 cases")
    }

    // MARK: - CIS-005: Equatable Conformance

    func testCIS005_EquatableConformance() {
        // Arrange
        let state1: ControlItemState = .expanded
        let state2: ControlItemState = .expanded
        let state3: ControlItemState = .collapsed

        // Assert
        XCTAssertEqual(state1, state2, "CIS-005: Same states should be equal")
        XCTAssertNotEqual(state1, state3, "CIS-005: Different states should not be equal")
    }

    // MARK: - CIS-006: Hashable Conformance

    func testCIS006_HashableConformance() {
        // Arrange
        var stateSet = Set<ControlItemState>()

        // Act
        stateSet.insert(.expanded)
        stateSet.insert(.collapsed)
        stateSet.insert(.hidden)
        stateSet.insert(.expanded) // Duplicate

        // Assert
        XCTAssertEqual(stateSet.count, 3, "CIS-006: Set should contain exactly 3 unique states")
    }
}

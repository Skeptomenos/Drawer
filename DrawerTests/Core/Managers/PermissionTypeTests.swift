//
//  PermissionTypeTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class PermissionTypeTests: XCTestCase {

    // MARK: - PRT-001: Accessibility displayName

    func testPRT001_AccessibilityDisplayName() {
        // Arrange
        let sut = PermissionType.accessibility

        // Act
        let displayName = sut.displayName

        // Assert
        XCTAssertEqual(
            displayName,
            "Accessibility",
            "PRT-001: Accessibility displayName should be 'Accessibility'"
        )
    }

    // MARK: - PRT-002: ScreenRecording displayName

    func testPRT002_ScreenRecordingDisplayName() {
        // Arrange
        let sut = PermissionType.screenRecording

        // Act
        let displayName = sut.displayName

        // Assert
        XCTAssertEqual(
            displayName,
            "Screen Recording",
            "PRT-002: ScreenRecording displayName should be 'Screen Recording'"
        )
    }

    // MARK: - PRT-003: Accessibility description

    func testPRT003_AccessibilityDescription() {
        // Arrange
        let sut = PermissionType.accessibility

        // Act
        let description = sut.description

        // Assert
        XCTAssertEqual(
            description,
            "Required to simulate clicks on hidden menu bar icons",
            "PRT-003: Accessibility description should explain click simulation requirement"
        )
    }

    // MARK: - PRT-004: ScreenRecording description

    func testPRT004_ScreenRecordingDescription() {
        // Arrange
        let sut = PermissionType.screenRecording

        // Act
        let description = sut.description

        // Assert
        XCTAssertEqual(
            description,
            "Required to capture images of hidden menu bar icons",
            "PRT-004: ScreenRecording description should explain icon capture requirement"
        )
    }

    // MARK: - PRT-005: Accessibility systemSettingsURL

    func testPRT005_AccessibilitySystemSettingsURL() {
        // Arrange
        let sut = PermissionType.accessibility
        let expectedURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

        // Act
        let url = sut.systemSettingsURL

        // Assert
        XCTAssertNotNil(url, "PRT-005: Accessibility systemSettingsURL should not be nil")
        XCTAssertEqual(
            url,
            expectedURL,
            "PRT-005: Accessibility systemSettingsURL should point to Privacy_Accessibility pane"
        )
    }

    // MARK: - PRT-006: ScreenRecording systemSettingsURL

    func testPRT006_ScreenRecordingSystemSettingsURL() {
        // Arrange
        let sut = PermissionType.screenRecording
        let expectedURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")

        // Act
        let url = sut.systemSettingsURL

        // Assert
        XCTAssertNotNil(url, "PRT-006: ScreenRecording systemSettingsURL should not be nil")
        XCTAssertEqual(
            url,
            expectedURL,
            "PRT-006: ScreenRecording systemSettingsURL should point to Privacy_ScreenCapture pane"
        )
    }

    // MARK: - PRT-007: allCases includes both cases

    func testPRT007_AllCasesIncludesBothCases() {
        // Arrange
        let expectedCases: Set<PermissionType> = [.accessibility, .screenRecording]

        // Act
        let allCases = Set(PermissionType.allCases)

        // Assert
        XCTAssertEqual(
            allCases.count,
            2,
            "PRT-007: allCases should contain exactly 2 cases"
        )
        XCTAssertEqual(
            allCases,
            expectedCases,
            "PRT-007: allCases should include both .accessibility and .screenRecording"
        )
        XCTAssertTrue(
            PermissionType.allCases.contains(.accessibility),
            "PRT-007: allCases should contain .accessibility"
        )
        XCTAssertTrue(
            PermissionType.allCases.contains(.screenRecording),
            "PRT-007: allCases should contain .screenRecording"
        )
    }
}

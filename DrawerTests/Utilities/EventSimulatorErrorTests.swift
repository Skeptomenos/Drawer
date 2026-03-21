//
//  EventSimulatorErrorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class EventSimulatorErrorTests: XCTestCase {

    // MARK: - ESE-001: accessibilityNotGranted description

    func testESE001_AccessibilityNotGrantedDescription() {
        // Arrange
        let error = EventSimulatorError.accessibilityNotGranted

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description, "ESE-001: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Accessibility permission is required to simulate clicks",
            "ESE-001: accessibilityNotGranted description should be correct"
        )
    }

    // MARK: - ESE-002: eventCreationFailed description

    func testESE002_EventCreationFailedDescription() {
        // Arrange
        let error = EventSimulatorError.eventCreationFailed

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description, "ESE-002: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Failed to create CGEvent",
            "ESE-002: eventCreationFailed description should be correct"
        )
    }

    // MARK: - ESE-003: eventPostingFailed description

    func testESE003_EventPostingFailedDescription() {
        // Arrange
        let error = EventSimulatorError.eventPostingFailed

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description, "ESE-003: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Failed to post CGEvent",
            "ESE-003: eventPostingFailed description should be correct"
        )
    }

    // MARK: - ESE-004: invalidCoordinates description

    func testESE004_InvalidCoordinatesDescription() {
        // Arrange
        let error = EventSimulatorError.invalidCoordinates

        // Act
        let description = error.errorDescription

        // Assert
        XCTAssertNotNil(description, "ESE-004: Error description should not be nil")
        XCTAssertEqual(
            description,
            "Invalid screen coordinates",
            "ESE-004: invalidCoordinates description should be correct"
        )
    }
}

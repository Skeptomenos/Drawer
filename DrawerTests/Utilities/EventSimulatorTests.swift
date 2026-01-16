//
//  EventSimulatorTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import XCTest

@testable import Drawer

final class EventSimulatorTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: EventSimulator!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        sut = EventSimulator.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - EVS-001: hasAccessibilityPermission returns correct value
    
    func testEVS001_HasAccessibilityPermissionReturnsCorrectValue() {
        // Arrange
        let expectedValue = AXIsProcessTrusted()
        
        // Act
        let actualValue = sut.hasAccessibilityPermission
        
        // Assert
        XCTAssertEqual(
            actualValue,
            expectedValue,
            "EVS-001: hasAccessibilityPermission should match AXIsProcessTrusted()"
        )
    }
    
    // MARK: - EVS-002: simulateClick without permission throws accessibilityNotGranted error
    
    func testEVS002_SimulateClickWithoutPermissionThrowsAccessibilityNotGrantedError() async throws {
        let hasPermission = AXIsProcessTrusted()
        let testPoint = CGPoint(x: 100, y: 100)
        
        if !hasPermission {
            do {
                try await sut.simulateClick(at: testPoint)
                XCTFail("EVS-002: simulateClick should throw when accessibility permission is not granted")
            } catch let error as EventSimulatorError {
                XCTAssertEqual(
                    error,
                    .accessibilityNotGranted,
                    "EVS-002: Error should be accessibilityNotGranted when permission is denied"
                )
                XCTAssertEqual(
                    error.errorDescription,
                    "Accessibility permission is required to simulate clicks",
                    "EVS-002: Error description should match expected message"
                )
            } catch {
                XCTFail("EVS-002: Unexpected error type: \(error)")
            }
        } else {
            XCTAssertTrue(
                sut.hasAccessibilityPermission,
                "EVS-002: Permission is granted in this environment - denied path cannot be tested directly"
            )
        }
    }
    
    // MARK: - EVS-003: simulateClick with invalid coordinates throws invalidCoordinates error
    
    func testEVS003_SimulateClickWithInvalidCoordinatesThrowsInvalidCoordinatesError() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-003: Accessibility permission required to test coordinate validation")
        }
        
        // Arrange - coordinates far outside any possible screen
        let invalidPoint = CGPoint(x: -99999, y: -99999)
        
        // Act & Assert
        do {
            try await sut.simulateClick(at: invalidPoint)
            XCTFail("EVS-003: simulateClick should throw when coordinates are invalid")
        } catch let error as EventSimulatorError {
            XCTAssertEqual(
                error,
                .invalidCoordinates,
                "EVS-003: Error should be invalidCoordinates for out-of-bounds point"
            )
            XCTAssertEqual(
                error.errorDescription,
                "Invalid screen coordinates",
                "EVS-003: Error description should match expected message"
            )
        } catch {
            XCTFail("EVS-003: Unexpected error type: \(error)")
        }
    }
    
    // MARK: - EVS-004: isValidScreenPoint inside screen returns true
    
    func testEVS004_IsValidScreenPointInsideScreenReturnsTrue() async throws {
        // Skip if no accessibility permission (would throw accessibilityNotGranted first)
        guard AXIsProcessTrusted() else {
            throw XCTSkip("EVS-004: Accessibility permission required to test coordinate validation")
        }
        
        // Arrange - get a point that is definitely inside the main screen
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("EVS-004: No main screen available")
        }
        
        // Use center of the screen - guaranteed to be valid
        let validPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.midY
        )
        
        // Act & Assert
        // If isValidScreenPoint returns true, simulateClick should NOT throw invalidCoordinates
        // It should either succeed or throw a different error (e.g., eventCreationFailed)
        do {
            try await sut.simulateClick(at: validPoint)
            // Success - point was valid and click was simulated
        } catch EventSimulatorError.invalidCoordinates {
            XCTFail("EVS-004: Point inside screen should be valid, but got invalidCoordinates error")
        } catch {
            // Other errors (eventCreationFailed, eventPostingFailed) are acceptable
            // They indicate the point was valid but something else failed
        }
    }
}

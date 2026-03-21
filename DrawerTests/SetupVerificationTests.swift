//
//  SetupVerificationTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

/// SETUP-008: Verify test target runs
/// This is a smoke test to confirm the test infrastructure is working correctly.
final class SetupVerificationTests: XCTestCase {

    // MARK: - Smoke Tests

    func testSETUP008_VerifyTestTargetRuns() {
        // Arrange
        let a = 1
        let b = 1

        // Act
        let result = a + b

        // Assert
        XCTAssertEqual(result, 2, "Basic arithmetic should work - test infrastructure is functional")
    }

    func testTestTargetCanImportDrawerModule() {
        // This test verifies that @testable import Drawer works
        // If this compiles and runs, the test target is correctly linked to the main target
        XCTAssertTrue(true, "If this runs, the Drawer module is accessible")
    }
}

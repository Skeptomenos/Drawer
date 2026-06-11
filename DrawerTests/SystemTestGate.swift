//
//  SystemTestGate.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

/// Gate for tests that touch the real system: TCC permissions, real CGEvent
/// posting, real `NSStatusItem`s, real panels/windows, real screen capture,
/// or real global event monitors.
///
/// These tests are DESTRUCTIVE or environment-dependent on a developer
/// machine (they can click the real menu bar, show real panels, and depend
/// on granted permissions). They are skipped by default and only run when
/// explicitly requested:
///
///     DRAWER_SYSTEM_TESTS=1 make validate-system
///
/// Call at the top of any system-level test method:
///
///     func testSomething() throws {
///         try requireSystemTests()
///         ...
///     }
func requireSystemTests(file: StaticString = #filePath, line: UInt = #line) throws {
    try XCTSkipUnless(
        ProcessInfo.processInfo.environment["DRAWER_SYSTEM_TESTS"] == "1",
        "System-level test: set DRAWER_SYSTEM_TESTS=1 to run",
        file: file,
        line: line
    )
}

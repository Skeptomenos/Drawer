//
//  TestEnvironment.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import Foundation

/// Detects whether the process is running as an XCTest host.
///
/// The unit-test target uses the full Drawer.app as its TEST_HOST. Without a
/// guard, every test run boots the real app: AppDelegate creates real
/// `NSStatusItem`s with production autosave names, polluting the user's
/// menu bar state (observed: 16 leaked instances scrambling status item
/// positions during a test crash-loop on 2026-06-11).
///
/// - Note: TEMPORARY mitigation. The structural fix (hardening roadmap
///   Phase 3/5) extracts logic into a framework target tested without an
///   app host, removing the need for environment sniffing.
enum TestEnvironment {

    /// True when the process was launched by XCTest as a test host.
    static let isRunningTests: Bool =
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
        || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil

    /// Prefix applied to `NSStatusItem` autosave names under test so that
    /// system tests (DRAWER_SYSTEM_TESTS=1) constructing real status items
    /// can never corrupt the production items' persisted positions.
    static var statusItemAutosavePrefix: String {
        isRunningTests ? "test_" : ""
    }
}
